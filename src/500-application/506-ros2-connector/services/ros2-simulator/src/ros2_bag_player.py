#!/usr/bin/env python3
"""
ROS2 Bag Playback Utility

Focused playback-only script for the ros2-simulator service.

Features:
- Plays a specified ROS2 bag (SQLite or MCAP) from a mounted directory
- Optional looping and rate control
- Optional topic include/exclude filtering
- Graceful shutdown on SIGINT/SIGTERM

Configuration via environment variables:
- BAG_PATH (required): Absolute or container path to bag directory
    (must contain metadata.yaml)
- PLAY_LOOP (default: true): Loop playback when reaching end
- PLAY_RATE (default: 1.0): Playback rate multiplier
- PLAY_INCLUDE (optional): Comma-separated list of topics to include
    (if set, only these play)
- PLAY_EXCLUDE (optional): Comma-separated list of topics to skip

Usage inside container (example):
  BAG_PATH=/app/resources/data/demo_bag python3 /app/src/ros2_bag_player.py

"""
import os
import sys
import time
import signal
from typing import Dict, Set, Optional

import rclpy
from rclpy.node import Node
from rclpy.serialization import deserialize_message
from rosidl_runtime_py.utilities import get_message
import rosbag2_py
import yaml  # Detect storage identifier (mcap/sqlite3) from metadata


def _env_bool(name: str, default: bool) -> bool:
    val = os.getenv(name)
    if val is None:
        return default
    return val.strip().lower() in {"1", "true", "yes", "on"}


def _env_set(name: str) -> Optional[Set[str]]:
    raw = os.getenv(name)
    if not raw:
        return None
    return {t.strip() for t in raw.split(',') if t.strip()}


class BagPlayer(Node):
    def __init__(self, bag_path: str, loop: bool = True, rate: float = 1.0,
                 include: Optional[Set[str]] = None,
                 exclude: Optional[Set[str]] = None):
        super().__init__('ros2_bag_player')
        self.bag_path = bag_path
        self.loop = loop
        self.rate = rate if rate > 0 else 1.0
        self.include = include
        self.exclude = exclude or set()

        self._reader = None
        self._topic_types: Dict[str, str] = {}
        # Map of topic name -> Publisher instance (avoid name clash with
        # Node internal _publishers list used by rclpy)
        self._topic_publishers: Dict[str, any] = {}

        self._open_reader()
        self.get_logger().info(
            "BagPlayer initialized: "
            f"path={bag_path} loop={loop} rate={self.rate}"
        )
        if self.include:
            self.get_logger().info(f"Include filter: {sorted(self.include)}")
        if self.exclude:
            self.get_logger().info(f"Exclude filter: {sorted(self.exclude)}")

    def _detect_storage_id(self) -> str:
        """Detect storage id (mcap/sqlite3) via metadata.yaml if present.

        Falls back to trying both if detection fails.
        """
        metadata_path = os.path.join(self.bag_path, 'metadata.yaml')
        if os.path.isfile(metadata_path):
            try:
                with open(metadata_path, 'r', encoding='utf-8') as f:
                    meta = yaml.safe_load(f) or {}
                storage_id = meta.get(
                    'rosbag2_bagfile_information', {}
                ).get('storage_identifier')
                if storage_id:
                    return storage_id
            except Exception as exc:  # pragma: no cover - best effort
                self.get_logger().warn(
                    f"Failed to parse metadata.yaml storage id: {exc}"
                )
        return 'sqlite3'  # default fallback

    def _open_reader(self):
        # Determine storage id (mcap/sqlite3). If primary fails try fallback.
        primary_id = self._detect_storage_id()
        fallback_id = 'mcap' if primary_id == 'sqlite3' else 'sqlite3'

        def _try_open(storage_id: str) -> bool:
            storage_options = rosbag2_py.StorageOptions(
                uri=self.bag_path,
                storage_id=storage_id
            )
            converter_options = rosbag2_py.ConverterOptions(
                input_serialization_format='cdr',
                output_serialization_format='cdr'
            )
            reader = rosbag2_py.SequentialReader()
            try:
                reader.open(storage_options, converter_options)
                self._reader = reader
                self._topic_types = {
                    t.name: t.type for t in reader.get_all_topics_and_types()
                }
                return True
            except Exception as exc:  # pragma: no cover - runtime dependent
                self.get_logger().warn(
                    f"Failed to open with storage '{storage_id}': {exc}"
                )
                return False

        if not _try_open(primary_id) and not _try_open(fallback_id):
            raise RuntimeError(
                "No storage could be initialized for bag at "
                f"{self.bag_path} (tried {primary_id}, {fallback_id})"
            )

        if not self._topic_types:
            raise RuntimeError(f"No topics found in bag: {self.bag_path}")

        self.get_logger().info(
            "Opened bag with storage id: "
            f"{primary_id if self._reader else 'unknown'} "
            f"topics={len(self._topic_types)}"
        )

    def _reset_reader(self):
        self.get_logger().info('Looping bag playback...')
        self._open_reader()

    def _topic_allowed(self, topic: str) -> bool:
        if self.include and topic not in self.include:
            return False
        if topic in self.exclude:
            return False
        return True

    def play(self):
        first_timestamp = None
        wall_start = time.time()
        while rclpy.ok():
            if not self._reader.has_next():
                if self.loop:
                    self._reset_reader()
                    first_timestamp = None
                    wall_start = time.time()
                    continue
                break
            topic, data, timestamp = self._reader.read_next()
            if not self._topic_allowed(topic):
                continue
            if topic not in self._topic_publishers:
                msg_type = get_message(self._topic_types[topic])
                self._topic_publishers[topic] = self.create_publisher(
                    msg_type, topic, 10)
            if first_timestamp is None:
                first_timestamp = timestamp
                wall_start = time.time()
            # Basic rate synchronization
            sim_elapsed = (timestamp - first_timestamp) / 1e9
            target_elapsed = sim_elapsed / self.rate
            real_elapsed = time.time() - wall_start
            if target_elapsed > real_elapsed:
                time.sleep(target_elapsed - real_elapsed)
            msg_type = get_message(self._topic_types[topic])
            msg = deserialize_message(data, msg_type)
            self._topic_publishers[topic].publish(msg)


def main(argv=None):
    bag_path = os.getenv('BAG_PATH')
    if not bag_path:
        print(
            'ERROR: BAG_PATH environment variable is required',
            file=sys.stderr
        )
        return 2
    if not os.path.isdir(bag_path):
        print(
            f'ERROR: BAG_PATH directory not found: {bag_path}',
            file=sys.stderr
        )
        return 2
    metadata_file = os.path.join(bag_path, 'metadata.yaml')
    if not os.path.isfile(metadata_file):
        print(
            'ERROR: metadata.yaml not found in bag directory: ' f'{bag_path}',
            file=sys.stderr
        )
        return 2

    loop = _env_bool('PLAY_LOOP', True)
    rate = float(os.getenv('PLAY_RATE', '1.0'))
    include = _env_set('PLAY_INCLUDE')
    exclude = _env_set('PLAY_EXCLUDE') or set()

    rclpy.init(args=argv)
    node = BagPlayer(bag_path, loop=loop, rate=rate,
                     include=include, exclude=exclude)

    shutdown = False

    def handle_signal(signum, frame):
        nonlocal shutdown
        shutdown = True
        node.get_logger().info(f'Received signal {signum}, shutting down...')

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    try:
        node.play()
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()
    return 0


if __name__ == '__main__':  # pragma: no cover
    sys.exit(main())
