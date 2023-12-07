import zmq
import tkinter as tk

def send_key(event):
    key = event.char.upper()
    
    # Ensure that only the keys we want are sent
    if key in ["Q", "W", "A", "S", "D", " "]:
        # Send the message to the server
        socket.send_string(key)
        
        # Wait for the response from the server
        response = socket.recv_string()
        print("Received response:", response)

    if key == "Q":
        window.quit()

# Set up the ZeroMQ context and socket
context = zmq.Context()
socket = context.socket(zmq.REQ)
socket.connect("tcp://localhost:5555")

# Create a new Tkinter window
window = tk.Tk()
window.title("Continuous Input")

# Set the event listener for key press event
window.bind("<KeyPress>", send_key)

# Run the application, the script will pause here until the window is closed
window.mainloop()

context.destroy()
