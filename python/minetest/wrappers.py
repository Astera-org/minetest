import gymnasium as gym
import numpy as np

from minetest.minetest_env import KEY_MAP


class DiscreteActionWrapper(gym.ActionWrapper):
    def __init__(
        self,
        env: gym.Env,
        keyboard_action_keys: list[str],
        mouse_action_keys: list[str],
        noop: int = 0,
    ):
        super().__init__(env)
        self.keyboard_action_keys = keyboard_action_keys
        self.mouse_action_keys = mouse_action_keys
        self.noop = noop

    def action(self, action: dict[str, np.ndarray]) -> int:
        for idx, x in enumerate(action["keys"]):
            if x:
                key = KEY_MAP[idx]
                if key in self.keyboard_action_keys:
                    return self.keyboard_action_keys.index(key)
        if "mouse_left" in self.mouse_action_keys and action["mouse"][0] > 0:
            return len(self.keyboard_action_keys) + self.mouse_action_keys.index(
                "mouse_left"
            )
        if "mouse_right" in self.mouse_action_keys and action["mouse"][0] < 0:
            return len(self.keyboard_action_keys) + self.mouse_action_keys.index(
                "mouse_right"
            )
        if "mouse_up" in self.mouse_action_keys and action["mouse"][1] > 0:
            return len(self.keyboard_action_keys) + self.mouse_action_keys.index(
                "mouse_up"
            )
        if "mouse_down" in self.mouse_action_keys and action["mouse"][1] < 0:
            return len(self.keyboard_action_keys) + self.mouse_action_keys.index(
                "mouse_down"
            )
        return self.noop
