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
    img_data = img_data.reshape((1051, 1728, 3))  # replace height and width with the actual values

    # Convert the numpy array to a PIL Image
    img = Image.fromarray(img_data)

    # Convert the PIL Image to a Tkinter PhotoImage
    photo = ImageTk.PhotoImage(img)

    # Update the image displayed in the label
    label.config(image=photo)
    label.image = photo  # keep a reference to the image


def send_key(event):
    key = event.char.upper()
    
    # Ensure that only the keys we want are sent
    if key in ["Q", "W", "A", "S", "D", " "]:
        # Send the message to the server
        socket.send_string(key)

    elif key == "Q":
        window.quit()
    else:
        raise NotImplementedError()
    
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
