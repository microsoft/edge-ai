"""
ONVIF Connector Client

Discovers ONVIF devices, retrieves capabilities and media profiles,
subscribes to events, and publishes to MQTT broker.

Features:
- ONVIF device discovery and capability detection
- Media profile discovery (Profile S and T)
- PTZ control command handling
- Event subscription (motion, tampering)
- MQTT publishing with topic routing
- Auto-reconnection with exponential backoff
"""

import asyncio
import logging
import os
import xml.etree.ElementTree as ET
from datetime import datetime

import aiohttp
import paho.mqtt.client as mqtt

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

ONVIF_NAMESPACES = {
    'soap': 'http://www.w3.org/2003/05/soap-envelope',
    'tds': 'http://www.onvif.org/ver10/device/wsdl',
    'trt': 'http://www.onvif.org/ver10/media/wsdl',
    'tptz': 'http://www.onvif.org/ver20/ptz/wsdl',
    'tev': 'http://www.onvif.org/ver10/events/wsdl',
    'timg': 'http://www.onvif.org/ver20/imaging/wsdl',
    'tt': 'http://www.onvif.org/ver10/schema',
    'wsnt': 'http://docs.oasis-open.org/wsn/b-2'
}

for prefix, uri in ONVIF_NAMESPACES.items():
    ET.register_namespace(prefix, uri)


class ONVIFConnectorClient:
    """ONVIF connector client for device discovery and event handling"""

    def __init__(self):
        self.onvif_host = os.getenv('ONVIF_HOST', 'onvif-camera-simulator')
        self.onvif_port = int(os.getenv('ONVIF_PORT', '8080'))
        self.onvif_endpoint = f'http://{self.onvif_host}:{self.onvif_port}'

        self.mqtt_broker = os.getenv('MQTT_BROKER', 'mosquitto-broker')
        self.mqtt_port = int(os.getenv('MQTT_PORT', '1883'))
        self.mqtt_client_id = os.getenv('MQTT_CLIENT_ID', 'onvif-connector-client')
        self.mqtt_topic_prefix = os.getenv('MQTT_TOPIC_PREFIX', 'onvif-camera')

        self.reconnect_delay = 1
        self.max_reconnect_delay = 60
        self.event_poll_interval = int(os.getenv('EVENT_POLL_INTERVAL', '5'))

        # Device information
        self.device_info = {}
        self.capabilities = {}
        self.media_profiles = []

        # Statistics
        self.stats = {
            'events_received': 0,
            'events_published': 0,
            'ptz_commands': 0,
            'connection_attempts': 0,
            'last_event_time': None
        }

        # MQTT client setup
        self.mqtt_client = mqtt.Client(
            client_id=self.mqtt_client_id,
            callback_api_version=mqtt.CallbackAPIVersion.VERSION1,
            protocol=mqtt.MQTTv311
        )
        self.mqtt_client.on_connect = self._on_mqtt_connect
        self.mqtt_client.on_disconnect = self._on_mqtt_disconnect
        self.mqtt_client.on_message = self._on_mqtt_message

        logger.info("ONVIF Connector Client initialized")
        logger.info(f"ONVIF Endpoint: {self.onvif_endpoint}")
        logger.info(f"MQTT Broker: {self.mqtt_broker}:{self.mqtt_port}")

    def _on_mqtt_connect(self, client, userdata, flags, rc):
        """MQTT connection callback.

        Args:
            client: MQTT client instance
            userdata: User data passed to callback
            flags: Connection flags
            rc: Connection result code (0 = success)
        """
        if rc == 0:
            logger.info("Connected to MQTT broker successfully")
            # Subscribe to PTZ command topics
            ptz_topic = f"{self.mqtt_topic_prefix}/ptz/command/#"
            client.subscribe(ptz_topic)
            logger.info(f"Subscribed to PTZ commands: {ptz_topic}")
        else:
            logger.error(f"Failed to connect to MQTT broker: {rc}")

    def _on_mqtt_disconnect(self, client, userdata, rc):
        """MQTT disconnection callback.

        Args:
            client: MQTT client instance
            userdata: User data passed to callback
            rc: Disconnection result code (0 = clean disconnect)
        """
        if rc != 0:
            logger.warning(f"Unexpected MQTT disconnection: {rc}")

    def _on_mqtt_message(self, client, userdata, msg):
        """Handle incoming MQTT messages (PTZ commands).

        Args:
            client: MQTT client instance
            userdata: User data passed to callback
            msg: MQTT message containing topic and payload
        """
        try:
            topic = msg.topic
            payload = msg.payload.decode('utf-8')

            logger.info(f"Received MQTT message on {topic}: {payload}")

            # Handle PTZ commands
            if '/ptz/command/' in topic:
                asyncio.create_task(self._handle_ptz_command(topic, payload))
                self.stats['ptz_commands'] += 1

        except Exception as e:
            logger.error(f"Error handling MQTT message: {e}")

    async def _handle_ptz_command(self, topic: str, payload: str):
        """Execute PTZ command on ONVIF device.

        Args:
            topic: MQTT topic containing command type
            payload: Command payload (JSON string with direction/speed)
        """
        try:
            # Parse command from topic (e.g., onvif-camera/ptz/command/pan)
            command_type = topic.split('/')[-1]

            # Create SOAP request for PTZ command
            soap_body = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
               xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl"
               xmlns:tt="http://www.onvif.org/ver10/schema">
    <soap:Body>
        <tptz:RelativeMove>
            <tptz:ProfileToken>profile_s_h264</tptz:ProfileToken>
            <tptz:Translation>
                <tt:PanTilt x="{payload}" y="0.0"/>
            </tptz:Translation>
        </tptz:RelativeMove>
    </soap:Body>
</soap:Envelope>'''

            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f'{self.onvif_endpoint}/onvif/ptz_service',
                    data=soap_body,
                    headers={'Content-Type': 'application/soap+xml'}
                ) as response:
                    if response.status == 200:
                        logger.info(f"PTZ command executed: {command_type}")
                    else:
                        logger.error(f"PTZ command failed: {response.status}")

        except Exception as e:
            logger.error(f"Error executing PTZ command: {e}")

    async def discover_device_info(self) -> bool:
        """Discover ONVIF device information.

        Queries the ONVIF device for manufacturer, model, firmware version,
        and serial number using GetDeviceInformation SOAP request.

        Returns:
            bool: True if device information retrieved successfully, False otherwise
        """
        try:
            soap_body = '''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
               xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
    <soap:Body>
        <tds:GetDeviceInformation/>
    </soap:Body>
</soap:Envelope>'''

            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f'{self.onvif_endpoint}/onvif/device_service',
                    data=soap_body,
                    headers={'Content-Type': 'application/soap+xml'}
                ) as response:
                    if response.status == 200:
                        text = await response.text()
                        root = ET.fromstring(text)

                        # Extract device information
                        for elem in root.iter():
                            if 'Manufacturer' in elem.tag:
                                self.device_info['manufacturer'] = elem.text
                            elif 'Model' in elem.tag:
                                self.device_info['model'] = elem.text
                            elif 'FirmwareVersion' in elem.tag:
                                self.device_info['firmware'] = elem.text
                            elif 'SerialNumber' in elem.tag:
                                self.device_info['serial'] = elem.text

                        logger.info(f"Device discovered: {self.device_info}")
                        return True
                    else:
                        logger.error(f"Failed to get device info: {response.status}")
                        return False

        except Exception as e:
            logger.error(f"Error discovering device: {e}")
            return False

    async def discover_capabilities(self) -> bool:
        """Discover ONVIF device capabilities.

        Queries the ONVIF device for supported services including media,
        PTZ, events, and imaging capabilities.

        Returns:
            bool: True if capabilities retrieved successfully, False otherwise
        """
        try:
            soap_body = '''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
               xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
    <soap:Body>
        <tds:GetCapabilities/>
    </soap:Body>
</soap:Envelope>'''

            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f'{self.onvif_endpoint}/onvif/device_service',
                    data=soap_body,
                    headers={'Content-Type': 'application/soap+xml'}
                ) as response:
                    if response.status == 200:
                        text = await response.text()
                        root = ET.fromstring(text)

                        # Extract capabilities
                        for elem in root.iter():
                            if 'Media' in elem.tag:
                                self.capabilities['media'] = True
                            elif 'PTZ' in elem.tag:
                                self.capabilities['ptz'] = True
                            elif 'Events' in elem.tag:
                                self.capabilities['events'] = True
                            elif 'Imaging' in elem.tag:
                                self.capabilities['imaging'] = True

                        logger.info(f"Capabilities discovered: {self.capabilities}")
                        return True
                    else:
                        logger.error(f"Failed to get capabilities: {response.status}")
                        return False

        except Exception as e:
            logger.error(f"Error discovering capabilities: {e}")
            return False

    async def discover_media_profiles(self) -> bool:
        """Discover ONVIF media profiles.

        Retrieves available media profiles from the ONVIF device, including
        Profile S (H.264, JPEG) and Profile T (H.265) configurations.

        Returns:
            bool: True if media profiles retrieved successfully, False otherwise
        """
        try:
            soap_body = '''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
               xmlns:trt="http://www.onvif.org/ver10/media/wsdl">
    <soap:Body>
        <trt:GetProfiles/>
    </soap:Body>
</soap:Envelope>'''

            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f'{self.onvif_endpoint}/onvif/media_service',
                    data=soap_body,
                    headers={'Content-Type': 'application/soap+xml'}
                ) as response:
                    if response.status == 200:
                        text = await response.text()
                        root = ET.fromstring(text)

                        # Extract media profiles
                        for profile in root.findall('.//trt:Profiles', ONVIF_NAMESPACES):
                            profile_data = {
                                'token': profile.get('token'),
                                'name': profile.find('.//tt:Name', ONVIF_NAMESPACES).text if profile.find('.//tt:Name', ONVIF_NAMESPACES) is not None else 'Unknown'
                            }
                            self.media_profiles.append(profile_data)

                        logger.info(f"Media profiles discovered: {len(self.media_profiles)} profiles")
                        for profile in self.media_profiles:
                            logger.info(f"  - {profile['name']} (token: {profile['token']})")
                        return True
                    else:
                        logger.error(f"Failed to get media profiles: {response.status}")
                        return False

        except Exception as e:
            logger.error(f"Error discovering media profiles: {e}")
            return False

    async def subscribe_to_events(self):
        """Subscribe to ONVIF camera events.

        Uses PullMessages pattern to retrieve events from the ONVIF device,
        including motion detection and tampering alerts.
        """
        try:
            soap_body = '''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
               xmlns:tev="http://www.onvif.org/ver10/events/wsdl">
    <soap:Body>
        <tev:PullMessages>
            <tev:Timeout>PT10S</tev:Timeout>
            <tev:MessageLimit>10</tev:MessageLimit>
        </tev:PullMessages>
    </soap:Body>
</soap:Envelope>'''

            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f'{self.onvif_endpoint}/onvif/event_service',
                    data=soap_body,
                    headers={'Content-Type': 'application/soap+xml'}
                ) as response:
                    if response.status == 200:
                        text = await response.text()
                        await self._process_events(text)
                    else:
                        logger.warning(f"Failed to pull events: {response.status}")

        except Exception as e:
            logger.error(f"Error subscribing to events: {e}")

    async def _process_events(self, xml_text: str):
        """Process ONVIF events and publish to MQTT.

        Parses ONVIF event XML, extracts motion and tampering notifications,
        and publishes them to appropriate MQTT topics.

        Args:
            xml_text: SOAP XML response containing event notifications
        """
        try:
            root = ET.fromstring(xml_text)

            for notification in root.findall('.//wsnt:NotificationMessage', ONVIF_NAMESPACES):
                # Extract topic
                topic_elem = notification.find('.//wsnt:Topic', ONVIF_NAMESPACES)
                if topic_elem is not None:
                    event_topic = topic_elem.text.strip()

                    # Extract message data
                    message_elem = notification.find('.//tt:Message', ONVIF_NAMESPACES)
                    if message_elem is not None:
                        event_time = message_elem.get('UtcTime', datetime.utcnow().isoformat())

                        # Determine event type
                        if 'Motion' in event_topic:
                            event_type = 'motion'
                            is_motion = message_elem.find('.//tt:SimpleItem[@Name="IsMotion"]', ONVIF_NAMESPACES)
                            if is_motion is not None and is_motion.get('Value') == 'true':
                                await self._publish_event(event_type, {
                                    'type': 'motion_detected',
                                    'timestamp': event_time,
                                    'device_id': self.device_info.get('serial', 'unknown')
                                })

                        elif 'Tamper' in event_topic:
                            event_type = 'tampering'
                            is_tamper = message_elem.find('.//tt:SimpleItem[@Name="IsTamper"]', ONVIF_NAMESPACES)
                            if is_tamper is not None and is_tamper.get('Value') == 'true':
                                await self._publish_event(event_type, {
                                    'type': 'tampering_detected',
                                    'timestamp': event_time,
                                    'device_id': self.device_info.get('serial', 'unknown')
                                })

                        self.stats['events_received'] += 1
                        self.stats['last_event_time'] = datetime.now().isoformat()

        except Exception as e:
            logger.error(f"Error processing events: {e}")

    async def _publish_event(self, event_type: str, event_data: dict):
        """Publish event to MQTT broker.

        Args:
            event_type: Type of event (e.g., 'motion', 'tampering')
            event_data: Dictionary containing event details and timestamp
        """
        try:
            topic = f"{self.mqtt_topic_prefix}/events/{event_type}"
            payload = str(event_data)

            self.mqtt_client.publish(topic, payload, qos=1)
            self.stats['events_published'] += 1

            logger.info(f"Published {event_type} event to {topic}")

        except Exception as e:
            logger.error(f"Error publishing event: {e}")

    async def connect_to_onvif(self):
        """Connect to ONVIF device and discover capabilities.

        Attempts to connect to the ONVIF device with exponential backoff retry.
        Performs device discovery, capability detection, and media profile enumeration.

        Returns:
            bool: True when successfully connected and discovered device information
        """
        while True:
            try:
                self.stats['connection_attempts'] += 1
                logger.info(f"Connecting to ONVIF device: {self.onvif_endpoint}")

                # Discover device information
                if await self.discover_device_info():
                    # Discover capabilities
                    if await self.discover_capabilities():
                        # Discover media profiles
                        if await self.discover_media_profiles():
                            logger.info("ONVIF device discovery completed successfully")
                            self.reconnect_delay = 1
                            return True

                logger.warning(f"ONVIF discovery failed, retrying in {self.reconnect_delay}s")
                await asyncio.sleep(self.reconnect_delay)
                self.reconnect_delay = min(self.reconnect_delay * 2, self.max_reconnect_delay)

            except Exception as e:
                logger.error(f"Error connecting to ONVIF device: {e}")
                await asyncio.sleep(self.reconnect_delay)
                self.reconnect_delay = min(self.reconnect_delay * 2, self.max_reconnect_delay)

    async def run(self):
        """Main run loop for ONVIF connector.

        Initializes MQTT connection, connects to ONVIF device, and starts
        the event subscription loop. Runs continuously until interrupted.
        """
        try:
            # Connect to MQTT broker
            logger.info(f"Connecting to MQTT broker at {self.mqtt_broker}:{self.mqtt_port}")
            self.mqtt_client.connect(self.mqtt_broker, self.mqtt_port, 60)
            self.mqtt_client.loop_start()

            # Connect to ONVIF device
            await self.connect_to_onvif()

            # Event subscription loop
            logger.info(f"Starting event subscription loop (interval: {self.event_poll_interval}s)")
            while True:
                await self.subscribe_to_events()
                await asyncio.sleep(self.event_poll_interval)

                # Log statistics periodically
                if self.stats['events_received'] % 10 == 0:
                    logger.info(f"Statistics: {self.stats}")

        except KeyboardInterrupt:
            logger.info("Shutting down ONVIF Connector Client")
        except Exception as e:
            logger.error(f"Fatal error in connector: {e}")
        finally:
            self.mqtt_client.loop_stop()
            self.mqtt_client.disconnect()


if __name__ == '__main__':
    client = ONVIFConnectorClient()
    asyncio.run(client.run())
