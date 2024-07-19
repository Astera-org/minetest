import os
from typing import Any, Optional

import gymnasium as gym
import numpy as np

from minetest.discrete_actions import MOVEMENT_KEYS
from minetest.utils import DataProcessor

BOAD_KEYBOARD_ACTION_KEYS = MOVEMENT_KEYS + ["dig"]

BOAD_MOUSE_ACTION_KEYS = ["mouse_left", "mouse_right", "mouse_up", "mouse_down"]

BOAD_NOOP_IDX = len(BOAD_KEYBOARD_ACTION_KEYS) + len(BOAD_MOUSE_ACTION_KEYS)

BOAD_ADDITIONAL_OBSERVATION_SPACES = {
    "health": gym.spaces.Box(0, 20, (1,), dtype=np.float32),
    "hunger": gym.spaces.Box(0, 1000, (1,), dtype=np.float32),
    "thirst": gym.spaces.Box(0, 1000, (1,), dtype=np.float32),
}


def write_boad_config(game_dir: str, config: Optional[dict[str, Any]] = None) -> None:
    if config is None:
        config = {}
    boad_config = _get_boad_config(**config)
    config_path = os.path.join(game_dir, "config.lua")
    with open(config_path, "w") as f:
        f.write(boad_config)


def _get_boad_config(
    hunger_rate: int = 20,
    thirst_rate: int = 20,
    allow_night: bool = False,
    apple_scale: float = 2.5,
    rose_scale: float = 1.5,
    **kwargs,
) -> str:
    return f"""STARVE_1_MUL={hunger_rate}
STARVE_2_MUL={thirst_rate}
ALLOW_NIGHT={int(allow_night)}
APPLE_SCALE={apple_scale}
ROSE_SCALE={rose_scale}
"""


class BoadDataProcessor(DataProcessor):
    @staticmethod
    def get_padded_int(arr: np.ndarray) -> str:
        return f"{int(arr[0]):03d}"

    def __init__(self):
        self._prev_obs = {"health": "", "hunger": "", "thirst": "", "reward": 0}

    def process(self, obs: dict[str, np.ndarray], reward: float) -> None:
        obs = {
            k: BoadDataProcessor.get_padded_int(v)
            for k, v in obs.items()
            if k != "image"
        }
        obs["reward"] = reward
        if obs != self._prev_obs:
            print(obs)
            self._prev_obs = obs
