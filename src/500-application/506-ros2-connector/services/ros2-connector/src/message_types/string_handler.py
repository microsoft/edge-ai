"""
String message handler for ROS2 std_msgs/String messages.

This module handles String message processing and MQTT publishing.
"""

from std_msgs.msg import String
from . import base_handler
BaseMessageHandler = base_handler.BaseMessageHandler


class StringMessageHandler(BaseMessageHandler):
    """Handler for ROS2 String messages."""

    message_type = 'std_msgs/msg/String'
    message_class = String
    handler_type = 'string'

    def handle_message(
        self,
        msg: String,
        topic_name: str,
        logger,
        mqtt_publisher
    ) -> None:
        """
        Process a received String message and publish to MQTT.

        Args:
            msg: The received String message
            topic_name: The ROS2 topic name
            logger: ROS2 logger instance
            mqtt_publisher: Function to publish to MQTT (topic, message)
        """
        count = self.message_counts.get(topic_name, 0)

        # Log only every 50 messages to reduce noise
        if count % 50 == 0:
            logger.info(
                f'[{topic_name}] Received: "{msg.data}" (message #{count})'
            )
        else:
            logger.debug(f'[{topic_name}] Received: "{msg.data}"')

        # Create MQTT data structure
        mqtt_data = self.create_base_mqtt_data(topic_name)
        mqtt_data.update({
            "message": msg.data
        })

        # Publish to MQTT
        self.publish_to_mqtt(topic_name, mqtt_data, mqtt_publisher)
