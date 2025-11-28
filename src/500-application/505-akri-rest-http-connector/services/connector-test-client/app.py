#!/usr/bin/env python3
"""
Akri REST Connector Test Client
Simulates the behavior of an Akri REST connector by polling REST endpoints
and publishing data to MQTT topics
"""

import logging
import os
import threading
import time
from datetime import datetime, timezone
from typing import Any, Dict

import paho.mqtt.client as mqtt
import requests
import schedule
from requests.auth import HTTPBasicAuth

# Configure logging
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class RestConnectorClient:
    def __init__(self):
        # MQTT Configuration
        self.mqtt_host = os.environ.get(
            'AIO_BROKER_HOSTNAME', 'mosquitto-broker')
        self.mqtt_port = int(os.environ.get('AIO_BROKER_TCP_PORT', 1883))
        self.mqtt_client_id = os.environ.get(
            'AIO_MQTT_CLIENT_ID', 'akri-rest-connector-test')
        self.mqtt_use_tls = os.environ.get(
            'AIO_MQTT_USE_TLS', 'false').lower() == 'true'

        # REST Endpoints Configuration
        self.weather_endpoint = os.environ.get(
            'WEATHER_ENDPOINT', 'http://weather-station:8080/api/weather')
        self.sensor_fields_endpoint = os.environ.get(
            'SENSOR_FIELDS_ENDPOINT', 'http://sensor-simulator:8081/sensor/array/field')
        self.sensor_field_ids = [
            field_id.strip()
            for field_id in os.environ.get(
                'SENSOR_FIELD_IDS',
                'temp-celsius-01,humidity-pct-01,pressure-kpa-01,status-indicator-01,alarm-light-01'
            ).split(',')
            if field_id.strip()
        ]
        self.field_config_path = os.environ.get(
            'FIELD_CONFIG_PATH', '/app/resources/field_sources.json')
        self.auth_endpoint = os.environ.get(
            'AUTH_ENDPOINT', 'http://authenticated-device:8082/api/device/status')
        self.auth_username = os.environ.get('AUTH_USERNAME', 'device_user')
        self.auth_password = os.environ.get('AUTH_PASSWORD', 'device_pass_123')

        # MQTT Topics
        self.weather_topic = os.environ.get(
            'WEATHER_TOPIC', 'akri/weather-station-001/data')
        self.sensor_topic = os.environ.get(
            'SENSOR_TOPIC', 'akri/generic-sensor-001/data')
        self.auth_device_topic = os.environ.get(
            'AUTH_DEVICE_TOPIC', 'akri/auth-device-001/status')
        self.error_topic = os.environ.get('ERROR_TOPIC', 'akri/errors')

        # Polling Configuration
        self.polling_interval = int(
            os.environ.get('POLLING_INTERVAL_SECONDS', 30))
        self.retry_attempts = int(os.environ.get('RETRY_ATTEMPTS', 3))
        self.retry_delay = int(os.environ.get('RETRY_DELAY_SECONDS', 5))

        # Initialize MQTT client
        self.mqtt_client = None
        self.mqtt_connected = False

    def setup_mqtt(self):
        """Initialize and connect to MQTT broker"""
        try:
            self.mqtt_client = mqtt.Client(client_id=self.mqtt_client_id)
            self.mqtt_client.on_connect = self.on_mqtt_connect
            self.mqtt_client.on_disconnect = self.on_mqtt_disconnect
            self.mqtt_client.on_publish = self.on_mqtt_publish

            if self.mqtt_use_tls:
                self.mqtt_client.tls_set()

            logger.info(
                f"Connecting to MQTT broker at {self.mqtt_host}:{self.mqtt_port}")
            self.mqtt_client.connect(self.mqtt_host, self.mqtt_port, 60)
            self.mqtt_client.loop_start()

            # Wait for connection
            for _ in range(30):  # Wait up to 30 seconds
                if self.mqtt_connected:
                    break
                time.sleep(1)

            if not self.mqtt_connected:
                logger.error("Failed to connect to MQTT broker within timeout")
                return False

            return True
        except Exception as e:
            logger.error(f"Failed to setup MQTT: {e}")
            return False

    def on_mqtt_connect(self, client, userdata, flags, rc):
        """Callback for MQTT connection"""
        if rc == 0:
            self.mqtt_connected = True
            logger.info("Connected to MQTT broker successfully")
        else:
            logger.error(f"Failed to connect to MQTT broker: {rc}")

    def on_mqtt_disconnect(self, client, userdata, rc):
        """Callback for MQTT disconnection"""
        self.mqtt_connected = False
        logger.warning(f"Disconnected from MQTT broker: {rc}")

    def on_mqtt_publish(self, client, userdata, mid):
        """Callback for MQTT publish"""
        logger.debug(f"Message published with ID: {mid}")

    def fetch_with_retry(self, url, auth=None, endpoint_name="unknown"):
        """Fetch data from REST endpoint with retry logic"""
        for attempt in range(self.retry_attempts):
            try:
                logger.debug(
                    f"Fetching data from {endpoint_name} (attempt {attempt + 1}/{self.retry_attempts})")

                response = requests.get(url, auth=auth, timeout=10)
                response.raise_for_status()

                data = response.json()
                logger.info(
                    f"Successfully retrieved data from {endpoint_name}")
                return data

            except requests.exceptions.RequestException as e:
                logger.warning(
                    f"Attempt {attempt + 1} failed for {endpoint_name}: {e}")
                if attempt < self.retry_attempts - 1:
                    time.sleep(self.retry_delay)
                else:
                    logger.error(f"All attempts failed for {endpoint_name}")
                    return None

        return None

    def publish_to_mqtt(self, topic, data):
        """Publish data to MQTT topic"""
        if not self.mqtt_connected:
            logger.error("MQTT not connected, cannot publish data")
            return False

        try:
            import json
            payload = json.dumps(data, indent=2)
            result = self.mqtt_client.publish(topic, payload, qos=1)

            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                logger.info(f"Published data to topic: {topic}")
                return True
            else:
                logger.error(
                    f"Failed to publish to topic {topic}: {result.rc}")
                return False

        except Exception as e:
            logger.error(f"Error publishing to MQTT: {e}")
            return False

    def publish_error(self, endpoint_name, error_message):
        """Publish error information to error topic"""
        error_data = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "connector": "akri-rest-connector-test",
            "endpoint": endpoint_name,
            "error": str(error_message),
            "retry_attempts": self.retry_attempts
        }

        self.publish_to_mqtt(self.error_topic, error_data)

    def _build_fields_url(self) -> str:
        """Construct the sensor fields endpoint URL with requested field IDs."""
        if not self.sensor_field_ids:
            return self.sensor_fields_endpoint

        # requests handles query construction and encoding
        request_obj = requests.Request(
            method='GET',
            url=self.sensor_fields_endpoint,
            params=[('field_id', field_id)
                    for field_id in self.sensor_field_ids]
        ).prepare()
        return request_obj.url

    def _normalize_sensor_payload(self, payload: Any) -> Dict[str, Any] | None:
        """Normalize sensor payloads into a consistent structure."""
        if isinstance(payload, list):
            return {
                'fields': payload,
                'count': len(payload),
                'source': 'list',
                'original_payload': payload,
            }

        if not isinstance(payload, dict):
            return None

        if isinstance(payload.get('fields'), list):
            return {
                'fields': payload.get('fields', []),
                'count': payload.get('count', len(payload.get('fields', []))),
                'source': payload.get('source', 'fields-array'),
                'original_payload': payload,
            }

        required_single_field_keys = {'field_id', 'value', 'data_type'}
        if required_single_field_keys.issubset(payload.keys()):
            return {
                'fields': [payload],
                'count': 1,
                'source': 'single-field',
                'original_payload': payload,
            }

        return None

    def poll_weather_station(self):
        """Poll weather station endpoint"""
        logger.info("Polling weather station...")
        data = self.fetch_with_retry(
            self.weather_endpoint, endpoint_name="weather-station")

        if data:
            # Add connector metadata
            data["connector_metadata"] = {
                "connector_type": "akri-rest-connector",
                "polling_interval": self.polling_interval,
                "collection_time": datetime.now(timezone.utc).isoformat()
            }
            self.publish_to_mqtt(self.weather_topic, data)
        else:
            self.publish_error("weather-station",
                               "Failed to retrieve weather data")

    def poll_sensor_device(self):
        """Poll sensor device using field-based endpoint."""
        logger.info("Polling sensor device...")

        endpoint_url = self._build_fields_url()
        data = self.fetch_with_retry(
            endpoint_url,
            endpoint_name="sensor-device-fields"
        )

        if data is None:
            self.publish_error(
                "sensor-device", "Failed to retrieve sensor data")
            return

        normalized = self._normalize_sensor_payload(data)
        if not normalized:
            self.publish_error(
                "sensor-device", "Received unexpected sensor payload format")
            return

        normalized.setdefault('connector_metadata', {})
        normalized['connector_metadata'].update({
            "connector_type": "akri-rest-connector",
            "polling_interval": self.polling_interval,
            "collection_time": datetime.now(timezone.utc).isoformat(),
            "source_mode": normalized.get('source', 'fields-array'),
            "endpoint_used": endpoint_url,
            "field_ids": self.sensor_field_ids,
            "field_count": normalized.get('count', 0),
        })

        self.publish_to_mqtt(self.sensor_topic, normalized)

    def poll_authenticated_device(self):
        """Poll authenticated device endpoint"""
        logger.info("Polling authenticated device...")
        auth = HTTPBasicAuth(self.auth_username, self.auth_password)
        data = self.fetch_with_retry(
            self.auth_endpoint, auth=auth, endpoint_name="authenticated-device")

        if data:
            # Add connector metadata
            data["connector_metadata"] = {
                "connector_type": "akri-rest-connector",
                "authentication": "basic_http",
                "polling_interval": self.polling_interval,
                "collection_time": datetime.now(timezone.utc).isoformat()
            }
            self.publish_to_mqtt(self.auth_device_topic, data)
        else:
            self.publish_error("authenticated-device",
                               "Failed to retrieve authenticated device data")

    def schedule_polling(self):
        """Schedule periodic polling of all endpoints"""
        logger.info(
            f"Scheduling polling every {self.polling_interval} seconds")

        schedule.every(self.polling_interval).seconds.do(
            self.poll_weather_station)
        schedule.every(self.polling_interval).seconds.do(
            self.poll_sensor_device)
        schedule.every(self.polling_interval).seconds.do(
            self.poll_authenticated_device)

        # Run scheduler in background thread
        def run_scheduler():
            while True:
                schedule.run_pending()
                time.sleep(1)

        scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
        scheduler_thread.start()

        # Run initial polls immediately
        logger.info("Performing initial data collection...")
        self.poll_weather_station()
        self.poll_sensor_device()
        self.poll_authenticated_device()

    def run(self):
        """Main execution loop"""
        logger.info("Starting Akri REST Connector Test Client...")
        logger.info("Configuration:")
        logger.info(f"  MQTT Broker: {self.mqtt_host}:{self.mqtt_port}")
        logger.info(f"  TLS Enabled: {self.mqtt_use_tls}")
        logger.info(f"  Polling Interval: {self.polling_interval}s")
        logger.info(f"  Retry Attempts: {self.retry_attempts}")
        logger.info(f"  Sensor Fields Endpoint: {self.sensor_fields_endpoint}")
        logger.info(f"  Sensor Field IDs: {self.sensor_field_ids}")
        logger.info(f"  Field Config Path: {self.field_config_path}")

        # Setup MQTT connection
        if not self.setup_mqtt():
            logger.error("Failed to setup MQTT connection, exiting...")
            return

        # Wait a bit for other services to be ready
        logger.info("Waiting for REST endpoints to be ready...")
        time.sleep(10)

        # Start polling
        self.schedule_polling()

        # Keep running
        logger.info("Connector test client is running. Press Ctrl+C to stop.")
        try:
            while True:
                time.sleep(60)  # Wake up every minute to check status
                if not self.mqtt_connected:
                    logger.warning(
                        "MQTT connection lost, attempting to reconnect...")
                    self.setup_mqtt()
        except KeyboardInterrupt:
            logger.info("Shutting down connector test client...")
            if self.mqtt_client:
                self.mqtt_client.loop_stop()
                self.mqtt_client.disconnect()


if __name__ == '__main__':
    client = RestConnectorClient()
    client.run()
