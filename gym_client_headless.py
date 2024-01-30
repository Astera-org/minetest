import gymnasium as gym
import pygame
import numpy as np
from minetester.minetest_env import KEY_MAP
from pathlib import Path
import sys
from gym_client import open_world_dir

from PIL import Image  # only needed to save images to disk

STORE_FILES = False
repo_root = Path(__file__).parent
minetest_executable = repo_root / "bin" / "minetest"
# On mac, the default build instructions put the binary into build/macos
if sys.platform == "darwin":
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
        display_size=(300, 200),
        start_xvfb=True,
        headless=True,
        world_dir=world_dir,
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