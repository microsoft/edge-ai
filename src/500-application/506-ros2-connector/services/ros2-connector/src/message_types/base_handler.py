"""ROS2 message handler abstraction.

This module provides the :class:`BaseMessageHandler` abstract base class which
standardizes how ROS2 messages are received from subscriptions, transformed
into a normalized dictionary payload, and published to MQTT.

Subclass contract:
    1. Set the class attributes ``message_type``, ``message_class`` and
       ``handler_type`` (a short identifier used in topics/payloads).
    2. Implement :meth:`handle_message` to:
        * Extract domain fields from the ROS2 message instance
        * Call :meth:`create_base_mqtt_data` to get the common envelope
        * Add message‐specific fields to the envelope
        * Invoke :meth:`publish_to_mqtt` with the final structure

Key responsibilities factored into helper methods:
    * Subscription callback creation (:meth:`create_callback`)
    * MQTT topic name derivation (:meth:`format_mqtt_topic`)
    * Common payload envelope with metadata (:meth:`create_base_mqtt_data`)
    * JSON serialization and publish helper (:meth:`publish_to_mqtt`)

The class maintains a per-topic message counter to aid downstream consumers
with ordering diagnostics or rate calculations. No persistence is attempted
and counters reset with process lifetime.
"""

import json
import time
from abc import ABC, abstractmethod
from typing import Any, Dict, Callable


class BaseMessageHandler(ABC):
    """Abstract base class for concrete ROS2 message handlers.

    Subclasses adapt a specific ROS2 message type into a normalized MQTT JSON
    payload. They must set the identifying class attributes and implement
    :meth:`handle_message`.

    Class Attributes
    ----------------
    message_type: str | None
    Fully-qualified ROS2 message type string (e.g.
    ``"std_msgs/msg/String"``).
    message_class: type | None
    Actual Python class for the ROS2 message (e.g.
    ``std_msgs.msg.String``).
    handler_type: str | None
        Short, lowercase identifier used in MQTT topics & payloads
        (e.g. ``"string"`` or ``"twist"``).
    """

    # Class-level identifiers (must be overridden by subclasses)
    message_type: str | None = None
    message_class: type | None = None
    handler_type: str | None = None

    def __init__(self, mqtt_topic_prefix: str = "robot"):
        """Initialize a handler instance.

        Parameters
        ----------
        mqtt_topic_prefix: str, default="robot"
            Root prefix prepended to all derived MQTT topics produced by this
            handler.

        Notes
        -----
        A per-topic in-memory counter (``message_counts``) is maintained to
        include an ever-incrementing ``count`` field in published payloads to
        help consumers detect drops or compute simple rates.
        """
        self.mqtt_topic_prefix = mqtt_topic_prefix
        self.message_counts = {}

    def create_callback(
        self,
        topic_name: str,
        logger,
        mqtt_publisher: Callable[[str, str], None]
    ) -> Callable:
        """Produce a ROS2 subscription callback bound to this handler.

        The returned closure increments an internal per-topic counter then
        delegates to :meth:`handle_message` for transformation & publishing.

        Parameters
        ----------
        topic_name: str
            ROS2 topic name being subscribed to.
        logger
            ROS2 logger (duck-typed; must provide ``info`` / ``warning`` /
            ``error`` if used).
        mqtt_publisher: Callable[[str, str], None]
            Function that accepts ``(mqtt_topic, json_string)``.

        Returns
        -------
        Callable
            Function taking a single ROS2 message argument. Suitable for
            passing directly as the subscription callback.
        """
        # Initialize message count for this topic
        if topic_name not in self.message_counts:
            self.message_counts[topic_name] = 0

        def callback(msg):
            self.message_counts[topic_name] += 1
            self.handle_message(msg, topic_name, logger, mqtt_publisher)

        return callback

    @abstractmethod
    def handle_message(
        self,
        msg: Any,
        topic_name: str,
        logger,
        mqtt_publisher: Callable[[str, str], None]
    ) -> None:
        """Transform a ROS2 message to MQTT payload (implemented by subclass).

        Implementations SHOULD:
            1. Call :meth:`create_base_mqtt_data` to obtain the standard
               envelope (contains topic, handler type, count, timestamp).
                2. Add message-type specific fields (e.g. ``data``, ``linear``
                    etc.).
            3. Invoke :meth:`publish_to_mqtt` with the composed payload.

        Parameters
        ----------
        msg: Any
            ROS2 message instance of ``message_class``.
        topic_name: str
            Original ROS2 topic name.
        logger
            ROS2 logger (optional usage—subclass may log anomalies).
        mqtt_publisher: Callable[[str, str], None]
            Function for publishing serialized JSON to MQTT.

        Raises
        ------
        NotImplementedError
            If the subclass fails to override this abstract method.
        """
        pass

    def format_mqtt_topic(self, topic_name: str) -> str:
        """Derive the final MQTT topic for a ROS2 source topic.

        The ROS2 topic path separators ('/') are converted to underscores to
        avoid accidental multi-level MQTT topic hierarchies unless the caller
        explicitly encodes them in ``handler_type`` or the prefix.

        Parameters
        ----------
        topic_name: str
            ROS2 topic name (e.g. ``"/cmd_vel"``).

        Returns
        -------
        str
            MQTT topic string of form ``"{prefix}/{handler_type}{sanitized}"``.
        """
        safe_topic = topic_name.replace('/', '_')
        return f"{self.mqtt_topic_prefix}/{self.handler_type}{safe_topic}"

    def create_base_mqtt_data(self, topic_name: str) -> Dict[str, Any]:
        """Build the common MQTT payload envelope.

        Parameters
        ----------
        topic_name: str
            ROS2 topic name from which the message originated.

        Returns
        -------
        dict
            Dictionary containing:
                ``topic`` (original ROS2 topic),
                ``type`` (handler_type),
                ``count`` (monotonic per-topic integer starting at 0),
                ``timestamp`` (float seconds since epoch).
        """
        return {
            "topic": topic_name,
            "type": self.handler_type,
            "count": self.message_counts.get(topic_name, 0),
            "timestamp": time.time()
        }

    def publish_to_mqtt(
        self,
        topic_name: str,
        data: Dict[str, Any],
        mqtt_publisher: Callable[[str, str], None]
    ) -> None:
        """Serialize and publish a payload to MQTT.

        Parameters
        ----------
        topic_name: str
            ROS2 topic name (used to derive MQTT topic).
        data: dict
            Fully populated payload dictionary (will be JSON serialized).
        mqtt_publisher: Callable[[str, str], None]
            Function responsible for the actual publish operation.

        Notes
        -----
        Serialization uses ``json.dumps`` with default settings; ensure all
        values are JSON encodable before calling.
        """
        mqtt_topic = self.format_mqtt_topic(topic_name)
        mqtt_message = json.dumps(data)
        mqtt_publisher(mqtt_topic, mqtt_message)
