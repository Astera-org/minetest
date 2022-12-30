import os

import zmq


class DataRecorder:
    def __init__(
        self,
        data_path: os.PathLike,
        target_address: str,
        timeout: int = 1000,
        max_queue_length: int = 1200,
        max_attempts: int = 10,
    ):
        self.target_address = target_address
        self.data_path = data_path
        self.timeout = timeout
        self.max_queue_length = max_queue_length
        self.max_attempts = max_attempts

        self._recording = False

        # Setup ZMQ
        self.context = zmq.Context()
        self.socket = self.context.socket(zmq.SUB)
        self.socket.RCVTIMEO = self.timeout
        self.socket.connect(f"tcp://{self.target_address}")

        # Subscribe to all topics
        self.socket.setsockopt(zmq.SUBSCRIBE, b"")

        # Set maximum message queue length (high water mark)
        self.socket.setsockopt(zmq.RCVHWM, self.max_queue_length)

        # Set timeout in milliseconds
        self.socket.setsockopt(zmq.RCVTIMEO, 1000)

    def start(self):
        with open(self.data_path, "w") as out:
            self._recording = True
            num_attempts = 0
            while self._recording:
                try:
                    # Receive data
                    raw_data = self.socket.recv()
                    num_attempts = 0

                    # Write data to new line
                    out.write(str(raw_data) + "\n")
                except zmq.ZMQError as err:
                    if err.errno == zmq.EAGAIN:
                        print(f"Reception attempts: {num_attempts}")
                        if num_attempts >= self.max_attempts:
                            print("Session finished.")
                            self._recording = False
                        num_attempts += 1
                    else:
                        print(f"ZMQError: {err}")
                        self._recording = False

    def stop(self):
        self._recording = False


if __name__ == "__main__":
    address = "localhost:5555"
    data_dir = "data.bin"
    num_attempts = 10
    recorder = DataRecorder(data_dir, address, max_attempts=num_attempts)
    recorder.start()  # warning: file quickly grows very large
