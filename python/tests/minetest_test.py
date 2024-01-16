import sys
from pathlib import Path

import gymnasium as gym
import numpy as np

from minetester.minetest_env import INVERSE_KEY_MAP


def test_minetest_basic():
    minetest_executable = Path(__file__).parent.parent.parent / "bin" / "minetest"
    assert minetest_executable.exists()

    isMac = sys.platform == "darwin"

    env = gym.make(
        "minetest",
        minetest_executable=minetest_executable,
        render_mode="rgb_array",
        display_size=(223, 111),
        gameid="minetest",
        start_xvfb=not isMac,
        headless=True,
    )
    env.reset()

    for i in range(5):
        action = {
            "KEYS": np.zeros(len(INVERSE_KEY_MAP), dtype=bool),
            "MOUSE": np.array([0.0, 0.0]),
        }

        if i == 3:
            action["KEYS"][INVERSE_KEY_MAP["forward"]] = True
            action["KEYS"][INVERSE_KEY_MAP["left"]] = True
            action["MOUSE"] = np.array([0.0, 1.0])

        obs, reward, terminated, truncated, info = env.step(action)
        assert not terminated and not truncated
        assert obs.shape == (111, 223, 3)
        assert obs.sum() > 0, "All black image"
        assert reward == 1  # default game has only alive reward

    env.close()
