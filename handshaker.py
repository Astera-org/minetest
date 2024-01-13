import capnp
import pkg_resources
import zmq
import numpy as np
from PIL import Image

"""
Useful for debugging:
- lldb -- /home/simon/minetest/bin/minetest --go --worldname test_world --config /home/simon/minetest/artifacts/2dd22d78-8c03-445e-83ad-8fff429569d4.conf --remote-input localhost:5555 --headless
- Then run handshaker.py
"""

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


remoteclient_capnp = capnp.load(
    pkg_resources.resource_filename(
        "minetester", "../../src/network/proto/remoteclient.capnp"
    )
)
context = zmq.Context()
socket = context.socket(zmq.REQ)
socket.connect("tcp://localhost:5555")

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
    ) = unpack_pb_obs(byte_obs)

    # Save the observation as a PNG file
    if obs.size > 0:
        image = Image.fromarray(obs)
        image.save(f"observation_{i}.png")
    
    i += 1
    inp = input("Stop with 'stop':")
