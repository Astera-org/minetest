import datetime
import logging
import os
import shutil
import subprocess
import uuid
from collections import namedtuple
from pathlib import Path
from typing import Any, Dict, Optional, Tuple

import capnp
import gymnasium as gym
import numpy as np
import pkg_resources
import pygame
import zmq

remoteclient_capnp = capnp.load(
    pkg_resources.resource_filename(
        "minetester", "../../src/network/proto/remoteclient.capnp"
    )
)


# Define default keys / buttons
KEY_MAP = [
    "forward",
    "left",
    "backward",
    "right",
    "jump",
    "sneak",
    "dig",
    "place",
]

INVERSE_KEY_MAP = {name: idx for idx, name in enumerate(KEY_MAP)}

DisplaySize = namedtuple("DisplaySize", ["width", "height"])


class MinetestEnv(gym.Env):
    metadata = {"render_modes": ["rgb_array", "human"]}

    def __init__(
        self,
        env_port: int = 5555,
        minetest_executable: Optional[os.PathLike] = None,
        world_dir: Optional[os.PathLike] = None,
        artifact_dir: Optional[os.PathLike] = None,
        config_path: Optional[os.PathLike] = None,
        display_size: Tuple[int, int] = (1728, 1051),
        render_mode: str = "rgb_array",
        fov: int = 72,
        base_seed: int = 0,
        world_seed: Optional[int] = None,
        start_minetest: bool = True,
        game_id: str = "minetest",
        client_name: str = "minetester",
        config_dict: Dict[str, Any] = None,
    ):
        if config_dict is None:
            config_dict = {}
        self.unique_env_id = str(uuid.uuid4())

        self.display_size = DisplaySize(*display_size)
        self.fov_y = fov
        self.fov_x = self.fov_y * self.display_size.width / self.display_size.height
        self.render_mode = render_mode

        if render_mode == "human":
            self._start_pygame()

        # Define action and observation space
        self._configure_spaces()

        # Define Minetest paths
        self._set_artifact_dirs(
            artifact_dir, world_dir, config_path
        )  # Stores minetest artifacts and outputs
        self.minetest_executable = Path(minetest_executable)
        assert (
            self.minetest_executable.exists()
        ), f"Minetest executable not found: {self.minetest_executable}"

        # Whether to start minetest server and client
        self.start_minetest = start_minetest

        # Used ports
        self.env_port = env_port  # MT env <-> MT client

        # Client Name
        self.client_name = client_name

        # ZMQ objects
        self.socket = None
        self.context = None

        # Minetest processes
        self.client_process = None

        # Env objects
        self.last_obs = None
        self.render_fig = None
        self.render_img = None

        # Seed the environment
        self.base_seed = base_seed
        self.world_seed = world_seed
        # If no world_seed is provided
        # seed the world with a random seed
        # generated by the RNG from base_seed
        self.reseed_on_reset = world_seed is None
        self.seed(self.base_seed)

        # Write minetest.conf
        self.config_dict = config_dict
        self._write_config()

        # Configure logging
        logging.basicConfig(
            filename=os.path.join(self.log_dir, f"env_{self.unique_env_id}.log"),
            filemode="a",
            format="%(asctime)s,%(msecs)d %(name)s %(levelname)s %(message)s",
            datefmt="%H:%M:%S",
            level=logging.DEBUG,
        )

        # Configure game and mods
        self.game_id = game_id

    def _configure_spaces(self):
        # Define action and observation space
        self.max_mouse_move_x = self.display_size[0] // 2
        self.max_mouse_move_y = self.display_size[1] // 2
        self.action_space = gym.spaces.Dict(
            {
                "KEYS": gym.spaces.MultiBinary(len(KEY_MAP)),
                "MOUSE": gym.spaces.Box(
                    low=np.array([-self.max_mouse_move_x, -self.max_mouse_move_y]),
                    high=np.array([self.max_mouse_move_x, self.max_mouse_move_y]),
                    shape=(2,),
                    dtype=int,
                ),
            },
        )
        self.observation_space = gym.spaces.Box(
            0,
            255,
            shape=(self.display_size[1], self.display_size[0], 3),
            dtype=np.uint8,
        )

    def _set_artifact_dirs(self, artifact_dir, world_dir, config_path):
        if artifact_dir is None:
            self.artifact_dir = os.path.join(os.getcwd(), "artifacts")
        else:
            self.artifact_dir = artifact_dir

        self.clean_config = True
        if config_path is None:
            self.config_path = os.path.join(
                self.artifact_dir, f"{self.unique_env_id}.conf"
            )
        else:
            self.clean_config = True
            self.config_path = config_path

        if world_dir is None:
            self.reset_world = True
            self.world_dir = os.path.join(self.artifact_dir, self.unique_env_id)
        else:
            self.reset_world = False
            self.world_dir = world_dir

        self.log_dir = os.path.join(self.artifact_dir, "log")
        self.media_cache_dir = os.path.join(self.artifact_dir, "media_cache")

        os.makedirs(self.log_dir, exist_ok=True)
        os.makedirs(self.media_cache_dir, exist_ok=True)

    def _reset_zmq(self):
        if self.socket:
            self.socket.close()
        self.context = zmq.Context()
        self.socket = self.context.socket(zmq.REQ)
        self.socket.connect(f"tcp://localhost:{self.env_port}")

    def _reset_minetest(self):
        # Determine log paths
        reset_timestamp = datetime.datetime.now().strftime("%m-%d-%Y,%H:%M:%S")
        log_path = os.path.join(
            self.log_dir,
            f"{{}}_{reset_timestamp}_{self.unique_env_id}.log",
        )

        # Close Mintest processes
        if self.client_process:
            self.client_process.kill()

        # (Re)start Minetest client
        self.client_process = start_minetest_client(
            self.minetest_executable,
            self.config_path,
            log_path,
            f"localhost:{self.env_port}",
        )

    def _perform_client_handshake(self):
        # handshake is an empty action
        pb_action = remoteclient_capnp.Action.new_message()
        self.socket.send(pb_action.to_bytes())

    def _check_world_dir(self):
        if self.world_dir is None:
            raise RuntimeError(
                "World directory was not set. Please, provide a world directory "
                "in the constructor or seed the environment!",
            )

    def _delete_world(self):
        if os.path.exists(self.world_dir):
            shutil.rmtree(self.world_dir, ignore_errors=True)

    def _check_config_path(self):
        if self.config_path is None:
            raise RuntimeError(
                "Minetest config path was not set. Please, provide a config path "
                "in the constructor or seed the environment!",
            )

    def _delete_config(self):
        if os.path.exists(self.config_path):
            os.remove(self.config_path)

    def _write_config(self):
        config = dict(
            # Base config
            mute_sound=True,
            show_debug=False,
            enable_client_modding=True,
            csm_restriction_flags=0,
            enable_mod_channels=True,
            screen_w=self.display_size[0],
            screen_h=self.display_size[1],
            fov=self.fov_y,
            # Adapt HUD size to display size, based on (1024, 600) default
            hud_scaling=self.display_size[0] / 1024,
            # Experimental settings to improve performance
            server_map_save_interval=1000000,
            profiler_print_interval=0,
            active_block_range=2,
            abm_time_budget=0.01,
            abm_interval=0.1,
            active_block_mgmt_interval=4.0,
            server_unload_unused_data_timeout=1000000,
            client_unload_unused_data_timeout=1000000,
            full_block_send_enable_min_time_from_building=0.0,
            max_block_send_distance=100,
            max_block_generate_distance=100,
            num_emerge_threads=0,
            emergequeue_limit_total=1000000,
            emergequeue_limit_diskonly=1000000,
            emergequeue_limit_generate=1000000,
        )

        # Seed the map generator if not using a custom map
        if self.world_seed:
            config.update(fixed_map_seed=self.world_seed)
        # Update config from existing config file
        if os.path.exists(self.config_path):
            config.update(read_config_file(self.config_path))
        # Set from custom config dict
        config.update(self.config_dict)
        write_config_file(self.config_path, config)

    def _start_pygame(self):
        pygame.init()
        self.screen = pygame.display.set_mode(
            (self.display_size.width, self.display_size.height)
        )
        pygame.display.set_caption(f"Minetester - {self.unique_env_id}")

    def _display_pygame(self):
        # for some reason pydata expects the transposed image
        img_data = self.last_obs.transpose((1, 0, 2))

        # Convert the numpy array to a Pygame Surface and display it
        img = pygame.surfarray.make_surface(img_data)
        self.screen.blit(img, (0, 0))
        pygame.display.update()

    def seed(self, seed: Optional[int] = None):
        self._np_random = np.random.RandomState(seed or 0)

    def reset(
        self, seed: Optional[int] = None, options: Optional[Dict[str, Any]] = None
    ):
        self.seed(seed=seed)
        if self.start_minetest:
            if self.reset_world:
                self._delete_world()
                if self.reseed_on_reset:
                    self.world_seed = self._np_random.randint(np.iinfo(np.int64).max)
            self._reset_minetest()
        self._reset_zmq()
        self._perform_client_handshake()

        # Receive initial observation
        logging.debug("Waiting for first obs...")
        byte_obs = self.socket.recv()
        (
            obs,
            _,
            _,
        ) = unpack_pb_obs(byte_obs)
        self.last_obs = obs
        logging.debug(f"Received first obs: {obs.shape}")
        return obs, {}

    def step(self, action: Dict[str, Any]):
        # Send action
        if isinstance(action["MOUSE"], np.ndarray):
            action["MOUSE"] = action["MOUSE"].tolist()
        pb_action = pack_pb_action(action)
        logging.debug(f"Sending action: {pb_action}")
        self.socket.send(pb_action.to_bytes())

        # TODO more robust check for whether a server/client is alive while receiving observations
        if self.client_process is not None and self.client_process.poll() is not None:
            return self.last_obs, 0.0, True, False, {}

        # Receive observation
        logging.debug("Waiting for obs...")
        byte_obs = self.socket.recv()
        next_obs, rew, done = unpack_pb_obs(byte_obs)

        self.last_obs = next_obs
        logging.debug(f"Received obs - {next_obs.shape}; reward - {rew}")

        if self.render_mode == "human":
            self._display_pygame()

        return next_obs, rew, done, False, {}

    def render(self):
        if self.render_mode == "human":
            # rendering happens during step, as per gymnasium API
            return None
        return self.last_obs

    def close(self):
        if self.socket is not None:
            self.socket.close()
        # TODO improve process termination
        # i.e. don't kill, but close signal
        if self.client_process is not None:
            self.client_process.kill()
        if self.reset_world:
            self._delete_world()
        if self.clean_config:
            self._delete_config()


def unpack_pb_obs(received_obs: str):
    with remoteclient_capnp.Observation.from_bytes(received_obs) as obs_proto:
        # Convert the response to a numpy array
        img = obs_proto.image
        img_data = np.frombuffer(img.data, dtype=np.uint8).reshape(
            (img.height, img.width, 3)
        )
        # Reshape the numpy array to the correct dimensions
        reward = obs_proto.reward
        done = obs_proto.done
    return img_data, reward, done


def pack_pb_action(action: Dict[str, Any]):
    pb_action = remoteclient_capnp.Action.new_message()

    pb_action.mouseDx = action["MOUSE"][0]
    pb_action.mouseDy = action["MOUSE"][1]

    keyEvents = pb_action.init("keyEvents", action["KEYS"].sum())
    setIdx = 0
    for idx, pressed in enumerate(action["KEYS"]):
        if pressed:
            keyEvents[setIdx] = KEY_MAP[idx]
            setIdx += 1
    return pb_action


def start_minetest_client(
    minetest_executable: str,
    config_path: str,
    log_path: str,
    client_socket: str,
    display: int = None,
):
    cmd = [
        minetest_executable,
        "--go",
        "--worldname",
        "test_world",  # TODO don't hardcode this
        "--config",
        config_path,
        "--remote-input",
        client_socket,
        "--verbose",
    ]

    stdout_file = log_path.format("client_stdout")
    stderr_file = log_path.format("client_stderr")
    with open(stdout_file, "w") as out, open(stderr_file, "w") as err:
        # client_env = os.environ.copy()
        # if display is not None:
        #     client_env["DISPLAY"] = ":" + str(display)
        client_process = subprocess.Popen(cmd, stdout=out, stderr=err)
    return client_process


def read_config_file(file_path):
    config = {}
    with open(file_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip()
                if value.isdigit():
                    value = int(value)
                elif value.replace(".", "", 1).isdigit():
                    value = float(value)
                elif value.lower() == "true":
                    value = True
                elif value.lower() == "false":
                    value = False
                config[key] = value
    return config


def write_config_file(file_path, config):
    with open(file_path, "w") as f:
        for key, value in config.items():
            f.write(f"{key} = {value}\n")
