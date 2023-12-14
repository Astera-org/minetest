from dataclasses import dataclass
import zmq
import tkinter as tk
from PIL import Image, ImageTk
import numpy as np
import capnp

capnp.remove_import_hook()
remoteclient_capnp = capnp.load("src/network/proto/remoteclient.capnp")


def display_image():
    # Wait for the response from the server
    response = socket.recv()

    with remoteclient_capnp.Observation.from_bytes(response) as obs_proto:
        # Convert the response to a numpy array
        img = obs_proto.image
        img_data = np.frombuffer(img.data, dtype=np.uint8)
        # Reshape the numpy array to the correct dimensions
        img_data = img_data.reshape((img.height, img.width, 3))
        reward = obs_proto.reward

    # Convert the numpy array to a PIL Image
    img = Image.fromarray(img_data)

    # Convert the PIL Image to a Tkinter PhotoImage
    photo = ImageTk.PhotoImage(img)

    # Update the image displayed in the label
    label.config(image=photo)
    label.image = photo  # keep a reference to the image


key_to_keytype = {
    "W": "forward",
    "A": "left",
    "S": "backward",
    "D": "right",
    "SPACE": "jump",
    "SHIFT_L": "sneak",
    "J": "dig",
    "K": "place",
    "C": "cameraMode",
    "ESCAPE": "esc",
}

arrow_keys_to_mouse_direction = {
    "UP": (0, -20),
    "DOWN": (0, 20),
    "LEFT": (-20, 0),
    "RIGHT": (20, 0),
}


key_cache = set()


@dataclass
class Mouse:
    dx: float
    dy: float


mouse = Mouse(0, 0)


def key_down(event):
    key = event.keysym.upper()

    if key in key_to_keytype:
        key_cache.add(key)
    if key in arrow_keys_to_mouse_direction:
        mouse.dx += arrow_keys_to_mouse_direction[key][0]
        mouse.dy += arrow_keys_to_mouse_direction[key][1]

    sendCurrent()


def key_up(event):
    key = event.keysym.upper()

    if key in key_to_keytype and key in key_cache:
        key_cache.remove(key)

    if key in arrow_keys_to_mouse_direction:
        mouse.dx -= arrow_keys_to_mouse_direction[key][0]
        mouse.dy -= arrow_keys_to_mouse_direction[key][1]

    sendCurrent()


def sendCurrent():
    action = remoteclient_capnp.Action.new_message()
    keyEvents = action.init("keyEvents", len(key_cache))
    for i, key in enumerate(key_cache):
        keyEvents[i] = key_to_keytype[key]

    action.mouseDx = mouse.dx
    action.mouseDy = mouse.dy

    # Send the event to the server
    socket.send(action.to_bytes())

    display_image()


# Set up the ZeroMQ context and socket
context = zmq.Context()
socket = context.socket(zmq.REQ)
socket.connect("tcp://localhost:5555")

# to get first observation as a reply, we need to send a message
action = remoteclient_capnp.Action.new_message()
socket.send(action.to_bytes())

# Create a new Tkinter window
window = tk.Tk()
window.title("Continuous Input")

# Create a label to display the image
label = tk.Label(window)
label.pack()
display_image()

# Set the event listener for key press event
window.bind("<KeyPress>", key_down)
window.bind("<KeyRelease>", key_up)
# Run the application, the script will pause here until the window is closed
window.mainloop()

context.destroy()
