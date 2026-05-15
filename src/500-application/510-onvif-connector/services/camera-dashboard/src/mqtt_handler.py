"""MQTT integration for PTZ command publishing and camera event subscription.

Publishes PTZ commands to {topic_prefix}/ptz/command/{camera_id}/{action}
and subscribes to {topic_prefix}/events/# for incoming camera events.
"""
import json

import paho.mqtt.client as mqtt


class MQTTHandler:
    """MQTT client for publishing PTZ commands and receiving camera events."""

    def __init__(self, broker, port, topic_prefix, on_event_callback=None):
        self.topic_prefix = topic_prefix
        self.on_event_callback = on_event_callback
        self.client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
        self.client.on_connect = self._on_connect
        self.client.on_message = self._on_message
        self._broker = broker
        self._port = port

    def connect(self):
        """Connect to the MQTT broker and start the background network loop."""
        self.client.connect(self._broker, self._port)
        self.client.loop_start()

    def disconnect(self):
        """Stop the network loop and disconnect from the broker."""
        self.client.loop_stop()
        self.client.disconnect()

    def _on_connect(self, client, userdata, flags, rc, properties=None):
        client.subscribe(f"{self.topic_prefix}/events/#")

    def _on_message(self, client, userdata, msg):
        if self.on_event_callback:
            try:
                payload = json.loads(msg.payload.decode())
                self.on_event_callback(msg.topic, payload)
            except json.JSONDecodeError:
                pass

    def send_ptz_command(self, camera_id, action, payload):
        """Publish a JSON PTZ command to the camera-specific action topic."""
        topic = f"{self.topic_prefix}/ptz/command/{camera_id}/{action}"
        self.client.publish(topic, json.dumps(payload))

    def pan(self, camera_id, direction, speed=0.5):
        self.send_ptz_command(camera_id, "pan", {"direction": direction, "speed": speed})

    def tilt(self, camera_id, direction, speed=0.5):
        self.send_ptz_command(camera_id, "tilt", {"direction": direction, "speed": speed})

    def zoom(self, camera_id, direction, speed=0.3):
        self.send_ptz_command(camera_id, "zoom", {"direction": direction, "speed": speed})

    def home(self, camera_id):
        self.send_ptz_command(camera_id, "home", {})
