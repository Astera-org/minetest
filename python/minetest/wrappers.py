from typing import Any, SupportsFloat

import gymnasium as gym
import numpy as np
from gymnasium.core import ActType, ObsType
from gymnasium.vector.vector_env import VectorEnv
from numpy.typing import NDArray


class MaxEpisodeLengthWrapper(gym.Wrapper):
    """An env wrapper that truncates episodes that reach a maximum length."""

    def __init__(self, env: gym.Env, max_episode_length: int):
        """Initialize MaxEpisodeLengthWrapper wrapper.

        Args:
            env (Env): The vector environment to wrap
            max_episode_length (int): The maximum allowable expisode length
        """
        super().__init__(env)
        self._max_episode_length = max_episode_length
        self._episode_length = 0

    def step(
        self, action: Any
    ) -> tuple[Any, SupportsFloat, bool, bool, dict[str, Any]]:
        obs, reward, terminated, truncated, info = super().step(action)
        self._episode_length += 1
        if not terminated and self._episode_length >= self._max_episode_length:
            truncated = True
        return obs, reward, terminated, truncated, info

    def reset(
        self, *, seed: int | None = None, options: dict[str, Any] | None = None
    ) -> tuple[Any, dict[str, Any]]:
        self._episode_length = 0
        return super().reset(seed=seed, options=options)


class MaxEpisodeLengthWrapperV0(gym.vector.VectorEnvWrapper):
    """A vector env wrapper that truncates episodes that reach a maximum length."""

    def __init__(self, env: VectorEnv, max_episode_length: int):
        """Initialize MaxEpisodeLengthWrapper wrapper.

        Args:
            env (VectorEnv): The vector environment to wrap
            max_episode_length (int): The maximum allowable expisode length
        """
        super().__init__(env)
        self._max_episode_length = max_episode_length
        self._episode_lengths = np.zeros(self.num_envs, dtype=np.int32)

    def step(self, actions: ActType) -> tuple[ObsType, NDArray, NDArray, NDArray, dict]:
        obs, rewards, terminated, truncated, info = super().step(actions)
        self._episode_lengths += 1
        timed_outs = np.logical_not(terminated) & (
            self._episode_lengths >= self._max_episode_length
        )
        truncated[timed_outs] = True
        return obs, rewards, terminated, truncated, info

    def reset(
        self,
        *,
        seed: int | list[int] | None = None,
        options: dict[str, Any] | None = None,
    ) -> tuple[ObsType, dict[str, Any]]:
        self._episode_lengths[:] = 0
        return super().reset(seed=seed, options=options)
