#!/usr/bin/env python3
"""Analytics Camera SSE Server.

This module provides an HTTP server that streams Server-Sent Events (SSE) for
analytics camera event integration with Azure IoT Operations. It serves as both
a development/testing tool and a reference implementation for SSE connectors.

The server exposes SSE endpoints that can be consumed by Akri SSE connectors,
publishing real-time events for leak detection, heartbeats, and analytics state changes.
"""

import asyncio
import json
import logging
import os
from typing import AsyncGenerator

from aiohttp import web
from events_simulator import AnalyticsEventSimulator

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class AnalyticsSSEServer:
    """HTTP server that streams analytics camera events via Server-Sent Events.

    This server provides a complete SSE implementation for testing and development
    of Akri SSE connectors. It uses a pluggable event simulator that can be replaced
    with real event sources for production deployments.

    Attributes:
        device_id: Unique identifier for the camera device.
        port: HTTP server port number.
        event_simulator: Event generation strategy (default: AnalyticsEventSimulator).
        app: aiohttp web application instance.

    Note:
        For production deployments, replace the AnalyticsEventSimulator with
        a real event source by subclassing and overriding generate_events().
    """

    def __init__(
        self,
        device_id: str = "analytics-camera-001",
        port: int = 8080,
        heartbeat_interval: int = 5,
        alert_probability: float = 0.1
    ):
        """Initialize the SSE server.

        Args:
            device_id: Unique identifier for the camera device.
            port: HTTP server port (default: 8080).
            heartbeat_interval: Seconds between heartbeat events (default: 5).
            alert_probability: Probability of alert generation per check (default: 0.1).
        """
        self.device_id = device_id
        self.port = port
        self.event_simulator = AnalyticsEventSimulator(
            device_id=device_id,
            heartbeat_interval=heartbeat_interval,
            alert_probability=alert_probability
        )
        self.app = web.Application()
        self.setup_routes()

    def setup_routes(self):
        """Configure HTTP route handlers.

        Routes:
            GET /camera-events: SSE endpoint for event streaming
            GET /health: Health check endpoint
            GET /: Server information endpoint
        """
        self.app.router.add_get('/camera-events', self.sse_handler)
        self.app.router.add_get('/health', self.health_handler)
        self.app.router.add_get('/', self.info_handler)

    async def health_handler(self, request: web.Request) -> web.Response:
        """Health check endpoint for monitoring and load balancers.

        Args:
            request: HTTP request object.

        Returns:
            JSON response with health status, device ID, and timestamp.
        """
        return web.json_response({
            'status': 'healthy',
            'device_id': self.device_id,
            'timestamp': self.event_simulator.generate_heartbeat_event(
                int(asyncio.get_event_loop().time() * 1000)
            )['timestamp']
        })

    async def info_handler(self, request: web.Request) -> web.Response:
        """Server information endpoint with capability discovery.

        Args:
            request: HTTP request object.

        Returns:
            JSON response with device information, endpoints, and event types.
        """
        return web.json_response({
            'device_id': self.device_id,
            'device_type': 'analytics-camera',
            'sse_endpoint': '/camera-events',
            'event_types': [
                'HEARTBEAT',
                'ANALYTICS_ENABLED',
                'ANALYTICS_DISABLED',
                'ALERT',
                'ALERT_DLQC'
            ],
            'heartbeat_interval_seconds': self.event_simulator.heartbeat_interval
        })

    async def generate_events(self) -> AsyncGenerator[dict, None]:
        """Generate analytics camera SSE events using the configured simulator.

        This method delegates to the event_simulator for event generation.
        For production deployments, replace the simulator with a real event source
        that yields events from actual camera hardware or analytics services.

        Yields:
            Event dictionaries with type-specific data structures.

        Note:
            To integrate real event sources, either:
            1. Create a new simulator class with the same interface
            2. Override this method in a subclass
            3. Modify AnalyticsEventSimulator.generate_events() directly
        """
        logger.info(f"Starting SSE event generation for device {self.device_id}")

        async for event in self.event_simulator.generate_events():
            yield event

    async def sse_handler(self, request: web.Request) -> web.StreamResponse:
        """Server-Sent Events endpoint handler.

        Establishes a persistent HTTP connection and streams events as they
        are generated. Implements the SSE protocol with proper headers and
        event formatting.

        Args:
            request: HTTP request object from the client.

        Returns:
            Streaming response with Server-Sent Events.

        Note:
            Clients should set Accept: text/event-stream header.
            Connection remains open until client disconnects or server error.
        """
        client_ip = request.remote
        logger.info(f"New SSE client connected from {client_ip}")

        response = web.StreamResponse()
        response.headers['Content-Type'] = 'text/event-stream'
        response.headers['Cache-Control'] = 'no-cache'
        response.headers['Connection'] = 'keep-alive'
        response.headers['Access-Control-Allow-Origin'] = '*'

        await response.prepare(request)

        try:
            async for event_data in self.generate_events():
                event_type = event_data.get('type', 'message')
                event_json = json.dumps(event_data)

                sse_data = f"event: {event_type}\ndata: {event_json}\n\n"

                await response.write(sse_data.encode('utf-8'))
                await asyncio.sleep(0.1)

        except asyncio.CancelledError:
            logger.info(f"SSE client {client_ip} disconnected")
        except Exception as e:
            logger.error(f"Error in SSE handler: {e}")
        finally:
            return response

    def run(self):
        """Start the HTTP server and begin serving SSE endpoints.

        Logs server configuration and runs the aiohttp web application.
        Blocks until the server is shut down.
        """
        logger.info(f"Starting Analytics Camera SSE Server on port {self.port}")
        logger.info(f"Device ID: {self.device_id}")
        logger.info(f"SSE Endpoint: http://0.0.0.0:{self.port}/camera-events")
        logger.info(f"Health Check: http://0.0.0.0:{self.port}/health")

        web.run_app(
            self.app,
            host='0.0.0.0',
            port=self.port,
            access_log=logger
        )


def main():
    """Main entry point for the SSE server application.

    Reads configuration from environment variables and starts the server.

    Environment Variables:
        DEVICE_ID: Camera device identifier (default: analytics-camera-001)
        PORT: HTTP server port (default: 8080)
        HEARTBEAT_INTERVAL: Seconds between heartbeats (default: 5)
        ALERT_PROBABILITY: Alert generation probability 0.0-1.0 (default: 0.1)
    """
    device_id = os.getenv('DEVICE_ID', 'analytics-camera-001')
    port = int(os.getenv('PORT', '8080'))
    heartbeat_interval = int(os.getenv('HEARTBEAT_INTERVAL', '5'))
    alert_probability = float(os.getenv('ALERT_PROBABILITY', '0.1'))

    server = AnalyticsSSEServer(
        device_id=device_id,
        port=port,
        heartbeat_interval=heartbeat_interval,
        alert_probability=alert_probability
    )

    server.run()


if __name__ == '__main__':
    main()
