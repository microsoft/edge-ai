#!/usr/bin/env python3
"""Analytics Camera Event Simulator.

This module provides event generation for testing and development of SSE connectors.
The simulator generates realistic analytics camera events including heartbeats, alerts,
and analytics state changes. This is separated from the SSE server infrastructure to
allow easy replacement with real event sources in production deployments.
"""

import random
from datetime import datetime
from typing import AsyncGenerator, Dict, Any
import asyncio


class AnalyticsEventSimulator:
    """Simulates analytics camera events for development and testing.

    This class generates realistic SSE events that mimic an analytics camera's
    behavior, including periodic heartbeats, leak detection alerts with varying
    detail levels, and analytics enable/disable state changes.

    Attributes:
        device_id: Unique identifier for the simulated camera device.
        heartbeat_interval: Seconds between heartbeat events.
        alert_probability: Probability (0.0-1.0) of generating an alert per check.
        analytics_enabled: Current state of analytics functionality.
        event_id_counter: Monotonically increasing event identifier.
    """

    def __init__(
        self,
        device_id: str = "analytics-camera-001",
        heartbeat_interval: int = 5,
        alert_probability: float = 0.1
    ):
        """Initialize the event simulator.

        Args:
            device_id: Unique identifier for the camera device.
            heartbeat_interval: Seconds between heartbeat events (default: 5).
            alert_probability: Probability of alert generation per check (default: 0.1).
        """
        self.device_id = device_id
        self.heartbeat_interval = heartbeat_interval
        self.alert_probability = alert_probability
        self.analytics_enabled = True
        self.event_id_counter = 1000

    def generate_heartbeat_event(self, timestamp: int) -> Dict[str, Any]:
        """Generate a heartbeat event.

        Args:
            timestamp: Unix timestamp in milliseconds.

        Returns:
            Dictionary containing heartbeat event data.
        """
        return {
            'type': 'HEARTBEAT',
            'timestamp': timestamp
        }

    def generate_analytics_enabled_event(self, timestamp: int) -> Dict[str, Any]:
        """Generate an analytics enabled event.

        Args:
            timestamp: Unix timestamp in milliseconds.

        Returns:
            Dictionary containing analytics enabled event data.
        """
        return {
            'type': 'ANALYTICS_ENABLED',
            'timestamp': timestamp,
            'analytics_type': 'leak detection'
        }

    def generate_analytics_disabled_event(self, timestamp: int) -> Dict[str, Any]:
        """Generate an analytics disabled event.

        Args:
            timestamp: Unix timestamp in milliseconds.

        Returns:
            Dictionary containing analytics disabled event data.
        """
        return {
            'type': 'ANALYTICS_DISABLED',
            'timestamp': timestamp,
            'analytics_type': 'leak detection'
        }

    def generate_basic_alert_event(self, timestamp: int) -> Dict[str, Any]:
        """Generate a basic leak detection alert.

        Args:
            timestamp: Unix timestamp in milliseconds.

        Returns:
            Dictionary containing basic alert event data.
        """
        self.event_id_counter += 1
        return {
            'type': 'ALERT',
            'timestamp': timestamp,
            'message': 'leak',
            'event_id': self.event_id_counter
        }

    def generate_detailed_alert_event(self, timestamp: int) -> Dict[str, Any]:
        """Generate a detailed leak detection alert with environmental data.

        This event includes comprehensive leak information including location,
        flow rate, environmental conditions, and camera metadata.

        Args:
            timestamp: Unix timestamp in milliseconds.

        Returns:
            Dictionary containing detailed alert event data with all sensor readings.
        """
        self.event_id_counter += 1
        return {
            'type': 'ALERT_DLQC',
            'timestamp': timestamp,
            'message': 'leak',
            'event_id': self.event_id_counter,
            'camera_id': random.randint(1, 5),
            'leak_location': {
                'longitude': random.uniform(-180, 180),
                'latitude': random.uniform(-90, 90)
            },
            'camera_location': {
                'longitude': random.uniform(-180, 180),
                'latitude': random.uniform(-90, 90)
            },
            'flow_rate': random.uniform(0.1, 2.0),
            'unit': 'g/s',
            'mass': random.uniform(1.0, 10.0),
            'mass_unit': 'kg',
            'confidence_level': random.randint(20, 95),
            'camera_orientation': random.randint(0, 360),
            'depression_angle': random.randint(30, 90),
            'wind_speed': random.uniform(0, 50),
            'wind_speed_unit': 'm/h',
            'wind_direction': random.randint(0, 360),
            'temperature': random.uniform(-10, 45),
            'temperature_unit': 'F',
            'humidity': random.randint(0, 100)
        }

    async def generate_events(self) -> AsyncGenerator[Dict[str, Any], None]:
        """Generate continuous stream of simulated analytics camera events.

        This generator produces events based on configured probabilities and intervals:
        - Heartbeat events at regular intervals
        - Random analytics enable/disable state changes (5% probability)
        - Leak alerts with configurable probability (70% detailed, 30% basic)

        Yields:
            Event dictionaries with type-specific data structures.

        Note:
            This is the primary integration point. Replace this method with
            real event source integration in production deployments.
        """
        last_heartbeat = datetime.now()

        while True:
            now = datetime.now()
            timestamp = int(now.timestamp() * 1000)

            # Generate heartbeat at regular intervals
            if (now - last_heartbeat).seconds >= self.heartbeat_interval:
                yield self.generate_heartbeat_event(timestamp)
                last_heartbeat = now

            # Randomly enable analytics if currently disabled
            if random.random() < 0.05:
                if not self.analytics_enabled:
                    yield self.generate_analytics_enabled_event(timestamp)
                    self.analytics_enabled = True

            # Generate alerts when analytics is enabled
            if self.analytics_enabled and random.random() < self.alert_probability:
                # 70% chance of detailed alert, 30% basic alert
                if random.random() < 0.7:
                    yield self.generate_detailed_alert_event(timestamp)
                else:
                    yield self.generate_basic_alert_event(timestamp)

            # Randomly disable analytics if currently enabled
            if random.random() < 0.02:
                if self.analytics_enabled:
                    yield self.generate_analytics_disabled_event(timestamp)
                    self.analytics_enabled = False

            await asyncio.sleep(1)
