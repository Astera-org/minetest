from contextlib import contextmanager
from pathlib import Path
import shutil
import tempfile
import gymnasium as gym
import pygame
from dataclasses import dataclass
import numpy as np
from minetester.minetest_env import KEY_MAP, INVERSE_KEY_MAP
import signal
import sys


KEY_TO_KEYTYPE = {
    "W": "forward",
    "A": "left",
    "S": "backward",
    "D": "right",
    "SPACE": "jump",
    "LEFT SHIFT": "sneak",
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
            keys_down.add(key)
        if key in ARROW_KEYS_TO_MOUSE_DIRECTION:
            mouse.dx += ARROW_KEYS_TO_MOUSE_DIRECTION[key][0]
            mouse.dy += ARROW_KEYS_TO_MOUSE_DIRECTION[key][1]
    elif event.type == pygame.KEYUP:
        if key in KEY_TO_KEYTYPE and key in keys_down:
            keys_down.remove(key)
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

        action = get_action_from_key_cache(keys_down, mouse)
        state, reward, terminated, truncated, info = env.step(action)
        env.render()
        print(reward)

        if terminated:
            print("\n\n--TERMINATED--\n\n")
            running = False


def signal_handler(sig, frame):
    env.close()
    pygame.quit()


@contextmanager
def open_world_dir():
    repo_root = Path(__file__).parent
    original_world_dir = (
        repo_root / "python" / "tests" / "worlds" / "test_world_minetestenv"
    )
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_world_dir = Path(temp_dir) / "test_world_minetestenv"
        shutil.copytree(original_world_dir, temp_world_dir)
        yield temp_world_dir


if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal_handler)

    keys_down = set()
    mouse = Mouse(0, 0)
    # Initialize Pygame
    pygame.init()

    # The Makefile puts the binary into build/macos
    repo_root = Path(__file__).parent
    is_mac = sys.platform == "darwin"
    minetest_executable = repo_root / "bin" / "minetest"
    if is_mac:
        minetest_executable = (
            repo_root
            / "build"
            / "macos"
            / "minetest.app"
            / "Contents"
            / "MacOS"
            / "minetest"
        )

    with open_world_dir() as world_dir:
        env = gym.make(
            "minetest-v0",
            minetest_executable=minetest_executable,
            render_mode="human",
            display_size=(1600, 1200),
            headless=False,
            world_dir=world_dir,
        )
        env.reset()
        game_loop()
    env.close()
    pygame.quit()
