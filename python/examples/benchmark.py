import os
import subprocess
from pathlib import Path
import tempfile
import time

import gymnasium
import gymnasium.vector

import numpy as np
from tqdm import trange

from minetest import minetest_env

repo_root = repo_root = Path(__file__).parent.parent.parent
temp_dir = tempfile.mkdtemp(prefix="minetest_")
game_dir = os.path.join(os.environ["CONDA_PREFIX"], "share/minetest/games/devtest")
# install devtest game if needed
if not os.path.exists(game_dir):
    os.makedirs(os.path.dirname(game_dir), exist_ok=True)
    os.symlink(os.path.realpath(os.path.join(repo_root, "games/devtest")), game_dir)

# use minetest from repo if needed
minetest_executable = os.path.join(os.environ["CONDA_PREFIX"], "bin/minetest")
if not os.path.exists(minetest_executable):
    minetest_executable = os.path.join(repo_root, "bin/minetest")
print(f"Using minetest executable: {minetest_executable}")

version_str = subprocess.check_output((minetest_executable, "--version"))
build_type_prefix = "BUILD_TYPE="
for line in version_str.decode().split("\n"):
    if line.startswith(build_type_prefix):
        build_type = line[len(build_type_prefix):]
        assert build_type == "Release", f"Benchmark should happen on a release build, got: {build_type}"

def benchmark(env):
    empty_action = {"keys": np.ndarray(0), "mouse": np.zeros((2,))}
    num_envs = 1
    if isinstance(env, gymnasium.vector.VectorEnv):
        num_envs = env.num_envs
        empty_action = {k: np.zeros((num_envs,) + v.shape) for k, v in empty_action.items()}
    with env:
        env.reset()
        start = time.time()
        n_steps = 1000
        for _ in trange(n_steps):
            observation, reward, done, truncated, info = env.step(empty_action)
            if isinstance(done, np.ndarray):
                done = done.any()
            if done:
                raise ValueError("Environment done unexpectedly")
        stop = time.time()

    print("SPS:", n_steps * num_envs / (stop - start))


envs = []

envs.append(
    ("minetest_no_vec",
     minetest_env.MinetestEnv(
        executable=minetest_executable,
        artifact_dir=os.path.join(temp_dir, "artifacts"),
        game_dir=game_dir,
        headless=True,
    )))

envs.append(
    ("minetest_vec24",
     gymnasium.vector.AsyncVectorEnv(
         [
            lambda: minetest_env.MinetestEnv(
                executable=minetest_executable,
                artifact_dir=os.path.join(temp_dir, "artifacts"),
                game_dir=game_dir,
                headless=True,
                log_to_stderr=True,
            ) for _ in range(24)
         ]
    )))

class NoopEnv(gymnasium.Env):
    observation_space = gymnasium.spaces.Discrete(1)
    action_space = gymnasium.spaces.Dict({
        "keys": gymnasium.spaces.MultiBinary(len(minetest_env.KEY_MAP)),
        "mouse": gymnasium.spaces.Box(-1, 1, (2,))})
    def __init__(self):
        super().__init__()
    def step(self, action):
        return 0, 0, False, False, {}
    def reset(self):
        return 0, {}

envs.append(("noop_no_vec",
             NoopEnv()))

envs.append(("noop_vec_24",
             gymnasium.vector.AsyncVectorEnv([NoopEnv for _ in range(24)])))

for name, env in envs:
    print(name)
    benchmark(env)
