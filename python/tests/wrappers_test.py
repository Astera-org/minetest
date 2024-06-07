from typing import Any, SupportsFloat

import gymnasium as gym
import numpy as np
from numpy.testing import assert_array_equal

from minetest.wrappers import MaxEpisodeLengthWrapper, MaxEpisodeLengthWrapperV0


class DummyEnv(gym.Env):
    def __init__(self):
        self.name = "dummy"
        self.action_space = gym.spaces.Text(max_length=10)
        self.observation_space = gym.spaces.Text(max_length=10)

    def step(
        self, action: Any
    ) -> tuple[Any, SupportsFloat, bool, bool, dict[str, Any]]:
        truncate = action == "truncate"
        return action, 0, False, truncate, {}

    def reset(
        self, *, seed: int | None = None, options: dict[str, Any] | None = None
    ) -> tuple[Any, dict[str, Any]]:
        return "reset", {}


def extract_truncated(step_result):
    obs, reward, terminated, truncated, info = step_result
    return truncated


def test_max_episode_length():
    env = DummyEnv()
    env = MaxEpisodeLengthWrapper(env, max_episode_length=3)

    _ = env.reset()
    # first two steps aren't truncated
    truncated = extract_truncated(env.step(""))
    assert not truncated
    truncated = extract_truncated(env.step(""))
    assert not truncated
    # third step is truncated
    truncated = extract_truncated(env.step(""))
    assert truncated
    # subsequent steps also truncated
    truncated = extract_truncated(env.step(""))
    assert truncated

    _ = env.reset()
    # initial steps are not truncated after resetting
    truncated = extract_truncated(env.step(""))
    assert not truncated
    # natural truncations preserved
    truncated = extract_truncated(env.step("truncate"))
    assert truncated


def test_max_episode_length_v0():
    env = gym.vector.SyncVectorEnv([lambda: DummyEnv() for _ in range(3)])
    assert isinstance(env, gym.vector.VectorEnv)
    env = MaxEpisodeLengthWrapperV0(env, max_episode_length=3)

    _ = env.reset()
    # first step isn't truncated
    truncated = extract_truncated(env.step(["", "", ""]))
    assert_array_equal(truncated, np.array([0, 0, 0], dtype=np.int32))
    # natural truncations preserved
    truncated = extract_truncated(env.step(["", "truncate", ""]))
    assert_array_equal(truncated, np.array([0, 1, 0], dtype=np.int32))
    # remaining episodes truncated in third step
    truncated = extract_truncated(env.step(["", "", ""]))
    assert_array_equal(truncated, np.array([1, 1, 1], dtype=np.int32))
    # subsequent steps also truncated
    truncated = extract_truncated(env.step(["", "", ""]))
    assert_array_equal(truncated, np.array([1, 1, 1], dtype=np.int32))

    _ = env.reset()
    # initial steps are not truncated after resetting
    truncated = extract_truncated(env.step(["", "", ""]))
    assert_array_equal(truncated, np.array([0, 0, 0], dtype=np.int32))
