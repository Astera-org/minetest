import argparse
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

import gymnasium as gym
import numpy as np
import pygame
from pygame.event import Event

from minetest.minetest_env import INVERSE_KEY_MAP, KEY_MAP

KEY_TO_KEYTYPE = {
    "W": "forward",
    "A": "left",
    "S": "backward",
    "D": "right",
    "SPACE": "jump",
    "LEFT SHIFT": "sneak",
    "J": "dig",
    "K": "place",
}
ARROW_KEYS_TO_MOUSE_DIRECTION = {
    "UP": (0, -1),
    "DOWN": (0, 1),
    "LEFT": (-1, 0),
    "RIGHT": (1, 0),
}


@dataclass
class Mouse:
    dx: float
    dy: float


def get_action_from_key_cache(
    key_cache: set[str], mouse: Mouse
) -> dict[str, np.ndarray]:
    keys = np.zeros(len(KEY_MAP), dtype=bool)
    for key in key_cache:
        if key in KEY_TO_KEYTYPE:
            keys[INVERSE_KEY_MAP[KEY_TO_KEYTYPE[key]]] = True

    mouse = np.array([mouse.dx, mouse.dy])
    return {"keys": keys, "mouse": mouse}


class GymClient:
    def __init__(
        self,
        env: gym.Env,
        mouse_magnitude: int = 20,
        get_action_from_key_cache: Callable[
            [set[str], Mouse], dict[str, np.ndarray]
        ] = get_action_from_key_cache,
    ):
        self._env = env
        self._keys_down = set()
        self._mouse = Mouse(0, 0)
        self._mouse_magnitude = mouse_magnitude
        self._get_action_from_key_cache = get_action_from_key_cache

    def __enter__(self):
        pygame.init()
        self._env.reset()
        return self

    def __exit__(self, exc_type: Any, exc_value: Any, traceback: Any) -> None:
        self._env.close()
        pygame.quit()

    def game_loop(self) -> None:
        running = True
        while running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type in [pygame.KEYDOWN, pygame.KEYUP]:
                    self._handle_key_event(event)

            action = self._get_action_from_key_cache(self._keys_down, self._mouse)
            state, reward, terminated, truncated, info = self._env.step(action)
            self._env.render()
            print(reward)

            if terminated or truncated:
                print("\n\n--TERMINATED--\n\n")
                running = False

    def _handle_key_event(self, event: Event) -> None:
        key = pygame.key.name(event.key).upper()

        if event.type == pygame.KEYDOWN:
            if key in KEY_TO_KEYTYPE:
                self._keys_down.add(key)
            if key in ARROW_KEYS_TO_MOUSE_DIRECTION:
                self._mouse.dx += (
                    ARROW_KEYS_TO_MOUSE_DIRECTION[key][0] * self._mouse_magnitude
                )
                self._mouse.dy += (
                    ARROW_KEYS_TO_MOUSE_DIRECTION[key][1] * self._mouse_magnitude
                )
        elif event.type == pygame.KEYUP:
            if key in KEY_TO_KEYTYPE and key in self._keys_down:
                self._keys_down.remove(key)
            if key in ARROW_KEYS_TO_MOUSE_DIRECTION:
                self._mouse.dx -= (
                    ARROW_KEYS_TO_MOUSE_DIRECTION[key][0] * self._mouse_magnitude
                )
                self._mouse.dy -= (
                    ARROW_KEYS_TO_MOUSE_DIRECTION[key][1] * self._mouse_magnitude
                )


def get_gym_args(__file__, args):
    gym_make_args = {
        "id": "minetest-v0",
        "render_mode": "human",
        "display_size": (512, 512),
    }
    if args.server_addr:
        gym_make_args["server_addr"] = args.server_addr
        gym_make_args["executable"] = None
    else:
        game_dir = "/Users/ericalt/Documents/minetest/games/devtest"
        gym_make_args["game_dir"] = game_dir
        # The Makefile puts the binary into build/macos
        repo_root = Path(__file__).parent.parent.parent
        minetest_executable = repo_root / "bin" / "minetest"
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
            # minetest_executable = "/opt/homebrew/bin/minetest"
        gym_make_args["executable"] = minetest_executable
        gym_make_args["headless"] = False
        gym_make_args["verbose_logging"] = True
    return gym_make_args


if __name__ == "__main__":
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument(
        "--server_addr",
        type=str,
        default=None,
        help=(
            "Minetest host:port to connect to. If set, will not "
            "start minetest (will assume it's already running)."
        ),
    )
    args = arg_parser.parse_args()
    gym_make_args = get_gym_args(__file__, args)
    with gym.make(**gym_make_args) as env, GymClient(env) as client:
        client.game_loop()
