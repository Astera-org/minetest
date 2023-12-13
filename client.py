import gen.src.network.proto.remoteclient_pb2 as remoteclient_pb2
import zmq
import tkinter as tk
from PIL import Image, ImageTk
import numpy as np

def display_image():
    # Wait for the response from the server
    response = socket.recv()

    # Convert the response to a numpy array
    img_data = np.frombuffer(response, dtype=np.uint8)

    # Reshape the numpy array to the correct dimensions
    img_data = img_data.reshape(
        (1051, 1728, 3)
    )  # replace height and width with the actual values

    # Convert the numpy array to a PIL Image
    img = Image.fromarray(img_data)

    # Convert the PIL Image to a Tkinter PhotoImage
    photo = ImageTk.PhotoImage(img)

    # Update the image displayed in the label
    label.config(image=photo)
    label.image = photo  # keep a reference to the image


key_to_keytype = {
    "W": remoteclient_pb2.KeyType.FORWARD,
    "A": remoteclient_pb2.KeyType.LEFT,
    "S": remoteclient_pb2.KeyType.BACKWARD,
    "D": remoteclient_pb2.KeyType.RIGHT,
    "SPACE": remoteclient_pb2.KeyType.JUMP,
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
    action = remoteclient_pb2.Action()
    if key in key_to_keytype:
        event = remoteclient_pb2.KeyboardEvent()
        # Create a new KeyboardEvent
        event.key = key_to_keytype[key]
        event.eventType = remoteclient_pb2.EventType.PRESS
        action.keyEvents.append(event)
    if key in arrow_keys_to_mouse_direction:
        action.mouseDx, action.mouseDy = arrow_keys_to_mouse_direction[key]

    # Send the event to the server
    print(f"Sending action: {action}")
    socket.send(action)

    if key == "Q":
        window.quit()
    else:
        raise NotImplementedError(f"Key {key} not implemented")

    display_image()


# Set up the ZeroMQ context and socket
context = zmq.Context()
socket = context.socket(zmq.REQ)
socket.connect("tcp://localhost:5555")

# to get first observation as a reply, we need to send a message
initial_event = remoteclient_pb2.KeyboardEvent()
initial_event.key = remoteclient_pb2.KeyType.SPACE
initial_event.eventType = remoteclient_pb2.EventType.PRESS
socket.send(initial_event.SerializeToString())

# Create a new Tkinter window
window = tk.Tk()
window.title("Continuous Input")

# Create a label to display the image
label = tk.Label(window)
label.pack()
display_image()

# Set the event listener for key press event
window.bind("<KeyPress>", send_key)
