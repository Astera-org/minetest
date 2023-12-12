import zmq
import tkinter as tk
from PIL import Image, ImageTk
import numpy as np

commands = [
    "FORWARD",
    "BACKWARD",
    "LEFT",
    "RIGHT",
    "JUMP",
    "AUX1",
    "SNEAK",
    "AUTOFORWARD",
    "DIG",
    "PLACE",
    "ESC",
    # Other
    "DROP",
    "INVENTORY",
    "CHAT",
    "CMD",
    "CMD_LOCAL",
    "CONSOLE",
    "MINIMAP",
    "FREEMOVE",
    "PITCHMOVE",
    "FASTMOVE",
    "NOCLIP",
    "HOTBAR_PREV",
    "HOTBAR_NEXT",
    "MUTE",
    "INC_VOLUME",
    "DEC_VOLUME",
    "CINEMATIC",
    "SCREENSHOT",
    "TOGGLE_BLOCK_BOUNDS",
    "TOGGLE_HUD",
    "TOGGLE_CHAT",
    "TOGGLE_FOG",
    "TOGGLE_UPDATE_CAMERA",
    "TOGGLE_DEBUG",
    "TOGGLE_PROFILER",
    "CAMERA_MODE",
    "INCREASE_VIEWING_RANGE",
    "DECREASE_VIEWING_RANGE",
    "RANGESELECT",
    "ZOOM",
    "QUICKTUNE_NEXT",
    "QUICKTUNE_PREV",
    "QUICKTUNE_INC",
    "QUICKTUNE_DEC",
    # hotbar
    "SLOT_1",
    "SLOT_2",
    "SLOT_3",
    "SLOT_4",
    "SLOT_5",
    "SLOT_6",
    "SLOT_7",
    "SLOT_8",
    "SLOT_9",
    "SLOT_10",
    "SLOT_11",
    "SLOT_12",
    "SLOT_13",
    "SLOT_14",
    "SLOT_15",
    "SLOT_16",
    "SLOT_17",
    "SLOT_18",
    "SLOT_19",
    "SLOT_20",
    "SLOT_21",
    "SLOT_22",
    "SLOT_23",
    "SLOT_24",
    "SLOT_25",
    "SLOT_26",
    "SLOT_27",
    "SLOT_28",
    "SLOT_29",
    "SLOT_30",
    "SLOT_31",
    "SLOT_32",
    # Fake keycode for array size and internal checks
    "INTERNAL_ENUM_COUNT",
]


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


def send_key(event):
    key = event.keysym.upper()

    # Ensure that only the keys we want are sent
    if key in ["Q", "W", "A", "S", "D", "SPACE", "UP", "DOWN", "LEFT", "RIGHT"]:
        # Send the message to the server
        socket.send_string(key)

    elif key == "Q":
        window.quit()
    else:
        raise NotImplementedError(f"Key {key} not implemented")

    display_image()


# Set up the ZeroMQ context and socket
context = zmq.Context()
socket = context.socket(zmq.REQ)
socket.connect("tcp://localhost:5555")

socket.send_string("START_MINETEST")

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
