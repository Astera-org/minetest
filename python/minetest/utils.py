import socket
from abc import ABC, abstractmethod
from typing import Any


class DataProcessor(ABC):
    @abstractmethod
    def process(self, obs: Any, reward: float) -> None:
        pass


def get_free_port():
    # take a lucky guess at a free port
    # Have the OS return a free port, then immediately close the socket.
    # Not guaranteed to be free, but should be good enough
    s = socket.socket()
    s.bind(("", 0))
    port = s.getsockname()[1]
    s.close()
    return port
