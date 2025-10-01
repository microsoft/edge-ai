# Standard library imports
import time
import os
from threading import Thread

# Third-party imports
import rclpy
from rclpy.node import Node
from paho.mqtt import client as mqtt_client
from flask import Flask, jsonify

# Local imports - use the message type registry
import message_types
get_supported_types = message_types.get_supported_types
create_handler = message_types.create_handler

# Configuration from environment variables
# Default to localhost for Docker
MQTT_BROKER = os.getenv('MQTT_BROKER', 'localhost')
MQTT_PORT = int(os.getenv('MQTT_PORT', '1883'))      # Standard MQTT port
MQTT_TOPIC_PREFIX = os.getenv('MQTT_TOPIC_PREFIX', 'robot')
HEALTH_PORT = 8080

# Dynamic topic discovery configuration
# Topic filter patterns (comma-separated, uses fnmatch patterns)
TOPIC_FILTER_PATTERNS = (
    os.getenv('TOPIC_FILTER_PATTERNS', '').split(',')
    if os.getenv('TOPIC_FILTER_PATTERNS') else []
)
EXCLUDE_SYSTEM_TOPICS = os.getenv('EXCLUDE_SYSTEM_TOPICS', 'true').lower() in [
    'true', '1', 'yes', 'on'
]

# Flask app for health checks
app = Flask(__name__)


@app.route('/health')
def health_check():
    """Health check endpoint for Docker container monitoring."""
    return jsonify({
        'status': 'healthy',
        'timestamp': time.time(),
        'service': 'ros2-connector'
    })


class MultiTopicSubscriber(Node):
    """
    ROS2 Node that subscribes to multiple topics with different message types
    and forwards them to MQTT. Supports String, JointState, and Image messages.
    """

    def __init__(self):
        """Initialize the node and set up MQTT connection and subscriptions."""
        super().__init__('multi_topic_subscriber')
        self.message_counts = {}  # Counter for received messages per topic
        self.discovered_topics = {}  # Store discovered topic configurations

        # Get supported message types from the registry
        self.supported_types = get_supported_types()
        self.handlers = {}  # Store handler instances per topic

        # Set up MQTT client
        self.client = self.connect_mqtt()

        # Set up subscriptions using dynamic discovery
        self.topic_subscriptions = {}
        self.discover_and_subscribe_topics()

        self.get_logger().info(
            f'Subscribed to {len(self.topic_subscriptions)} topics'
        )

    def discover_and_subscribe_topics(self):
        """Dynamically discover and subscribe to available topics."""
        self.get_logger().info('Starting dynamic topic discovery...')

        # Wait a moment for node graph to be established
        import time
        time.sleep(2.0)

        try:
            # Get all available topics and their types
            topic_names_and_types = self.get_topic_names_and_types()

            discovered_count = 0
            unsupported_types = set()  # Track unsupported message types

            for topic_name, topic_types in topic_names_and_types:
                # Skip system topics if configured to do so
                if EXCLUDE_SYSTEM_TOPICS and self._is_system_topic(topic_name):
                    continue

                # Apply topic filter patterns if specified
                if (TOPIC_FILTER_PATTERNS and
                        not self._matches_filter_patterns(topic_name)):
                    continue

                # Check if we support any of the message types for this topic
                supported = False
                for topic_type in topic_types:
                    if topic_type in self.supported_types:
                        # Create handler instance for this topic
                        handler = create_handler(topic_type, MQTT_TOPIC_PREFIX)
                        self.handlers[topic_name] = handler

                        # Store configuration for backwards compatibility
                        config = {
                            'type': handler.handler_type,
                            'msg_class': handler.message_class
                        }
                        self.discovered_topics[topic_name] = config

                        self.create_dynamic_subscription(topic_name, handler)
                        discovered_count += 1
                        supported = True
                        self.get_logger().info(
                            f'Discovered and subscribed to {topic_name} '
                            f'({topic_type})'
                        )
                        break  # Only subscribe once per topic
                    else:
                        unsupported_types.add(topic_type)

                if not supported:
                    self.get_logger().debug(
                        f'Skipped topic {topic_name} with unsupported types: '
                        f'{topic_types}'
                    )

            # Log summary of unsupported message types for easy identification
            if unsupported_types:
                self.get_logger().info(
                    f'Found {len(unsupported_types)} unsupported '
                    f'message types:'
                )
                for msg_type in sorted(unsupported_types):
                    self.get_logger().info(f'  - {msg_type}')
                self.get_logger().info(
                    'Add to TYPE_MAPPING to support more topics'
                )

            self.get_logger().info(
                f'Dynamic discovery completed. Found {discovered_count} '
                f'compatible topics.'
            )

        except Exception as e:
            self.get_logger().error(f'Failed during topic discovery: {str(e)}')
            self.get_logger().warn(
                'No topics subscribed due to discovery failure'
            )

    def _is_system_topic(self, topic_name):
        """Check if a topic is a system topic that should be excluded."""
        system_prefixes = ['/rosout', '/parameter_events', '/events/', '/_']
        return any(topic_name.startswith(prefix) for prefix in system_prefixes)

    def _matches_filter_patterns(self, topic_name):
        """Check if topic name matches configured filter patterns."""
        import fnmatch
        return any(
            fnmatch.fnmatch(topic_name, pattern.strip())
            for pattern in TOPIC_FILTER_PATTERNS if pattern.strip()
        )

    def create_dynamic_subscription(self, topic_name, handler):
        """Create a subscription for a dynamically discovered topic."""
        try:
            # Initialize message count for this topic
            self.message_counts[topic_name] = 0

            # Create callback using the handler
            callback = handler.create_callback(
                topic_name,
                self.get_logger(),
                self.publish_mqtt
            )

            # Create the subscription
            subscription = self.create_subscription(
                handler.message_class,
                topic_name,
                callback,
                10
            )

            self.topic_subscriptions[topic_name] = subscription

        except Exception as e:
            self.get_logger().error(
                f'Failed to create subscription for {topic_name}: {str(e)}'
            )

    def connect_mqtt(self):
        """
        Establish connection to the MQTT broker with retry logic.

        Returns:
            mqtt_client: Connected MQTT client instance
        """
        def on_connect(client, userdata, flags, rc):
            # Callback executed when connection completes
            if rc == 0:
                print("Connected to MQTT Broker!")
            else:
                print(f"Failed to connect to MQTT broker, return code {rc}")

        # Create and configure MQTT client (fix deprecation warning)
        client = mqtt_client.Client(
            client_id="ros2-connector",
            userdata=None,
            protocol=mqtt_client.MQTTv311,
            clean_session=True
        )
        client.on_connect = on_connect

        # Retry connection with exponential backoff
        max_retries = 5
        retry_delay = 1

        for attempt in range(max_retries):
            try:
                print(f"Attempting to connect to MQTT broker "
                      f"{MQTT_BROKER}:{MQTT_PORT} "
                      f"(attempt {attempt + 1}/{max_retries})")
                client.connect(MQTT_BROKER, MQTT_PORT, 60)
                # Start the network loop in background thread
                client.loop_start()
                print("MQTT connection established successfully")
                return client
            except Exception as e:
                print(f"Failed to connect to MQTT broker "
                      f"(attempt {attempt + 1}): {e}")
                if attempt < max_retries - 1:
                    print(f"Retrying in {retry_delay} seconds...")
                    time.sleep(retry_delay)
                    retry_delay *= 2  # Exponential backoff
                else:
                    print("All MQTT connection attempts failed")
                    return None

    def publish_mqtt(self, mqtt_topic, msg):
        """
        Publish a message to the MQTT broker.

        Args:
            mqtt_topic: The MQTT topic to publish to
            msg: The message to publish (should be serialized to string)
        """
        if self.client is None or not self.client.is_connected():
            self.get_logger().warn(
                "MQTT client not connected, skipping publish"
            )
            return

        # Publish the message and check result
        result = self.client.publish(mqtt_topic, msg)
        if result[0] == 0:
            self.get_logger().debug(f"Published to MQTT topic: {mqtt_topic}")
        else:
            self.get_logger().error(
                f"Failed to send message to topic {mqtt_topic}"
            )


def run_health_server():
    """Run the Flask health check server in a separate thread."""
    app.run(host='0.0.0.0', port=HEALTH_PORT, debug=False)


def main(args=None):
    """
    Main entry point for the ROS2 node.
    Initializes rclpy, creates the node, and handles cleanup.

    Args:
        args: Command-line arguments passed to rclpy.init
    """
    # Start health check server in background
    health_thread = Thread(target=run_health_server, daemon=True)
    health_thread.start()

    # Initialize ROS2 Python client
    rclpy.init(args=args)

    # Create and spin the node
    node = MultiTopicSubscriber()
    try:
        print("ROS2 Multi-Topic Connector started")
        print("Dynamic topic discovery enabled")
        supported_types = get_supported_types()
        print(f"Supported message types: {list(supported_types.keys())}")
        print(f"MQTT broker: {MQTT_BROKER}:{MQTT_PORT}")
        print(f"MQTT topic prefix: {MQTT_TOPIC_PREFIX}")
        print(f"Health check available at: "
              f"http://localhost:{HEALTH_PORT}/health")
        rclpy.spin(node)  # Keep the node running until interrupted
    except KeyboardInterrupt:
        # Handle graceful shutdown on Ctrl+C
        print("Shutting down...")

    # Clean up resources
    node.destroy_node()
    rclpy.shutdown()


# Entry point
if __name__ == '__main__':
    main()
