import argparse
import sys
from pathlib import Path

import gymnasium as gym
from gym_client import GymClient

from minetest.boad_setup import (
    BOAD_KEYBOARD_ACTION_KEYS,
    BOAD_MOUSE_ACTION_KEYS,
    BOAD_NOOP_IDX,
)
from minetest.minetest_discrete import MinetestDiscrete
from minetest.wrappers import DiscreteActionWrapper


def get_server_addr_args(args):
    return {
        "server_addr": args.server_addr,
        "executable": None,
    }


def get_game_dir_args(repo_root):
    return {
        "game_dir": "/Users/ericalt/Documents/minetest/games/devtest",
        "executable": get_exeutable(repo_root),
        "headless": False,
    }


def get_exeutable(repo_root):
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
    else:
        minetest_executable = repo_root / "bin" / "minetest"
    return minetest_executable


def get_env(args, repo_root):
    if args.game == "boad":
        return DiscreteActionWrapper(
            MinetestDiscrete(
                "boad",
                executable=get_exeutable(repo_root),
                headless=False,
            ),
            keyboard_action_keys=BOAD_KEYBOARD_ACTION_KEYS,
            mouse_action_keys=BOAD_MOUSE_ACTION_KEYS,
            noop=BOAD_NOOP_IDX,
        )
    gym_make_args = {
        "id": "minetest-v0",
        "render_mode": "human",
        "display_size": (512, 512),
    }
    if args.server_addr:
        gym_make_args.update(get_server_addr_args(args))
    else:
        gym_make_args.update(get_game_dir_args(repo_root))
    return gym.make(**gym_make_args)


if __name__ == "__main__":
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument(
        "--game",
        type=str,
        default=None,
        help=("Minetest game (options: [boad])."),
    )
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
    repo_root = Path(__file__).parent.parent.parent
    with get_env(args, repo_root) as env, GymClient(env) as client:
        client.game_loop()
