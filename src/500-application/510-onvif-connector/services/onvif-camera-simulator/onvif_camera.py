"""
ONVIF Camera Simulator

Simulates an ONVIF-compliant camera supporting Profile S and Profile T.
Provides device discovery, media URIs, PTZ control, and event generation.

ONVIF Profiles:
- Profile S: Basic video streaming (JPEG, H.264)
- Profile T: Advanced video streaming with H.265

Capabilities:
- Device information and capabilities discovery
- Media profile URIs for video streaming
- PTZ (Pan-Tilt-Zoom) control
- Event generation (motion detection, tampering)
- Imaging control (brightness, contrast, focus)
"""

import asyncio
import logging
import os
import random
import time
import uuid
from datetime import datetime
from aiohttp import web
from lxml import etree

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
    'tt': 'http://www.onvif.org/ver10/schema'
}


class ONVIFCameraSimulator:
    """ONVIF-compliant camera simulator supporting Profile S and Profile T"""

    def __init__(self):
        self.device_id = os.getenv('ONVIF_DEVICE_ID', 'onvif-camera-001')
        self.host = os.getenv('ONVIF_HOST', '0.0.0.0')
        self.port = int(os.getenv('ONVIF_PORT', '8080'))
        self.manufacturer = 'Edge AI Simulator'
        self.model = 'ONVIF-PTZ-4K'
        self.firmware_version = '1.0.0'
        self.serial_number = str(uuid.uuid4())[:8].upper()

        # PTZ state
        self.ptz_position = {'pan': 0.0, 'tilt': 0.0, 'zoom': 1.0}
        self.ptz_limits = {
            'pan': {'min': -180.0, 'max': 180.0},
            'tilt': {'min': -90.0, 'max': 90.0},
            'zoom': {'min': 1.0, 'max': 10.0}
        }

        # Imaging settings
        self.imaging_settings = {
            'brightness': 50.0,
            'contrast': 50.0,
            'saturation': 50.0,
            'sharpness': 50.0
        }

        # Event generation
        self.motion_detected = False
        self.tampering_detected = False
        self.last_event_time = time.time()

        # Media profiles (ONVIF Profile S and T)
        self.media_profiles = {
            'profile_s_h264': {
                'token': 'profile_s_h264',
                'name': 'Profile S - H.264 Main Stream',
                'encoding': 'H264',
                'resolution': {'width': 1920, 'height': 1080},
                'framerate': 30,
                'bitrate': 4000,
                'uri': f'rtsp://{self.device_id}.local:554/stream1'
            },
            'profile_s_jpeg': {
                'token': 'profile_s_jpeg',
                'name': 'Profile S - JPEG Snapshots',
                'encoding': 'JPEG',
                'resolution': {'width': 1920, 'height': 1080},
                'framerate': 5,
                'bitrate': 2000,
                'uri': f'http://{self.device_id}.local:8080/snapshot'
            },
            'profile_t_h265': {
                'token': 'profile_t_h265',
                'name': 'Profile T - H.265 4K Stream',
                'encoding': 'H265',
                'resolution': {'width': 3840, 'height': 2160},
                'framerate': 30,
                'bitrate': 8000,
                'uri': f'rtsp://{self.device_id}.local:554/stream2'
            }
        }

        logger.info(f"ONVIF Camera Simulator initialized: {self.device_id}")
        logger.info(f"Manufacturer: {self.manufacturer}, Model: {self.model}")
        logger.info(f"Serial: {self.serial_number}, Firmware: {self.firmware_version}")

    async def handle_health(self, request: web.Request) -> web.Response:
        """Health check endpoint.

        Args:
            request: HTTP request object

        Returns:
            JSON response with device status and timestamp
        """
        return web.json_response({
            'status': 'healthy',
            'device_id': self.device_id,
            'timestamp': int(time.time() * 1000)
        })

    async def handle_onvif_service(self, request: web.Request) -> web.Response:
        """Handle ONVIF SOAP requests.

        Routes incoming SOAP requests to appropriate handlers based on
        the SOAP action in the request body.

        Args:
            request: HTTP request containing SOAP XML body

        Returns:
            SOAP XML response or fault message
        """
        try:
            body = await request.text()
            parser = etree.XMLParser(resolve_entities=False)
            root = etree.fromstring(body.encode('utf-8'), parser=parser)

            # Extract SOAP action from body
            body_elem = root.find('.//soap:Body', ONVIF_NAMESPACES)
            if body_elem is None:
                return self._create_soap_fault('No SOAP Body found')

            # Determine which service method was called
            for child in body_elem:
                tag = child.tag
                if 'GetDeviceInformation' in tag:
                    return self._handle_get_device_information()
                elif 'GetCapabilities' in tag:
                    return self._handle_get_capabilities()
                elif 'GetProfiles' in tag:
                    return self._handle_get_profiles()
                elif 'GetStreamUri' in tag:
                    return self._handle_get_stream_uri(child)
                elif 'AbsoluteMove' in tag or 'RelativeMove' in tag:
                    return self._handle_ptz_command(child)
                elif 'GetImagingSettings' in tag:
                    return self._handle_get_imaging_settings()
                elif 'SetImagingSettings' in tag:
                    return self._handle_set_imaging_settings(child)
                elif 'PullMessages' in tag or 'GetEventProperties' in tag:
                    return self._handle_event_request(child)

            return self._create_soap_fault('Unknown ONVIF method')

        except Exception as e:
            logger.error(f"Error handling ONVIF request: {e}")
            return self._create_soap_fault(str(e))

    def _handle_get_device_information(self) -> web.Response:
        """Return ONVIF device information.

        Generates SOAP response containing manufacturer, model, firmware version,
        serial number, and hardware ID.

        Returns:
            SOAP XML response with device information
        """
        response = etree.Element("{http://www.w3.org/2003/05/soap-envelope}Envelope")
        body = etree.SubElement(response, "{http://www.w3.org/2003/05/soap-envelope}Body")
        device_info_response = etree.SubElement(body, "{http://www.onvif.org/ver10/device/wsdl}GetDeviceInformationResponse")

        etree.SubElement(device_info_response, "{http://www.onvif.org/ver10/device/wsdl}Manufacturer").text = self.manufacturer
        etree.SubElement(device_info_response, "{http://www.onvif.org/ver10/device/wsdl}Model").text = self.model
        etree.SubElement(device_info_response, "{http://www.onvif.org/ver10/device/wsdl}FirmwareVersion").text = self.firmware_version
        etree.SubElement(device_info_response, "{http://www.onvif.org/ver10/device/wsdl}SerialNumber").text = self.serial_number
        etree.SubElement(device_info_response, "{http://www.onvif.org/ver10/device/wsdl}HardwareId").text = self.device_id

        response_text = etree.tostring(response, encoding='utf-8', xml_declaration=True).decode('utf-8')
        return web.Response(text=response_text, content_type='application/soap+xml')
        return web.Response(text=response, content_type='application/soap+xml')

    def _handle_get_capabilities(self) -> web.Response:
        """Return ONVIF device capabilities (Profile S and T support).

        Generates SOAP response listing supported ONVIF services including
        Media, PTZ, Events, and Imaging with their endpoint URLs.

        Returns:
            SOAP XML response with device capabilities
        """
        response = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
               xmlns:tds="http://www.onvif.org/ver10/device/wsdl"
               xmlns:tt="http://www.onvif.org/ver10/schema">
    <soap:Body>
        <tds:GetCapabilitiesResponse>
            <tds:Capabilities>
                <tt:Media>
                    <tt:XAddr>http://{self.host}:{self.port}/onvif/media_service</tt:XAddr>
                    <tt:StreamingCapabilities>
                        <tt:RTPMulticast>false</tt:RTPMulticast>
                        <tt:RTP_TCP>true</tt:RTP_TCP>
                        <tt:RTP_RTSP_TCP>true</tt:RTP_RTSP_TCP>
                    </tt:StreamingCapabilities>
                </tt:Media>
                <tt:PTZ>
                    <tt:XAddr>http://{self.host}:{self.port}/onvif/ptz_service</tt:XAddr>
                </tt:PTZ>
                <tt:Events>
                    <tt:XAddr>http://{self.host}:{self.port}/onvif/event_service</tt:XAddr>
                </tt:Events>
                <tt:Imaging>
                    <tt:XAddr>http://{self.host}:{self.port}/onvif/imaging_service</tt:XAddr>
                </tt:Imaging>
            </tds:Capabilities>
        </tds:GetCapabilitiesResponse>
    </soap:Body>
</soap:Envelope>'''
        return web.Response(text=response, content_type='application/soap+xml')

    def _handle_get_profiles(self) -> web.Response:
        """Return available media profiles (Profile S and T).

        Generates SOAP response containing all configured media profiles
        including H.264, JPEG, and H.265 encoding configurations.

        Returns:
            SOAP XML response with media profile list
        """
        profiles_xml = ''
        for token, profile in self.media_profiles.items():
            profiles_xml += f'''
            <trt:Profiles token="{profile['token']}" fixed="true">
                <tt:Name>{profile['name']}</tt:Name>
                <tt:VideoEncoderConfiguration>
                    <tt:Encoding>{profile['encoding']}</tt:Encoding>
                    <tt:Resolution>
                        <tt:Width>{profile['resolution']['width']}</tt:Width>
                        <tt:Height>{profile['resolution']['height']}</tt:Height>
                    </tt:Resolution>
                    <tt:RateControl>
                        <tt:FrameRateLimit>{profile['framerate']}</tt:FrameRateLimit>
                        <tt:BitrateLimit>{profile['bitrate']}</tt:BitrateLimit>
                    </tt:RateControl>
                </tt:VideoEncoderConfiguration>
            </trt:Profiles>'''

        response = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
               xmlns:trt="http://www.onvif.org/ver10/media/wsdl"
               xmlns:tt="http://www.onvif.org/ver10/schema">
    <soap:Body>
        <trt:GetProfilesResponse>
            {profiles_xml}
        </trt:GetProfilesResponse>
    </soap:Body>
</soap:Envelope>'''
        return web.Response(text=response, content_type='application/soap+xml')

    def _handle_get_stream_uri(self, element) -> web.Response:
        """Return streaming URI for requested profile.

        Extracts the requested profile token from SOAP request and returns
        the corresponding RTSP or HTTP streaming URI.

        Args:
            element: SOAP body element containing ProfileToken

        Returns:
            SOAP XML response with media stream URI
        """
        profile_token = element.find('.//tt:ProfileToken', ONVIF_NAMESPACES)
        token = profile_token.text if profile_token is not None else 'profile_s_h264'

        profile = self.media_profiles.get(token, self.media_profiles['profile_s_h264'])

        response = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
               xmlns:trt="http://www.onvif.org/ver10/media/wsdl"
               xmlns:tt="http://www.onvif.org/ver10/schema">
    <soap:Body>
        <trt:GetStreamUriResponse>
            <trt:MediaUri>
                <tt:Uri>{profile['uri']}</tt:Uri>
                <tt:InvalidAfterConnect>false</tt:InvalidAfterConnect>
                <tt:InvalidAfterReboot>false</tt:InvalidAfterReboot>
                <tt:Timeout>PT60S</tt:Timeout>
            </trt:MediaUri>
        </trt:GetStreamUriResponse>
    </soap:Body>
</soap:Envelope>'''
        return web.Response(text=response, content_type='application/soap+xml')

    def _handle_ptz_command(self, element) -> web.Response:
        """Handle PTZ control commands.

        Processes AbsoluteMove or RelativeMove SOAP requests to update
        simulated PTZ position (pan, tilt, zoom).

        Args:
            element: SOAP body element containing PTZ command and values

        Returns:
            SOAP XML response acknowledging PTZ command
        """
        # Extract PTZ values from SOAP body
        velocity = element.find('.//tt:Velocity', ONVIF_NAMESPACES)
        position = element.find('.//tt:Position', ONVIF_NAMESPACES)

        if velocity is not None:
            pan = velocity.find('.//tt:PanTilt', ONVIF_NAMESPACES)
            zoom = velocity.find('.//tt:Zoom', ONVIF_NAMESPACES)
            if pan is not None:
                self.ptz_position['pan'] = float(pan.get('x', 0.0))
                self.ptz_position['tilt'] = float(pan.get('y', 0.0))
            if zoom is not None:
                self.ptz_position['zoom'] = float(zoom.get('x', 1.0))

        if position is not None:
            pan = position.find('.//tt:PanTilt', ONVIF_NAMESPACES)
            zoom = position.find('.//tt:Zoom', ONVIF_NAMESPACES)
            if pan is not None:
                self.ptz_position['pan'] = float(pan.get('x', 0.0))
                self.ptz_position['tilt'] = float(pan.get('y', 0.0))
            if zoom is not None:
                self.ptz_position['zoom'] = float(zoom.get('x', 1.0))

        logger.info(f"PTZ command executed: {self.ptz_position}")

        response = '''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
               xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl">
    <soap:Body>
        <tptz:MoveResponse/>
    </soap:Body>
</soap:Envelope>'''
        return web.Response(text=response, content_type='application/soap+xml')

    def _handle_get_imaging_settings(self) -> web.Response:
        """Return current imaging settings.

        Generates SOAP response containing current brightness, contrast,
        saturation, and sharpness values.

        Returns:
            SOAP XML response with imaging settings
        """
        response = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
               xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl"
               xmlns:tt="http://www.onvif.org/ver10/schema">
    <soap:Body>
        <timg:GetImagingSettingsResponse>
            <timg:ImagingSettings>
                <tt:Brightness>{self.imaging_settings['brightness']}</tt:Brightness>
                <tt:Contrast>{self.imaging_settings['contrast']}</tt:Contrast>
                <tt:Saturation>{self.imaging_settings['saturation']}</tt:Saturation>
                <tt:Sharpness>{self.imaging_settings['sharpness']}</tt:Sharpness>
            </timg:ImagingSettings>
        </timg:GetImagingSettingsResponse>
    </soap:Body>
</soap:Envelope>'''
        return web.Response(text=response, content_type='application/soap+xml')

    def _handle_set_imaging_settings(self, element) -> web.Response:
        """Update imaging settings.

        Processes SetImagingSettings SOAP request to update brightness,
        contrast, saturation, and sharpness values.

        Args:
            element: SOAP body element containing new imaging settings

        Returns:
            SOAP XML response acknowledging settings update
        """
        settings = element.find('.//timg:ImagingSettings', ONVIF_NAMESPACES)
        if settings is not None:
            for key in self.imaging_settings:
                elem = settings.find(f'.//tt:{key.capitalize()}', ONVIF_NAMESPACES)
                if elem is not None:
                    self.imaging_settings[key] = float(elem.text)

        logger.info(f"Imaging settings updated: {self.imaging_settings}")

        response = '''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
               xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl">
    <soap:Body>
        <timg:SetImagingSettingsResponse/>
    </soap:Body>
</soap:Envelope>'''
        return web.Response(text=response, content_type='application/soap+xml')

    def _handle_event_request(self, element) -> web.Response:
        """Generate and return camera events (motion, tampering).

        Randomly generates motion and tampering events, returning them
        as ONVIF notifications in the PullMessages response.

        Args:
            element: SOAP body element containing event request

        Returns:
            SOAP XML response with event notifications
        """
        current_time = time.time()

        # Randomly trigger events
        if current_time - self.last_event_time > 10:
            self.motion_detected = random.choice([True, False])
            self.tampering_detected = random.choice([True, False, False, False])
            self.last_event_time = current_time

        events_xml = ''
        if self.motion_detected:
            events_xml += f'''
            <wsnt:NotificationMessage>
                <wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">
                    tns1:RuleEngine/CellMotionDetector/Motion
                </wsnt:Topic>
                <wsnt:Message>
                    <tt:Message UtcTime="{datetime.utcnow().isoformat()}">
                        <tt:Source>
                            <tt:SimpleItem Name="VideoSourceConfigurationToken" Value="profile_s_h264"/>
                        </tt:Source>
                        <tt:Data>
                            <tt:SimpleItem Name="IsMotion" Value="true"/>
                        </tt:Data>
                    </tt:Message>
                </wsnt:Message>
            </wsnt:NotificationMessage>'''

        if self.tampering_detected:
            events_xml += f'''
            <wsnt:NotificationMessage>
                <wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">
                    tns1:RuleEngine/TamperDetector/Tamper
                </wsnt:Topic>
                <wsnt:Message>
                    <tt:Message UtcTime="{datetime.utcnow().isoformat()}">
                        <tt:Source>
                            <tt:SimpleItem Name="VideoSourceConfigurationToken" Value="profile_s_h264"/>
                        </tt:Source>
                        <tt:Data>
                            <tt:SimpleItem Name="IsTamper" Value="true"/>
                        </tt:Data>
                    </tt:Message>
                </wsnt:Message>
            </wsnt:NotificationMessage>'''

        response = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
               xmlns:tev="http://www.onvif.org/ver10/events/wsdl"
               xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2"
               xmlns:tt="http://www.onvif.org/ver10/schema">
    <soap:Body>
        <tev:PullMessagesResponse>
            <tev:CurrentTime>{datetime.utcnow().isoformat()}</tev:CurrentTime>
            <tev:TerminationTime>{datetime.utcnow().isoformat()}</tev:TerminationTime>
            {events_xml}
        </tev:PullMessagesResponse>
    </soap:Body>
</soap:Envelope>'''
        return web.Response(text=response, content_type='application/soap+xml')

    def _create_soap_fault(self, fault_string: str) -> web.Response:
        """Create SOAP fault response.

        Generates a SOAP fault message for error conditions.

        Args:
            fault_string: Error message to include in fault response

        Returns:
            SOAP XML fault response with HTTP 500 status
        """
        response = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
    <soap:Body>
        <soap:Fault>
            <soap:Code>
                <soap:Value>soap:Receiver</soap:Value>
            </soap:Code>
            <soap:Reason>
                <soap:Text xml:lang="en">{fault_string}</soap:Text>
            </soap:Reason>
        </soap:Fault>
    </soap:Body>
</soap:Envelope>'''
        return web.Response(text=response, content_type='application/soap+xml', status=500)

    async def start_server(self):
        """Start ONVIF camera simulator HTTP server.

        Initializes aiohttp web application, registers all ONVIF service
        endpoints, and starts the HTTP server. Runs until interrupted.
        """
        app = web.Application()

        # ONVIF service endpoints
        app.router.add_post('/onvif/device_service', self.handle_onvif_service)
        app.router.add_post('/onvif/media_service', self.handle_onvif_service)
        app.router.add_post('/onvif/ptz_service', self.handle_onvif_service)
        app.router.add_post('/onvif/event_service', self.handle_onvif_service)
        app.router.add_post('/onvif/imaging_service', self.handle_onvif_service)

        # Health check
        app.router.add_get('/health', self.handle_health)

        runner = web.AppRunner(app)
        await runner.setup()
        site = web.TCPSite(runner, self.host, self.port)
        await site.start()

        logger.info(f"ONVIF Camera Simulator started on http://{self.host}:{self.port}")
        logger.info(f"Device Service: http://{self.host}:{self.port}/onvif/device_service")
        logger.info(f"Media Profiles: {len(self.media_profiles)} (Profile S and T)")
        logger.info("PTZ Control: Enabled")
        logger.info("Events: Motion Detection, Tampering Detection")

        try:
            await asyncio.Event().wait()
        except KeyboardInterrupt:
            logger.info("Shutting down ONVIF Camera Simulator")
        finally:
            await runner.cleanup()


if __name__ == '__main__':
    simulator = ONVIFCameraSimulator()
    asyncio.run(simulator.start_server())
