import os
import tempfile
from copy import deepcopy
from typing import Any, Optional, SupportsFloat

import gymnasium as gym

from minetest.discrete_actions import (
    KEYBOARD_ACTIONS,
    MOUSE_ACTIONS,
    NOOP_ACTION,
)
from minetest.minetest_env import MinetestEnv


def get_action_dicts(
    keyboard_action_keys: list[str],
    mouse_action_keys: list[str],
) -> list[dict[str, Any]]:
    n_keyboard_actions = len(keyboard_action_keys)
    n_mouse_actions = len(mouse_action_keys)
    action_dicts = [
        deepcopy(NOOP_ACTION) for _ in range(n_keyboard_actions + n_mouse_actions + 1)
    ]

    for action_idx, keyboard_key in enumerate(keyboard_action_keys):
        action_dicts[action_idx]["keys"] = KEYBOARD_ACTIONS[keyboard_key]

    mouse_action_values = [
        v for k, v in MOUSE_ACTIONS.items() if k in mouse_action_keys
    ]
    for action_idx, mouse_value in enumerate(
        mouse_action_values, start=n_keyboard_actions
    ):
        action_dicts[action_idx]["mouse"] = mouse_value

    return action_dicts


class MinetestDiscrete(gym.Wrapper):
    def __init__(
        self,
        game: str,
        screen_size: int = 128,
        executable: Optional[os.PathLike] = "minetest",
        headless: bool = True,
        config: Optional[dict[str, Any]] = None,
    ):
        """Wrapper for the MineRL environments.

        Args:
            game (str): the minetest game to play.
            screen_size (int): the height of the pixels observations.
                Default to 128.
            config (dict): game specific configuration
                Default to None
        """

        temp_dir = tempfile.mkdtemp(prefix="minetest_")
        game_dir = os.path.join(
            os.environ["CONDA_PREFIX"], "share/minetest/games/", game
        )

        if game == "boad":
            from minetest.boad_setup import (
                BOAD_ADDITIONAL_OBSERVATION_SPACES,
                BOAD_KEYBOARD_ACTION_KEYS,
                BOAD_MOUSE_ACTION_KEYS,
                write_boad_config,
            )

            game_dir = "/Users/ericalt/Documents/minetest/games/boad"
            write_boad_config(game_dir, config)
            additional_observation_spaces = BOAD_ADDITIONAL_OBSERVATION_SPACES
            keyboard_action_keys = BOAD_KEYBOARD_ACTION_KEYS
            mouse_action_keys = BOAD_MOUSE_ACTION_KEYS
        else:
            from minetest.discrete_actions import (
                KEYBOARD_ACTION_KEYS,
                MOUSE_ACTION_KEYS,
            )

            additional_observation_spaces = {}
            keyboard_action_keys = KEYBOARD_ACTION_KEYS
            mouse_action_keys = MOUSE_ACTION_KEYS

        env = MinetestEnv(
            display_size=(screen_size, screen_size),
            artifact_dir=os.path.join(temp_dir, "artifacts"),
            game_dir=game_dir,
            additional_observation_spaces=additional_observation_spaces,
            verbose_logging=True,
            executable=executable,
            headless=headless,
        )
        super().__init__(env)
        self._action_dicts = get_action_dicts(keyboard_action_keys, mouse_action_keys)
        self.action_space = gym.spaces.Discrete(
            len(keyboard_action_keys) + len(mouse_action_keys)
        )

    def step(
        self, action_idx: int
    ) -> tuple[dict[str, Any], SupportsFloat, bool, bool, dict[str, Any]]:
        action_dict = self._action_dicts[action_idx]
        cum_reward = 0
        for keyboard_action in action_dict["keys"]:
            action = {"keys": keyboard_action, "mouse": action_dict["mouse"]}
            obs, reward, terminated, truncated, info = self.env.step(action)
            cum_reward += reward
            if terminated or truncated:
                break
        return obs, cum_reward, terminated, truncated, info

    @property
    def display_size(self):
        return self.env.display_size
