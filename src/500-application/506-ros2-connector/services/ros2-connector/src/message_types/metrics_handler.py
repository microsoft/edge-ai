"""
Metrics message handler for ROS2 edge_ros_interface/Metrics messages.

This module handles Metrics message processing and MQTT publishing.
"""

from edge_ros_interface.msg import Metrics
from . import base_handler
BaseMessageHandler = base_handler.BaseMessageHandler


class MetricsMessageHandler(BaseMessageHandler):
    """Handler for ROS2 Metrics messages."""

    message_type = 'edge_ros_interface/msg/Metrics'
    message_class = Metrics
    handler_type = 'metrics'

    def handle_message(
        self,
        msg: Metrics,
        topic_name: str,
        logger,
        mqtt_publisher
    ) -> None:
        """
        Process a received Metrics message and publish to MQTT.

        Args:
            msg: The received Metrics message
            topic_name: The ROS2 topic name
            logger: ROS2 logger instance
            mqtt_publisher: Function to publish to MQTT (topic, message)
        """
        count = self.message_counts.get(topic_name, 0)

        # Log only every 25 messages to reduce noise
        if count % 25 == 0:
            logger.info(
                f'[{topic_name}] Metrics from {msg.source}: '
                f'{len(msg.values)} values (message #{count})'
            )
        else:
            logger.debug(
                f'[{topic_name}] Metrics from {msg.source}: '
                f'{len(msg.values)} values'
            )

        # Convert timestamp to a more manageable format
        timestamp_sec = msg.timestamp.sec + (msg.timestamp.nanosec / 1e9)

        # Convert metric values to a serializable format
        metric_values = []
        for value in msg.values:
            metric_value = {
                "name": value.name,
                "unit": value.unit,
                "value": value.value,
                "lower_limit": (value.lower_limit
                                if not self._is_nan(value.lower_limit)
                                else None),
                "upper_limit": (value.upper_limit
                                if not self._is_nan(value.upper_limit)
                                else None)
            }
            metric_values.append(metric_value)

        # Create MQTT data structure
        mqtt_data = self.create_base_mqtt_data(topic_name)
        mqtt_data.update({
            "source": msg.source,
            "timestamp_sec": timestamp_sec,
            "metric_values": metric_values,
            "num_metrics": len(msg.values)
        })

        # Publish to MQTT
        self.publish_to_mqtt(topic_name, mqtt_data, mqtt_publisher)

    def _is_nan(self, value: float) -> bool:
        """
        Check if a float value is NaN.

        Args:
            value: Float value to check

        Returns:
            True if value is NaN, False otherwise
        """
        # NaN is the only value that is not equal to itself
        return value != value
