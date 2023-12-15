import os
import subprocess
from typing import Any, Dict

import capnp
import numpy as np
import pkg_resources

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
