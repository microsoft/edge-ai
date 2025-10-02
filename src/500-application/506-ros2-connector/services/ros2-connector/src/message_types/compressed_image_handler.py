"""
Compressed image message handler for ROS2 sensor_msgs/CompressedImage messages.

This module handles CompressedImage message processing and MQTT publishing.
"""

from sensor_msgs.msg import CompressedImage
from . import base_handler
BaseMessageHandler = base_handler.BaseMessageHandler


class CompressedImageMessageHandler(BaseMessageHandler):
    """Handler for ROS2 CompressedImage messages."""

    message_type = 'sensor_msgs/msg/CompressedImage'
    message_class = CompressedImage
    handler_type = 'image'

    def handle_message(
        self,
        msg: CompressedImage,
        topic_name: str,
        logger,
        mqtt_publisher
    ) -> None:
        """
        Process a received CompressedImage message and publish to MQTT.

        Args:
            msg: The received CompressedImage message
            topic_name: The ROS2 topic name
            logger: ROS2 logger instance
            mqtt_publisher: Function to publish to MQTT (topic, message)
        """
        count = self.message_counts.get(topic_name, 0)
        self.message_counts[topic_name] = count + 1

        # Log only every 25 messages to reduce noise
        if count % 25 == 0:
            logger.info(
                f'[{topic_name}] Received compressed image: {msg.format}, '
                f'size: {len(msg.data)} bytes (message #{count})'
            )
        else:
            logger.debug(
                f'[{topic_name}] Received compressed image: {msg.format}, '
                f'size: {len(msg.data)} bytes'
            )

        try:
            # Create MQTT data structure
            mqtt_data = self.create_base_mqtt_data(topic_name)
            mqtt_data.update({
                "format": msg.format,
                "data_size": len(msg.data),
                "image": "Placeholder for binary data",
                # Note: Base64 encoding disabled as in original code
                # "image_b64": base64.b64encode(msg.data).decode('utf-8'),
                "header": {
                    "stamp": {
                        "sec": msg.header.stamp.sec,
                        "nanosec": msg.header.stamp.nanosec
                    },
                    "frame_id": msg.header.frame_id
                }
            })

            # Publish to MQTT
            self.publish_to_mqtt(topic_name, mqtt_data, mqtt_publisher)

        except Exception as e:
            logger.error(
                f'Failed to process compressed image from {topic_name}: '
                f'{str(e)}'
            )
