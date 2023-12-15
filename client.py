import pygame
import numpy as np
import zmq
from dataclasses import dataclass
import capnp

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

# Pygame initialization
pygame.init()

# Window settings
screen_width = 1024  # You can adjust this
screen_height = 600  # You can adjust this
screen = pygame.display.set_mode((screen_width, screen_height))
pygame.display.set_caption("Continuous Input")

# ZeroMQ and Cap'n Proto setup
capnp.remove_import_hook()
remoteclient_capnp = capnp.load("src/network/proto/remoteclient.capnp")
context = zmq.Context()
socket = context.socket(zmq.REQ)
socket.connect("tcp://localhost:5555")

# Send initial message to server to get the first observation
action = remoteclient_capnp.Action.new_message()
socket.send(action.to_bytes())


def display_image():
    # Get the response from the server and display the image
    response = socket.recv()
    with remoteclient_capnp.Observation.from_bytes(response) as obs_proto:
        img = obs_proto.image
        img_data = np.frombuffer(img.data, dtype=np.uint8)
        img_data = img_data.reshape((img.height, img.width, 3))

    # for some reason pydata expects the transposed image
    img_data = img_data.transpose((1, 0, 2))

    # Convert the numpy array to a Pygame Surface and display it
    img = pygame.surfarray.make_surface(img_data)
    screen.blit(img, (0, 0))
    pygame.display.update()


def sendCurrent():
    action = remoteclient_capnp.Action.new_message()
    keyEvents = action.init("keyEvents", len(key_cache))
    for i, key in enumerate(key_cache):
        keyEvents[i] = key_to_keytype[key]

    action.mouseDx = mouse.dx
    action.mouseDy = mouse.dy
    socket.send(action.to_bytes())

    display_image()


def handle_key_event(event):
    key = pygame.key.name(event.key).upper()

    if event.type == pygame.KEYDOWN:
        if key in key_to_keytype:
            key_cache.add(key)
        if key in arrow_keys_to_mouse_direction:
            mouse.dx += arrow_keys_to_mouse_direction[key][0]
            mouse.dy += arrow_keys_to_mouse_direction[key][1]
    elif event.type == pygame.KEYUP:
        if key in key_to_keytype and key in key_cache:
            key_cache.remove(key)
        if key in arrow_keys_to_mouse_direction:
            mouse.dx -= arrow_keys_to_mouse_direction[key][0]
            mouse.dy -= arrow_keys_to_mouse_direction[key][1]


def game_loop():
    running = True
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type in [pygame.KEYDOWN, pygame.KEYUP]:
                handle_key_event(event)
        sendCurrent()

    pygame.quit()
    context.destroy()


display_image()

# Start the game loop
game_loop()
