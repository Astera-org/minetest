import capnp
import pkg_resources
import zmq
import numpy as np
from PIL import Image

"""
For debugging, it's useful to do something like this:
- lldb -- /home/simon/minetest/bin/minetest --go --worldname test_world_minetestenv --config /home/simon/minetest/artifacts/2dd22d78-8c03-445e-83ad-8fff429569d4.conf --remote-input localhost:5555 --headless
- Then run handshaker.py
"""


def deserialize_obs(received_obs: str):
    with remoteclient_capnp.Observation.from_bytes(received_obs) as obs_msg:
        img = obs_msg.image
        img_data = np.frombuffer(img.data, dtype=np.uint8).reshape(
            (img.height, img.width, 3)
        )
        reward = obs_msg.reward
        done = obs_msg.done
    return img_data, reward, done


remoteclient_capnp = capnp.load(
    pkg_resources.resource_filename(
        "minetester", "../../src/network/proto/remoteclient.capnp"
    )
)
context = zmq.Context()
socket = context.socket(zmq.REQ)
socket.connect("tcp://localhost:54321")

i = 0
inp = ""
while inp != "stop":
    pb_action = remoteclient_capnp.Action.new_message()
    socket.send(pb_action.to_bytes())

    byte_obs = socket.recv()
    (
        obs,
        _,
        _,
    ) = deserialize_obs(byte_obs)

    if obs.size > 0:
        image = Image.fromarray(obs)
        image.save(f"observation_{i}.png")

    i += 1
    inp = input("Stop with 'stop':")