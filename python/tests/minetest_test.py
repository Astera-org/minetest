import shutil
import sys
import tempfile
from pathlib import Path

import gymnasium as gym
import numpy as np
import pytest

from minetester.minetest_env import INVERSE_KEY_MAP


@pytest.fixture
def world_dir():
    repo_root = Path(__file__).parent.parent.parent
    original_world_dir = (
        repo_root / "python" / "tests" / "worlds" / "test_world_minetestenv"
    )
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_world_dir = Path(temp_dir) / "test_world_minetestenv"
        shutil.copytree(original_world_dir, temp_world_dir)
        yield temp_world_dir


def test_minetest_basic(world_dir):
    isMac = sys.platform == "darwin"
    repo_root = Path(__file__).parent.parent.parent
    if isMac:
        minetest_executable = (
            repo_root
            / "build"
            / "macos"
            / "minetest.app"
            / "Contents"
            / "MacOS"
            / "minetest"
        )
    else:
        minetest_executable = repo_root / "bin" / "minetest"
    assert minetest_executable.exists()

    env = gym.make(
        "minetest",
        minetest_executable=minetest_executable,
        render_mode="rgb_array",
        display_size=(223, 111),
        world_dir=world_dir,
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
