import gymnasium as gym
import pygame
from dataclasses import dataclass
import numpy as np
from minetester.minetest_env import KEY_MAP, INVERSE_KEY_MAP


KEY_TO_KEYTYPE = {
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
ARROW_KEYS_TO_MOUSE_DIRECTION = {
    "UP": (0, -20),
    "DOWN": (0, 20),
    "LEFT": (-20, 0),
    "RIGHT": (20, 0),
}


@dataclass
class Mouse:
    dx: float
    dy: float


def handle_key_event(event):
    key = pygame.key.name(event.key).upper()

    if event.type == pygame.KEYDOWN:
        if key in KEY_TO_KEYTYPE:
            key_cache.add(key)
        if key in ARROW_KEYS_TO_MOUSE_DIRECTION:
            mouse.dx += ARROW_KEYS_TO_MOUSE_DIRECTION[key][0]
            mouse.dy += ARROW_KEYS_TO_MOUSE_DIRECTION[key][1]
    elif event.type == pygame.KEYUP:
        if key in KEY_TO_KEYTYPE and key in key_cache:
            key_cache.remove(key)
        if key in ARROW_KEYS_TO_MOUSE_DIRECTION:
            mouse.dx -= ARROW_KEYS_TO_MOUSE_DIRECTION[key][0]
            mouse.dy -= ARROW_KEYS_TO_MOUSE_DIRECTION[key][1]


def get_action_from_key_cache(key_cache, mouse):
    keys = np.zeros(len(KEY_MAP), dtype=bool)
    for key in key_cache:
        keys[INVERSE_KEY_MAP[KEY_TO_KEYTYPE[key]]] = True

    mouse = np.array([mouse.dx, mouse.dy])
    return {"KEYS": keys, "MOUSE": mouse}


def game_loop():
    running = True
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type in [pygame.KEYDOWN, pygame.KEYUP]:
                handle_key_event(event)

        action = get_action_from_key_cache(key_cache, mouse)
        state, reward, terminated, truncated, info = env.step(action)
        env.render()
        print(reward)

        if terminated:
            print("\n\n--TERMINATED--\n\n")
            running = False


if __name__ == "__main__":
    key_cache = set()
    mouse = Mouse(0, 0)
    # Initialize Pygame
    pygame.init()

    # Initialize CartPole environment
    env = gym.make(
        "minetest",
        minetest_executable="/Users/siboehm/repos/minetest/build/macos/minetest.app/Contents/MacOS/minetest",
        render_mode="human",
    )
    env.reset()
    game_loop()
    env.close()
    pygame.quit()
