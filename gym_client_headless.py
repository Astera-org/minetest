import gymnasium as gym
import pygame
import numpy as np
from minetester.minetest_env import KEY_MAP
import sys

from PIL import Image  # only needed to save images to disk

STORE_FILES = False
# The Makefile puts the binary into build/macos
minetest_executable = "/home/simon/minetest/bin/minetest"
if sys.platform == "darwin":
    minetest_executable = (
        "/Users/siboehm/repos/minetest/build/macos/minetest.app/Contents/MacOS/minetest"
    )

env = gym.make(
    "minetest",
    minetest_executable=minetest_executable,
    render_mode="human",
    display_size=(300, 200),
    start_xvfb=True,
    headless=True,
)
env.reset()

for i in range(20):
    state, reward, terminated, truncated, info = env.step(
        {
            "KEYS": np.zeros(len(KEY_MAP), dtype=bool),
            "MOUSE": np.array([0.0, 0.0]),
        }
    )
    print(
        f"i: {i} R: {reward} Term: {terminated} Trunc: {truncated} AllBlack: {state.sum() == 0}"
    )
    if STORE_FILES:
        Image.fromarray(state).save(f"headless_test_{i}.png")

env.close()
pygame.quit()
