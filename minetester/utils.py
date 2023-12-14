import os
import subprocess
from typing import Any, Dict, Tuple

import numpy as np
from minetester.proto import objects_pb2 as pb_objects
from minetester.proto.objects_pb2 import KeyType

# Define default keys / buttons
KEY_MAP = {
    "FORWARD": KeyType.FORWARD,
    "BACKWARD": KeyType.BACKWARD,
    "LEFT": KeyType.LEFT,
    "RIGHT": KeyType.RIGHT,
    "JUMP": KeyType.JUMP,
    "SNEAK": KeyType.SNEAK,  # shift key in menus
    "DIG": KeyType.DIG,  # left mouse button
    "MIDDLE": KeyType.MIDDLE,  # middle mouse button
    "PLACE": KeyType.PLACE,  # right mouse button
    "DROP": KeyType.DROP,
    "HOTBAR_NEXT": KeyType.HOTBAR_NEXT,  # mouse wheel up
    "HOTBAR_PREV": KeyType.HOTBAR_PREV,  # mouse wheel down
    "SLOT_1": KeyType.SLOT_1,
    "SLOT_2": KeyType.SLOT_2,
    "SLOT_3": KeyType.SLOT_3,
    "SLOT_4": KeyType.SLOT_4,
    "SLOT_5": KeyType.SLOT_5,
    "SLOT_6": KeyType.SLOT_6,
    "SLOT_7": KeyType.SLOT_7,
    "SLOT_8": KeyType.SLOT_8,
    "INVENTORY": KeyType.INVENTORY,
}
INV_KEY_MAP = {value: key for key, value in KEY_MAP.items()}

# Define noop action
NOOP_ACTION = {key: 0 for key in KEY_MAP.keys()}
NOOP_ACTION.update({"MOUSE": np.zeros(2, dtype=int)})


def unpack_pb_obs(received_obs: str):
    pb_obs = pb_objects.Observation()
    pb_obs.ParseFromString(received_obs)
    obs = np.frombuffer(pb_obs.image.data, dtype=np.uint8).reshape(
        pb_obs.image.height,
        pb_obs.image.width,
        3,
    )
    last_action = unpack_pb_action(pb_obs.action) if pb_obs.action else None
    rew = pb_obs.reward
    done = pb_obs.terminal
    info = pb_obs.info
    return obs, rew, done, info, last_action


def unpack_pb_action(pb_action: pb_objects.Action):
    action = dict(NOOP_ACTION)
    action["MOUSE"] = [pb_action.mouseDx, pb_action.mouseDy]
    for key_event in pb_action.keyEvents:
        if key_event.key in INV_KEY_MAP and key_event.eventType == pb_objects.PRESS:
            key_name = INV_KEY_MAP[key_event.key]
            action[key_name] = 1
    return action


def pack_pb_action(action: Dict[str, Any]):
    pb_action = pb_objects.Action()
    pb_action.mouseDx, pb_action.mouseDy = action["MOUSE"]
    for key, v in action.items():
        if key == "MOUSE":
            continue
        pb_action.keyEvents.append(
            pb_objects.KeyboardEvent(
                key=KEY_MAP[key],
                eventType=pb_objects.PRESS if v else pb_objects.RELEASE,
            ),
        )
    return pb_action


def start_minetest_server(
    minetest_path: str,
    config_path: str,
    log_path: str,
    server_port: int,
    world_dir: str,
    sync_port: int,
    sync_dtime: float,
    game_id: str,
):
    cmd = [
        minetest_path,
        "--server",
        "--world",
        world_dir,
        "--gameid",
        game_id,
        "--config",
        config_path,
        "--port",
        str(server_port),
    ]
    if sync_port:
        cmd.extend(["--sync-port", str(sync_port)])
        cmd.extend(["--sync-dtime", str(sync_dtime)])
    stdout_file = log_path.format("server_stdout")
    stderr_file = log_path.format("server_stderr")

    with open(stdout_file, "w") as out, open(stderr_file, "w") as err:
        server_process = subprocess.Popen(cmd, stdout=out, stderr=err)
    return server_process


def start_minetest_client(
    minetest_path: str,
    config_path: str,
    log_path: str,
    client_port: int,
    server_port: int,
    cursor_img: str,
    client_name: str,
    media_cache_dir: str,
    sync_port: int = None,
    headless: bool = False,
    display: int = None,
):
    cmd = [
        minetest_path,
        "--name",
        client_name,
        "--password",
        "1234",
        "--address",
        "0.0.0.0",  # listen to all interfaces
        "--port",
        str(server_port),
        "--go",
        "--dumb",
        "--client-address",
        "tcp://localhost:" + str(client_port),
        "--record",
        "--noresizing",
        "--config",
        config_path,
        "--cache",
        media_cache_dir,
    ]
    if headless:
        # don't render to screen
        cmd.append("--headless")
    if cursor_img:
        cmd.extend(["--cursor-image", cursor_img])
    if sync_port:
        cmd.extend(["--sync-port", str(sync_port)])

    stdout_file = log_path.format("client_stdout")
    stderr_file = log_path.format("client_stderr")
    with open(stdout_file, "w") as out, open(stderr_file, "w") as err:
        client_env = os.environ.copy()
        if display is not None:
            client_env["DISPLAY"] = ":" + str(display)
        client_process = subprocess.Popen(cmd, stdout=out, stderr=err, env=client_env)
    return client_process


def start_xserver(
    display_idx: int = 1,
    display_size: Tuple[int, int] = (1024, 600),
    display_depth: int = 24,
):
    cmd = [
        "Xvfb",
        f":{display_idx}",
        "-screen",
        "0",  # screennum param
        f"{display_size[0]}x{display_size[1]}x{display_depth}",
    ]
    xserver_process = subprocess.Popen(cmd)
    return xserver_process


def read_config_file(file_path):
    config = {}
    with open(file_path, "r") as f:
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
