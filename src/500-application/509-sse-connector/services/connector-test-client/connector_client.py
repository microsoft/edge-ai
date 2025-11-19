#!/usr/bin/env python3
"""SSE Connector Test Client for Azure IoT Operations.

This module provides a test client that simulates the behavior of an Akri SSE
connector. It connects to Server-Sent Events (SSE) endpoints, receives event
streams, and publishes the events to MQTT topics based on event type.

For production deployments, this client would be replaced by the actual Akri
SSE connector running in the Kubernetes cluster.

Environment Variables:
    AIO_BROKER_HOSTNAME: MQTT broker hostname (default: localhost)
    AIO_BROKER_TCP_PORT: MQTT broker port (default: 1883)
    AIO_MQTT_CLIENT_ID: MQTT client identifier (default: sse-connector-test)
    SSE_ENDPOINT: SSE server URL (default: http://localhost:8080/camera-events)
    TOPIC_HEARTBEAT: MQTT topic for heartbeat events (default: camera-events/heartbeat)
    TOPIC_ALERT: MQTT topic for basic alert events (default: camera-events/alert)
    TOPIC_ALERT_DLQC: MQTT topic for detailed alerts (default: camera-events/alert_dlqc)
    TOPIC_ANALYTICS_ENABLED: Topic for analytics enabled (default: camera-events/analytics_enabled)
    TOPIC_ANALYTICS_DISABLED: Topic for analytics disabled (default: camera-events/analytics_disabled)
    ERROR_TOPIC: Topic for error events (default: akri/sse-connector/errors)

Typical Usage:
    Set environment variables and run:

    $ export SSE_ENDPOINT=http://analytics-camera:8080/camera-events
    $ export AIO_BROKER_HOSTNAME=aio-mq-dmqtt-frontend
    $ python connector_client.py
"""

import asyncio
import json
import logging
import os
import signal
import sys
from typing import Optional

import aiohttp
import paho.mqtt.client as mqtt

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class SSEConnectorTestClient:
    """SSE Connector Test Client that bridges SSE events to MQTT topics.

    This client simulates Akri SSE connector behavior by establishing a
    persistent connection to an SSE endpoint, receiving event streams, and
    publishing events to appropriate MQTT topics based on event type.

    The client implements exponential backoff for connection retries and
    maintains statistics about events processed. It gracefully handles
    disconnections and shutdown signals.

    Attributes:
        mqtt_broker: MQTT broker hostname.
        mqtt_port: MQTT broker port number.
        mqtt_client_id: Unique identifier for MQTT client.
        sse_endpoint: URL of the SSE server endpoint.
        topic_*: MQTT topic names for different event types.
        mqtt_client: MQTT client instance (initialized in setup_mqtt).
        running: Flag controlling the main event loop.
        stats: Dictionary tracking events received, published, and errors.
    """

    def __init__(self):
        """Initialize the SSE connector test client with configuration from environment."""
        self.mqtt_broker = os.getenv('AIO_BROKER_HOSTNAME', 'localhost')
        self.mqtt_port = int(os.getenv('AIO_BROKER_TCP_PORT', '1883'))
        self.mqtt_client_id = os.getenv(
            'AIO_MQTT_CLIENT_ID',
            'sse-connector-test'
        )
        self.sse_endpoint = os.getenv(
            'SSE_ENDPOINT',
            'http://localhost:8080/camera-events'
        )

        self.topic_heartbeat = os.getenv(
            'TOPIC_HEARTBEAT',
            'camera-events/heartbeat'
        )
        self.topic_alert = os.getenv('TOPIC_ALERT', 'camera-events/alert')
        self.topic_alert_dlqc = os.getenv(
            'TOPIC_ALERT_DLQC',
            'camera-events/alert_dlqc'
        )
        self.topic_analytics_enabled = os.getenv(
            'TOPIC_ANALYTICS_ENABLED',
            'camera-events/analytics_enabled'
        )
        self.topic_analytics_disabled = os.getenv(
            'TOPIC_ANALYTICS_DISABLED',
            'camera-events/analytics_disabled'
        )
        self.topic_error = os.getenv(
            'ERROR_TOPIC',
            'akri/sse-connector/errors'
        )

        self.mqtt_client: Optional[mqtt.Client] = None
        self.running = True
        self.stats = {
            'events_received': 0,
            'events_published': 0,
            'errors': 0,
            'by_type': {}
        }

    def setup_mqtt(self):
        """Initialize and connect the MQTT client.

        Creates an MQTT client instance with configured callbacks and
        establishes connection to the MQTT broker. Starts the MQTT
        network loop in a background thread.

        Raises:
            Exception: If MQTT broker connection fails.
        """
        self.mqtt_client = mqtt.Client(
            client_id=self.mqtt_client_id,
            callback_api_version=mqtt.CallbackAPIVersion.VERSION1,
            protocol=mqtt.MQTTv311
        )

        self.mqtt_client.on_connect = self._on_mqtt_connect
        self.mqtt_client.on_disconnect = self._on_mqtt_disconnect
        self.mqtt_client.on_publish = self._on_mqtt_publish

        try:
            logger.info(
                f"Connecting to MQTT broker at "
                f"{self.mqtt_broker}:{self.mqtt_port}"
            )
            self.mqtt_client.connect(self.mqtt_broker, self.mqtt_port, 60)
            self.mqtt_client.loop_start()
        except Exception as e:
            logger.error(f"Failed to connect to MQTT broker: {e}")
            raise

    def _on_mqtt_connect(self, client, userdata, flags, rc):
        """Handle MQTT connection establishment.

        Args:
            client: MQTT client instance.
            userdata: User-defined data (unused).
            flags: Connection flags from broker.
            rc: Connection result code (0 = success).
        """
        if rc == 0:
            logger.info("Connected to MQTT broker successfully")
        else:
            logger.error(f"Failed to connect to MQTT broker with code {rc}")

    def _on_mqtt_disconnect(self, client, userdata, rc):
        """Handle MQTT disconnection events.

        Args:
            client: MQTT client instance.
            userdata: User-defined data (unused).
            rc: Disconnection reason code (0 = clean disconnect).
        """
        if rc != 0:
            logger.warning(f"Unexpected MQTT disconnection (code: {rc})")

    def _on_mqtt_publish(self, client, userdata, mid):
        """Handle MQTT publish acknowledgments.

        Updates statistics counter when message is successfully published.

        Args:
            client: MQTT client instance.
            userdata: User-defined data (unused).
            mid: Message ID of the published message.
        """
        self.stats['events_published'] += 1

    def get_topic_for_event_type(self, event_type: str) -> str:
        """Map SSE event type to corresponding MQTT topic.

        Routes different event types to appropriate MQTT topics for
        downstream processing. Unknown event types are routed to the
        error topic.

        Args:
            event_type: SSE event type string (HEARTBEAT, ALERT, etc.).

        Returns:
            MQTT topic path for the event type.
        """
        topic_map = {
            'HEARTBEAT': self.topic_heartbeat,
            'ALERT': self.topic_alert,
            'ALERT_DLQC': self.topic_alert_dlqc,
            'ANALYTICS_ENABLED': self.topic_analytics_enabled,
            'ANALYTICS_DISABLED': self.topic_analytics_disabled
        }
        return topic_map.get(event_type, self.topic_error)

    def publish_to_mqtt(self, topic: str, payload: dict):
        """Publish event data to MQTT topic with QoS 1.

        Serializes the event payload to JSON and publishes to the specified
        topic. Updates error statistics if publishing fails.

        Args:
            topic: MQTT topic path to publish to.
            payload: Event data dictionary to publish.
        """
        try:
            if self.mqtt_client is None:
                logger.error("MQTT client is not initialized")
                self.stats['errors'] += 1
                return

            payload_json = json.dumps(payload)
            result = self.mqtt_client.publish(topic, payload_json, qos=1)

            if result.rc != mqtt.MQTT_ERR_SUCCESS:
                logger.error(f"Failed to publish to {topic}: {result.rc}")
                self.stats['errors'] += 1
            else:
                logger.debug(f"Published to {topic}: {payload_json[:100]}...")

        except Exception as e:
            logger.error(f"Error publishing to MQTT: {e}")
            self.stats['errors'] += 1

    async def connect_to_sse(self):
        """Establish persistent connection to SSE endpoint with retry logic.

        Connects to the SSE server and processes the event stream. Implements
        exponential backoff retry strategy (1s → 2s → 4s ... → 60s max) for
        connection failures. Continues retrying until successful connection
        or maximum retries reached.

        The method parses SSE protocol format (event: and data: lines) and
        delegates event processing to process_event().

        Note:
            Connection remains open until client shutdown or unrecoverable error.
            Normal disconnections trigger automatic reconnection attempts.
        """
        retry_count = 0
        max_retries = 10
        retry_delay = 1

        while self.running and retry_count < max_retries:
            try:
                logger.info(f"Connecting to SSE endpoint: {self.sse_endpoint}")

                timeout = aiohttp.ClientTimeout(total=None, sock_connect=10)

                async with aiohttp.ClientSession(timeout=timeout) as session:
                    async with session.get(
                        self.sse_endpoint,
                        headers={'Accept': 'text/event-stream'}
                    ) as response:

                        if response.status != 200:
                            logger.error(
                                f"SSE endpoint returned status "
                                f"{response.status}"
                            )
                            retry_count += 1
                            await asyncio.sleep(retry_delay)
                            retry_delay = min(retry_delay * 2, 60)
                            continue

                        logger.info("Connected to SSE endpoint successfully")
                        retry_count = 0
                        retry_delay = 1

                        event_type = None
                        event_data = None

                        async for line in response.content:
                            if not self.running:
                                break

                            line_str = line.decode('utf-8').strip()

                            if not line_str:
                                if event_type and event_data:
                                    await self.process_event(
                                        event_type,
                                        event_data
                                    )
                                    event_type = None
                                    event_data = None
                                continue

                            if line_str.startswith('event:'):
                                event_type = line_str[6:].strip()

                            elif line_str.startswith('data:'):
                                event_data = line_str[5:].strip()

            except asyncio.CancelledError:
                logger.info("SSE connection cancelled")
                break

            except aiohttp.ClientError as e:
                logger.error(f"SSE connection error: {e}")
                retry_count += 1
                if retry_count < max_retries:
                    logger.info(
                        f"Retrying in {retry_delay} seconds... "
                        f"(attempt {retry_count}/{max_retries})"
                    )
                    await asyncio.sleep(retry_delay)
                    retry_delay = min(retry_delay * 2, 60)
                else:
                    logger.error("Max retries reached, giving up")
                    break

            except Exception as e:
                logger.error(f"Unexpected error in SSE connection: {e}")
                retry_count += 1
                await asyncio.sleep(retry_delay)
                retry_delay = min(retry_delay * 2, 60)

        logger.info("SSE connection loop exited")

    async def process_event(self, event_type: str, event_data: str):
        """Process received SSE event and publish to MQTT.

        Parses the JSON event payload, updates statistics, and routes the
        event to the appropriate MQTT topic based on event type.

        Args:
            event_type: SSE event type (HEARTBEAT, ALERT, etc.).
            event_data: JSON string containing event payload.
        """
        try:
            payload = json.loads(event_data)
            self.stats['events_received'] += 1
            self.stats['by_type'][event_type] = (
                self.stats['by_type'].get(event_type, 0) + 1
            )

            logger.info(f"Received {event_type} event")

            topic = self.get_topic_for_event_type(event_type)
            self.publish_to_mqtt(topic, payload)

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse event data as JSON: {e}")
            self.stats['errors'] += 1

        except Exception as e:
            logger.error(f"Error processing event: {e}")
            self.stats['errors'] += 1

    def print_stats(self):
        """Print comprehensive statistics about processed events.

        Logs total events received, published, errors, and breakdown by
        event type. Called on client shutdown to provide session summary.
        """
        logger.info("=== SSE Connector Statistics ===")
        logger.info(f"Events Received: {self.stats['events_received']}")
        logger.info(f"Events Published: {self.stats['events_published']}")
        logger.info(f"Errors: {self.stats['errors']}")
        logger.info("Events by Type:")
        for event_type, count in self.stats['by_type'].items():
            logger.info(f"  {event_type}: {count}")

    async def run(self):
        """Main event loop for the SSE connector client.

        Sets up MQTT connection, registers signal handlers for graceful
        shutdown, and starts the SSE connection loop. Ensures proper
        cleanup on exit.

        Signal handlers:
            SIGINT: Graceful shutdown on Ctrl+C
            SIGTERM: Graceful shutdown on process termination
        """
        self.setup_mqtt()

        def signal_handler(sig, frame):
            logger.info("Received shutdown signal")
            self.running = False

        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)

        try:
            await self.connect_to_sse()
        finally:
            self.print_stats()
            if self.mqtt_client:
                self.mqtt_client.loop_stop()
                self.mqtt_client.disconnect()
            logger.info("SSE Connector Test Client shutdown complete")


def main():
    """Main entry point for the SSE connector test client.

    Creates client instance and runs the async event loop. Handles
    keyboard interrupts and fatal errors gracefully.

    Exit codes:
        0: Normal shutdown
        1: Fatal error occurred
    """
    client = SSEConnectorTestClient()

    try:
        asyncio.run(client.run())
    except KeyboardInterrupt:
        logger.info("Keyboard interrupt received")
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
