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

    with remoteclient_capnp.Image.from_bytes(response) as img_capnp:
        # Convert the response to a numpy array
        img_data = np.frombuffer(img_capnp.data, dtype=np.uint8)

    # Reshape the numpy array to the correct dimensions
    img_data = img_data.reshape((img_capnp.height, img_capnp.width, 3))

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
}

arrow_keys_to_mouse_direction = {
    "UP": (0, -20),
    "DOWN": (0, 20),
    "LEFT": (-20, 0),
    "RIGHT": (20, 0),
}


def send_key(event):
    key = event.keysym.upper()

    # Ensure that only the keys we want are sent
    action = remoteclient_capnp.Action.new_message()
    if key in key_to_keytype:
        keyEvents = action.init("keyEvents", 1)
        keyEvents[0] = key_to_keytype[key]
        # Create a new KeyboardEvent
    if key in arrow_keys_to_mouse_direction:
        action.mouseDx, action.mouseDy = arrow_keys_to_mouse_direction[key]

    # Send the event to the server
    print(f"Sending action: {action}")
    socket.send(action.to_bytes())

    if key == "Q":
        window.quit()

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
window.bind("<KeyPress>", send_key)
# Run the application, the script will pause here until the window is closed
window.mainloop()

context.destroy()
