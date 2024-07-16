import os
from typing import Any, Optional

import gymnasium as gym
import numpy as np

from minetest.discrete_actions import MOVEMENT_KEYS

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
    hunger_rate: int = 20, thirst_rate: int = 20, allow_night: bool = False, **kwargs
) -> str:
    return f"""STARVE_1_MUL={hunger_rate}
STARVE_2_MUL={thirst_rate}
ALLOW_NIGHT={int(allow_night)}
"""
