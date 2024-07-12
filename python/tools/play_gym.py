import argparse
import sys
from pathlib import Path

import gymnasium as gym
from gym_client import GymClient


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
