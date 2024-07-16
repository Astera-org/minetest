import itertools
from collections import OrderedDict
from copy import deepcopy
from typing import Iterator

import numpy as np

from minetest.minetest_env import KEY_MAP as KEYBOARD_ACTION_KEYS

# Keyboard actions
N_KEYBOARD_ACTIONS = len(KEYBOARD_ACTION_KEYS)
KEYBOARD_NOOP = np.zeros(N_KEYBOARD_ACTIONS)
MOVEMENT_KEYS = ["forward", "left", "backward", "right"]


def get_keyboard_actions(key: str, idx: int) -> Iterator[np.ndarray]:
    action_value = deepcopy(KEYBOARD_NOOP)
    action_value[idx] = 1
    if key in MOVEMENT_KEYS:
        return tuple(
            itertools.chain(
                itertools.repeat(action_value, times=32),
                itertools.repeat(KEYBOARD_NOOP, times=16),
            )
        )
    return (action_value,)


KEYBOARD_ACTIONS = OrderedDict(
    [(k, get_keyboard_actions(k, idx)) for idx, k in enumerate(KEYBOARD_ACTION_KEYS)]
)

# Mouse actions
MOUSE_NOOP = [0, 0]
MOUSE_SCALE = 64
MOUSE_ACTIONS = OrderedDict(
    [
        ("mouse_left", [MOUSE_SCALE, 0]),
        ("mouse_right", [-MOUSE_SCALE, 0]),
        ("mouse_up", [0, MOUSE_SCALE]),
        ("mouse_down", [0, -MOUSE_SCALE]),
    ]
)
N_MOUSE_ACTIONS = len(MOUSE_ACTIONS)
MOUSE_ACTION_KEYS = list(MOUSE_ACTIONS.keys())


def get_mouse_actions(unit_action: list[int], n_steps: int) -> Iterator[list[int]]:
    cum_sweep = 0
    for step in range(1, n_steps + 1):
        next_cum_sweep = MOUSE_SCALE * (step // n_steps)
        diff = next_cum_sweep - cum_sweep
        yield [x * diff for x in unit_action]
        cum_sweep = next_cum_sweep
    yield from itertools.repeat(MOUSE_NOOP)


# actions
NOOP_ACTION = {
    "keys": (KEYBOARD_NOOP,),
    "mouse": MOUSE_NOOP,
}
ACTION_KEYS = KEYBOARD_ACTION_KEYS + MOUSE_ACTION_KEYS
REPEATED_ACTION_KEYS = set(MOVEMENT_KEYS + MOUSE_ACTION_KEYS)
REPEATED_ACTION_IDXS = set(
    [i for i, v in enumerate(ACTION_KEYS) if v in REPEATED_ACTION_KEYS]
)
