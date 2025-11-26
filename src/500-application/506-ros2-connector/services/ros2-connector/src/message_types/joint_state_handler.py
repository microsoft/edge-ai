"""
Joint state message handler for ROS2 sensor_msgs/JointState messages.

This module handles JointState message processing and MQTT publishing.
"""

from math import floor
from sensor_msgs.msg import JointState
from . import base_handler
BaseMessageHandler = base_handler.BaseMessageHandler


class JointStateMessageHandler(BaseMessageHandler):
    """Handler for ROS2 JointState messages."""

    message_type = 'sensor_msgs/msg/JointState'
    message_class = JointState
    handler_type = 'joint_state'

    def handle_message(
        self,
        msg: JointState,
        topic_name: str,
        logger,
        mqtt_publisher
    ) -> None:
        """
        Process a received JointState message and publish to MQTT.

        Args:
            msg: The received JointState message
            topic_name: The ROS2 topic name
            logger: ROS2 logger instance
            mqtt_publisher: Function to publish to MQTT (topic, message)
        """
        count = self.message_counts.get(topic_name, 0)
        count_divide = floor(count / 2)

        # Log only every 1000 messages to reduce noise
        if count % 5000 == 0:
            logger.info(
                f'[{topic_name}] Joint positions: {len(msg.position)} joints '
                f'(message #{count})'
            )
        else:
            logger.debug(
                f'[{topic_name}] Joint positions: {len(msg.position)} joints'
            )

        # Create MQTT data structure
        mqtt_data = self.create_base_mqtt_data(topic_name)
        mqtt_data.update({
            "count_divide": count_divide,
            "position": list(msg.position),
            "velocity": list(msg.velocity) if msg.velocity else [],
            "effort": list(msg.effort) if msg.effort else [],
            "names": list(msg.name) if msg.name else []
        })

        # Publish to MQTT
        self.publish_to_mqtt(topic_name, mqtt_data, mqtt_publisher)
