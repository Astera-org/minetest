import gymnasium as gym
import pygame
import numpy as np
from minetester.minetest_env import KEY_MAP
import sys

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
    display_size=(1600, 1200),
    start_xvfb=True,
    headless=True,
)
env.reset()

for i in range(200):
    print(f"i: {i}")
    state, reward, terminated, truncated, info = env.step(
        {
            "KEYS": np.zeros(len(KEY_MAP), dtype=bool),
            "MOUSE": np.array([0.0, 0.0]),
        }
    )
    print(
        f"R: {reward} Term: {terminated} Trunc: {truncated} AllBlack: {state.sum() == 0}"
    )

env.close()
pygame.quit()
