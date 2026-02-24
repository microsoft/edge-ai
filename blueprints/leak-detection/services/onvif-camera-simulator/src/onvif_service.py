"""ONVIF SOAP endpoint handlers for Profile S and Profile T.

Provides device discovery, media URIs, PTZ control, event generation,
and imaging control via ONVIF-compliant SOAP responses.
"""

from __future__ import annotations

import logging
import random
import time
import uuid
from datetime import datetime, timezone
from typing import TYPE_CHECKING

from aiohttp import web
from lxml import etree

if TYPE_CHECKING:
    from src.camera_manager import CameraManager

logger = logging.getLogger(__name__)

ONVIF_NAMESPACES = {
    "soap": "http://www.w3.org/2003/05/soap-envelope",
    "tds": "http://www.onvif.org/ver10/device/wsdl",
    "trt": "http://www.onvif.org/ver10/media/wsdl",
    "tr2": "http://www.onvif.org/ver20/media/wsdl",
    "tptz": "http://www.onvif.org/ver20/ptz/wsdl",
    "tev": "http://www.onvif.org/ver10/events/wsdl",
    "timg": "http://www.onvif.org/ver20/imaging/wsdl",
    "tt": "http://www.onvif.org/ver10/schema",
}


class ONVIFService:
    """ONVIF SOAP service with dynamic profiles from CameraManager."""

    def __init__(
        self,
        camera_manager: CameraManager,
        device_hostname: str,
        onvif_port: int,
        rtsp_port: int,
    ) -> None:
        self.camera_manager = camera_manager
        self.device_hostname = device_hostname
        self.onvif_port = onvif_port
        self.rtsp_port = rtsp_port

        self.manufacturer = "Edge AI Simulator"
        self.model = "ONVIF-PTZ-4K"
        self.firmware_version = "1.0.0"
        self.serial_number = str(uuid.uuid4())[:8].upper()

        self.ptz_position = {"pan": 0.0, "tilt": 0.0, "zoom": 1.0}
        self.imaging_settings = {
            "brightness": 50.0,
            "contrast": 50.0,
            "saturation": 50.0,
            "sharpness": 50.0,
        }

        self.motion_detected = False
        self.tampering_detected = False
        self.last_event_time = time.time()

    def setup_routes(self, app: web.Application) -> None:
        """Register ONVIF SOAP POST routes on the application."""
        app.router.add_post("/onvif/device_service",
                            self.handle_device_service)
        app.router.add_post("/onvif/media_service", self.handle_media_service)
        app.router.add_post("/onvif/media2_service",
                            self.handle_media2_service)
        app.router.add_post("/onvif/ptz_service", self.handle_ptz_service)
        app.router.add_post("/onvif/event_service", self.handle_event_service)
        app.router.add_post("/onvif/imaging_service",
                            self.handle_imaging_service)

    # -- Route handlers -------------------------------------------------------

    async def handle_device_service(self, request: web.Request) -> web.Response:
        """Route SOAP requests for the Device service."""
        return await self._dispatch(request, {
            "GetDeviceInformation": self._get_device_information,
            "GetCapabilities": self._get_capabilities,
            "GetServices": self._get_services,
            "GetSystemDateAndTime": self._get_system_date_and_time,
            "GetScopes": self._get_scopes,
        })

    async def handle_media_service(self, request: web.Request) -> web.Response:
        """Route SOAP requests for the Media (Profile S) service."""
        return await self._dispatch(request, {
            "GetProfiles": self._get_profiles,
            "GetStreamUri": self._get_stream_uri,
            "GetSnapshotUri": self._get_snapshot_uri,
            "GetVideoSources": self._get_video_sources,
            "GetVideoEncoderConfigurations": self._get_video_encoder_configurations,
        })

    async def handle_media2_service(self, request: web.Request) -> web.Response:
        """Route SOAP requests for the Media2 (Profile T) service."""
        return await self._dispatch(request, {
            "GetProfiles": self._get_profiles_media2,
            "GetStreamUri": self._get_stream_uri_media2,
        })

    async def handle_ptz_service(self, request: web.Request) -> web.Response:
        """Route SOAP requests for the PTZ service."""
        return await self._dispatch(request, {
            "GetConfigurations": self._get_ptz_configurations,
            "AbsoluteMove": self._handle_ptz_move,
            "RelativeMove": self._handle_ptz_move,
            "ContinuousMove": self._handle_ptz_move,
            "Stop": self._handle_ptz_stop,
            "GetPresets": self._get_ptz_presets,
        })

    async def handle_event_service(self, request: web.Request) -> web.Response:
        """Route SOAP requests for the Event service."""
        return await self._dispatch(request, {
            "GetEventProperties": self._get_event_properties,
            "CreatePullPointSubscription": self._create_pull_point_subscription,
            "PullMessages": self._pull_messages,
        })

    async def handle_imaging_service(self, request: web.Request) -> web.Response:
        """Route SOAP requests for the Imaging service."""
        return await self._dispatch(request, {
            "GetImagingSettings": self._get_imaging_settings,
            "SetImagingSettings": self._set_imaging_settings,
        })

    # -- Dispatch helper ------------------------------------------------------

    async def _dispatch(
        self,
        request: web.Request,
        action_map: dict,
    ) -> web.Response:
        """Parse SOAP body, extract action tag, and route to handler."""
        try:
            body = await request.text()
            parser = etree.XMLParser(resolve_entities=False)
            root = etree.fromstring(body.encode("utf-8"), parser=parser)

            body_elem = root.find(".//soap:Body", ONVIF_NAMESPACES)
            if body_elem is None:
                return self._create_soap_fault("No SOAP Body found")

            for child in body_elem:
                local_tag = etree.QName(child.tag).localname
                handler = action_map.get(local_tag)
                if handler:
                    return handler(child)

            return self._create_soap_fault("Unknown ONVIF method")
        except Exception as exc:
            logger.exception("Error handling ONVIF request")
            return self._create_soap_fault(str(exc))

    # -- SOAP response helpers ------------------------------------------------

    def _build_soap_response(self, body_content: etree._Element) -> web.Response:
        """Wrap body_content in a SOAP envelope and return as Response."""
        envelope = etree.Element(
            "{http://www.w3.org/2003/05/soap-envelope}Envelope",
        )
        body = etree.SubElement(
            envelope, "{http://www.w3.org/2003/05/soap-envelope}Body")
        body.append(body_content)
        return web.Response(
            text=etree.tostring(envelope, encoding="unicode",
                                xml_declaration=True),
            content_type="application/soap+xml",
        )

    def _create_soap_fault(self, fault_string: str) -> web.Response:
        """Return a SOAP fault response."""
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
        return web.Response(text=response, content_type="application/soap+xml", status=500)

    # -- Helper: extract profile token from a SOAP element --------------------

    def _extract_profile_token(self, element: etree._Element) -> str | None:
        """Extract ProfileToken text from a SOAP request element."""
        for ns_prefix in ("trt", "tr2", "tt"):
            ns = ONVIF_NAMESPACES.get(ns_prefix, "")
            token_elem = element.find(f".//{{{ns}}}ProfileToken")
            if token_elem is not None and token_elem.text:
                return token_elem.text
        token_elem = element.find(".//{*}ProfileToken")
        if token_elem is not None and token_elem.text:
            return token_elem.text
        return None

    def _camera_id_from_token(self, token: str) -> str:
        """Derive camera ID from a profile token like 'profile_{cam_id}_main'."""
        parts = token.split("_")
        if len(parts) >= 3 and parts[0] == "profile":
            return "_".join(parts[1:-1])
        cameras = self.camera_manager.get_all_cameras()
        if cameras:
            return cameras[0].id
        return "unknown"

    # -- Device service operations --------------------------------------------

    def _get_device_information(self, _element: etree._Element) -> web.Response:
        ns_tds = ONVIF_NAMESPACES["tds"]
        resp = etree.Element(f"{{{ns_tds}}}GetDeviceInformationResponse")
        etree.SubElement(
            resp, f"{{{ns_tds}}}Manufacturer").text = self.manufacturer
        etree.SubElement(resp, f"{{{ns_tds}}}Model").text = self.model
        etree.SubElement(
            resp, f"{{{ns_tds}}}FirmwareVersion").text = self.firmware_version
        etree.SubElement(
            resp, f"{{{ns_tds}}}SerialNumber").text = self.serial_number
        etree.SubElement(
            resp, f"{{{ns_tds}}}HardwareId").text = "SIMULATOR-001"
        return self._build_soap_response(resp)

    def _get_capabilities(self, _element: etree._Element) -> web.Response:
        host = self.device_hostname
        port = self.onvif_port
        response = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
               xmlns:tds="http://www.onvif.org/ver10/device/wsdl"
               xmlns:tt="http://www.onvif.org/ver10/schema">
    <soap:Body>
        <tds:GetCapabilitiesResponse>
            <tds:Capabilities>
                <tt:Media>
                    <tt:XAddr>http://{host}:{port}/onvif/media_service</tt:XAddr>
                    <tt:StreamingCapabilities>
                        <tt:RTPMulticast>false</tt:RTPMulticast>
                        <tt:RTP_TCP>true</tt:RTP_TCP>
                        <tt:RTP_RTSP_TCP>true</tt:RTP_RTSP_TCP>
                    </tt:StreamingCapabilities>
                </tt:Media>
                <tt:PTZ>
                    <tt:XAddr>http://{host}:{port}/onvif/ptz_service</tt:XAddr>
                </tt:PTZ>
                <tt:Events>
                    <tt:XAddr>http://{host}:{port}/onvif/event_service</tt:XAddr>
                </tt:Events>
                <tt:Imaging>
                    <tt:XAddr>http://{host}:{port}/onvif/imaging_service</tt:XAddr>
                </tt:Imaging>
            </tds:Capabilities>
        </tds:GetCapabilitiesResponse>
    </soap:Body>
</soap:Envelope>'''
        return web.Response(text=response, content_type="application/soap+xml")

    def _get_services(self, _element: etree._Element) -> web.Response:
        host = self.device_hostname
        port = self.onvif_port
        ns_tds = ONVIF_NAMESPACES["tds"]
        resp = etree.Element(f"{{{ns_tds}}}GetServicesResponse")

        services = [
            ("http://www.onvif.org/ver10/device/wsdl",
             f"http://{host}:{port}/onvif/device_service"),
            ("http://www.onvif.org/ver10/media/wsdl",
             f"http://{host}:{port}/onvif/media_service"),
            ("http://www.onvif.org/ver20/media/wsdl",
             f"http://{host}:{port}/onvif/media2_service"),
            ("http://www.onvif.org/ver20/ptz/wsdl",
             f"http://{host}:{port}/onvif/ptz_service"),
            ("http://www.onvif.org/ver10/events/wsdl",
             f"http://{host}:{port}/onvif/event_service"),
            ("http://www.onvif.org/ver20/imaging/wsdl",
             f"http://{host}:{port}/onvif/imaging_service"),
        ]
        for namespace, xaddr in services:
            svc = etree.SubElement(resp, f"{{{ns_tds}}}Service")
            etree.SubElement(svc, f"{{{ns_tds}}}Namespace").text = namespace
            etree.SubElement(svc, f"{{{ns_tds}}}XAddr").text = xaddr

        return self._build_soap_response(resp)

    def _get_system_date_and_time(self, _element: etree._Element) -> web.Response:
        now = datetime.now(timezone.utc)
        ns_tds = ONVIF_NAMESPACES["tds"]
        ns_tt = ONVIF_NAMESPACES["tt"]
        resp = etree.Element(f"{{{ns_tds}}}GetSystemDateAndTimeResponse")
        sdt = etree.SubElement(resp, f"{{{ns_tds}}}SystemDateAndTime")
        etree.SubElement(sdt, f"{{{ns_tt}}}DateTimeType").text = "NTP"
        etree.SubElement(sdt, f"{{{ns_tt}}}DaylightSavings").text = "false"

        tz = etree.SubElement(sdt, f"{{{ns_tt}}}TimeZone")
        etree.SubElement(tz, f"{{{ns_tt}}}TZ").text = "UTC+0"

        utc_dt = etree.SubElement(sdt, f"{{{ns_tt}}}UTCDateTime")
        time_elem = etree.SubElement(utc_dt, f"{{{ns_tt}}}Time")
        etree.SubElement(time_elem, f"{{{ns_tt}}}Hour").text = str(now.hour)
        etree.SubElement(
            time_elem, f"{{{ns_tt}}}Minute").text = str(now.minute)
        etree.SubElement(
            time_elem, f"{{{ns_tt}}}Second").text = str(now.second)
        date_elem = etree.SubElement(utc_dt, f"{{{ns_tt}}}Date")
        etree.SubElement(date_elem, f"{{{ns_tt}}}Year").text = str(now.year)
        etree.SubElement(date_elem, f"{{{ns_tt}}}Month").text = str(now.month)
        etree.SubElement(date_elem, f"{{{ns_tt}}}Day").text = str(now.day)

        return self._build_soap_response(resp)

    def _get_scopes(self, _element: etree._Element) -> web.Response:
        ns_tds = ONVIF_NAMESPACES["tds"]
        ns_tt = ONVIF_NAMESPACES["tt"]
        resp = etree.Element(f"{{{ns_tds}}}GetScopesResponse")

        scope_uris = [
            "onvif://www.onvif.org/type/video_encoder",
            "onvif://www.onvif.org/type/ptz",
            "onvif://www.onvif.org/Profile/Streaming",
            f"onvif://www.onvif.org/name/{self.model}",
            f"onvif://www.onvif.org/hardware/{self.model}",
        ]
        for uri in scope_uris:
            scope = etree.SubElement(resp, f"{{{ns_tds}}}Scopes")
            etree.SubElement(scope, f"{{{ns_tt}}}ScopeDef").text = "Fixed"
            etree.SubElement(scope, f"{{{ns_tt}}}ScopeItem").text = uri

        return self._build_soap_response(resp)

    # -- Media service (Profile S) operations ---------------------------------

    def _get_profiles(self, _element: etree._Element) -> web.Response:
        cameras = self.camera_manager.get_all_cameras()
        profiles_xml = ""
        for cam in cameras:
            w, h = cam.resolution.split("x")
            token = f"profile_{cam.id}_main"
            profiles_xml += f'''
            <trt:Profiles token="{token}" fixed="true">
                <tt:Name>{cam.name}</tt:Name>
                <tt:VideoEncoderConfiguration token="vec_{cam.id}">
                    <tt:Encoding>H264</tt:Encoding>
                    <tt:Resolution>
                        <tt:Width>{w}</tt:Width>
                        <tt:Height>{h}</tt:Height>
                    </tt:Resolution>
                    <tt:RateControl>
                        <tt:FrameRateLimit>{cam.framerate}</tt:FrameRateLimit>
                        <tt:BitrateLimit>4000</tt:BitrateLimit>
                    </tt:RateControl>
                </tt:VideoEncoderConfiguration>
                <tt:PTZConfiguration token="ptz_{cam.id}">
                    <tt:Name>PTZ Configuration</tt:Name>
                </tt:PTZConfiguration>
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
        return web.Response(text=response, content_type="application/soap+xml")

    def _get_stream_uri(self, element: etree._Element) -> web.Response:
        token = self._extract_profile_token(element) or ""
        camera_id = self._camera_id_from_token(token)
        uri = f"rtsp://{self.device_hostname}:{self.rtsp_port}/{camera_id}"

        response = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
               xmlns:trt="http://www.onvif.org/ver10/media/wsdl"
               xmlns:tt="http://www.onvif.org/ver10/schema">
    <soap:Body>
        <trt:GetStreamUriResponse>
            <trt:MediaUri>
                <tt:Uri>{uri}</tt:Uri>
                <tt:InvalidAfterConnect>false</tt:InvalidAfterConnect>
                <tt:InvalidAfterReboot>false</tt:InvalidAfterReboot>
                <tt:Timeout>PT60S</tt:Timeout>
            </trt:MediaUri>
        </trt:GetStreamUriResponse>
    </soap:Body>
</soap:Envelope>'''
        return web.Response(text=response, content_type="application/soap+xml")

    def _get_snapshot_uri(self, element: etree._Element) -> web.Response:
        token = self._extract_profile_token(element) or ""
        camera_id = self._camera_id_from_token(token)
        uri = f"http://{self.device_hostname}:{self.onvif_port}/snapshot/{camera_id}"

        ns_trt = ONVIF_NAMESPACES["trt"]
        ns_tt = ONVIF_NAMESPACES["tt"]
        resp = etree.Element(f"{{{ns_trt}}}GetSnapshotUriResponse")
        media_uri = etree.SubElement(resp, f"{{{ns_trt}}}MediaUri")
        etree.SubElement(media_uri, f"{{{ns_tt}}}Uri").text = uri
        etree.SubElement(
            media_uri, f"{{{ns_tt}}}InvalidAfterConnect").text = "false"
        etree.SubElement(
            media_uri, f"{{{ns_tt}}}InvalidAfterReboot").text = "false"
        etree.SubElement(media_uri, f"{{{ns_tt}}}Timeout").text = "PT60S"
        return self._build_soap_response(resp)

    def _get_video_sources(self, _element: etree._Element) -> web.Response:
        cameras = self.camera_manager.get_all_cameras()
        ns_trt = ONVIF_NAMESPACES["trt"]
        ns_tt = ONVIF_NAMESPACES["tt"]
        resp = etree.Element(f"{{{ns_trt}}}GetVideoSourcesResponse")

        for cam in cameras:
            w, h = cam.resolution.split("x")
            vs = etree.SubElement(
                resp, f"{{{ns_trt}}}VideoSources", token=f"vs_{cam.id}")
            etree.SubElement(vs, f"{{{ns_tt}}}Framerate").text = str(
                cam.framerate)
            res = etree.SubElement(vs, f"{{{ns_tt}}}Resolution")
            etree.SubElement(res, f"{{{ns_tt}}}Width").text = w
            etree.SubElement(res, f"{{{ns_tt}}}Height").text = h

        return self._build_soap_response(resp)

    def _get_video_encoder_configurations(self, _element: etree._Element) -> web.Response:
        cameras = self.camera_manager.get_all_cameras()
        ns_trt = ONVIF_NAMESPACES["trt"]
        ns_tt = ONVIF_NAMESPACES["tt"]
        resp = etree.Element(
            f"{{{ns_trt}}}GetVideoEncoderConfigurationsResponse")

        for cam in cameras:
            w, h = cam.resolution.split("x")
            vec = etree.SubElement(
                resp, f"{{{ns_trt}}}Configurations", token=f"vec_{cam.id}")
            etree.SubElement(
                vec, f"{{{ns_tt}}}Name").text = f"{cam.name} Encoder"
            etree.SubElement(vec, f"{{{ns_tt}}}Encoding").text = "H264"
            res = etree.SubElement(vec, f"{{{ns_tt}}}Resolution")
            etree.SubElement(res, f"{{{ns_tt}}}Width").text = w
            etree.SubElement(res, f"{{{ns_tt}}}Height").text = h
            rc = etree.SubElement(vec, f"{{{ns_tt}}}RateControl")
            etree.SubElement(rc, f"{{{ns_tt}}}FrameRateLimit").text = str(
                cam.framerate)
            etree.SubElement(rc, f"{{{ns_tt}}}BitrateLimit").text = "4000"

        return self._build_soap_response(resp)

    # -- Media2 service (Profile T) operations --------------------------------

    def _get_profiles_media2(self, _element: etree._Element) -> web.Response:
        cameras = self.camera_manager.get_all_cameras()
        profiles_xml = ""
        for cam in cameras:
            w, h = cam.resolution.split("x")
            token = f"profile_{cam.id}_main"
            profiles_xml += f'''
            <tr2:Profiles token="{token}" fixed="true">
                <tt:Name>{cam.name}</tt:Name>
                <tr2:Configurations>
                    <tr2:VideoEncoder token="vec2_{cam.id}">
                        <tt:Encoding>H265</tt:Encoding>
                        <tt:Resolution>
                            <tt:Width>{w}</tt:Width>
                            <tt:Height>{h}</tt:Height>
                        </tt:Resolution>
                        <tt:RateControl>
                            <tt:FrameRateLimit>{cam.framerate}</tt:FrameRateLimit>
                            <tt:BitrateLimit>8000</tt:BitrateLimit>
                        </tt:RateControl>
                    </tr2:VideoEncoder>
                </tr2:Configurations>
            </tr2:Profiles>'''

        response = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
               xmlns:tr2="http://www.onvif.org/ver20/media/wsdl"
               xmlns:tt="http://www.onvif.org/ver10/schema">
    <soap:Body>
        <tr2:GetProfilesResponse>
            {profiles_xml}
        </tr2:GetProfilesResponse>
    </soap:Body>
</soap:Envelope>'''
        return web.Response(text=response, content_type="application/soap+xml")

    def _get_stream_uri_media2(self, element: etree._Element) -> web.Response:
        token = self._extract_profile_token(element) or ""
        camera_id = self._camera_id_from_token(token)
        uri = f"rtsp://{self.device_hostname}:{self.rtsp_port}/{camera_id}"

        ns_tr2 = ONVIF_NAMESPACES["tr2"]
        resp = etree.Element(f"{{{ns_tr2}}}GetStreamUriResponse")
        etree.SubElement(resp, f"{{{ns_tr2}}}Uri").text = uri
        return self._build_soap_response(resp)

    # -- PTZ service operations -----------------------------------------------

    def _get_ptz_configurations(self, _element: etree._Element) -> web.Response:
        cameras = self.camera_manager.get_all_cameras()
        ns_tptz = ONVIF_NAMESPACES["tptz"]
        ns_tt = ONVIF_NAMESPACES["tt"]
        resp = etree.Element(f"{{{ns_tptz}}}GetConfigurationsResponse")

        for cam in cameras:
            cfg = etree.SubElement(
                resp, f"{{{ns_tptz}}}PTZConfiguration", token=f"ptz_{cam.id}")
            etree.SubElement(cfg, f"{{{ns_tt}}}Name").text = f"PTZ {cam.name}"
            etree.SubElement(
                cfg, f"{{{ns_tt}}}NodeToken").text = f"ptznode_{cam.id}"

        return self._build_soap_response(resp)

    def _handle_ptz_move(self, element: etree._Element) -> web.Response:
        """Handle AbsoluteMove, RelativeMove, and ContinuousMove."""
        for search_tag in ("Velocity", "Position", "Translation"):
            target = element.find(
                f".//{{{ONVIF_NAMESPACES['tt']}}}{search_tag}")
            if target is None:
                target = element.find(f".//{{*}}{search_tag}")
            if target is not None:
                pan_tilt = target.find(
                    f".//{{{ONVIF_NAMESPACES['tt']}}}PanTilt")
                if pan_tilt is None:
                    pan_tilt = target.find(".//{*}PanTilt")
                zoom_elem = target.find(f".//{{{ONVIF_NAMESPACES['tt']}}}Zoom")
                if zoom_elem is None:
                    zoom_elem = target.find(".//{*}Zoom")

                if pan_tilt is not None:
                    self.ptz_position["pan"] = float(pan_tilt.get("x", 0.0))
                    self.ptz_position["tilt"] = float(pan_tilt.get("y", 0.0))
                if zoom_elem is not None:
                    self.ptz_position["zoom"] = float(zoom_elem.get("x", 1.0))
                break

        logger.info("PTZ move: %s", self.ptz_position)

        ns_tptz = ONVIF_NAMESPACES["tptz"]
        resp = etree.Element(f"{{{ns_tptz}}}MoveResponse")
        return self._build_soap_response(resp)

    def _handle_ptz_stop(self, _element: etree._Element) -> web.Response:
        logger.info("PTZ stop")
        ns_tptz = ONVIF_NAMESPACES["tptz"]
        resp = etree.Element(f"{{{ns_tptz}}}StopResponse")
        return self._build_soap_response(resp)

    def _get_ptz_presets(self, _element: etree._Element) -> web.Response:
        ns_tptz = ONVIF_NAMESPACES["tptz"]
        ns_tt = ONVIF_NAMESPACES["tt"]
        resp = etree.Element(f"{{{ns_tptz}}}GetPresetsResponse")

        presets = [
            ("preset_home", "Home", 0.0, 0.0, 1.0),
            ("preset_left", "Left", -1.0, 0.0, 1.0),
            ("preset_right", "Right", 1.0, 0.0, 1.0),
        ]
        for token, name, pan, tilt, zoom in presets:
            preset = etree.SubElement(
                resp, f"{{{ns_tptz}}}Preset", token=token)
            etree.SubElement(preset, f"{{{ns_tt}}}Name").text = name
            pos = etree.SubElement(preset, f"{{{ns_tt}}}PTZPosition")
            etree.SubElement(pos, f"{{{ns_tt}}}PanTilt",
                             x=str(pan), y=str(tilt))
            etree.SubElement(pos, f"{{{ns_tt}}}Zoom", x=str(zoom))

        return self._build_soap_response(resp)

    # -- Event service operations ---------------------------------------------

    def _get_event_properties(self, _element: etree._Element) -> web.Response:
        ns_tev = ONVIF_NAMESPACES["tev"]
        resp = etree.Element(f"{{{ns_tev}}}GetEventPropertiesResponse")
        topics = etree.SubElement(resp, f"{{{ns_tev}}}TopicNamespaceLocation")
        topics.text = "http://www.onvif.org/ver10/topics/topicns.xml"
        return self._build_soap_response(resp)

    def _create_pull_point_subscription(self, _element: etree._Element) -> web.Response:
        ns_tev = ONVIF_NAMESPACES["tev"]
        resp = etree.Element(
            f"{{{ns_tev}}}CreatePullPointSubscriptionResponse")
        sub_ref = etree.SubElement(resp, f"{{{ns_tev}}}SubscriptionReference")
        addr = etree.SubElement(
            sub_ref,
            "{http://www.w3.org/2005/08/addressing}Address",
        )
        addr.text = f"http://{self.device_hostname}:{self.onvif_port}/onvif/event_service"
        now = datetime.now(timezone.utc).isoformat()
        etree.SubElement(resp, f"{{{ns_tev}}}CurrentTime").text = now
        etree.SubElement(resp, f"{{{ns_tev}}}TerminationTime").text = now
        return self._build_soap_response(resp)

    def _pull_messages(self, _element: etree._Element) -> web.Response:
        current_time = time.time()
        if current_time - self.last_event_time > 10:
            self.motion_detected = random.choice([True, False])
            self.tampering_detected = random.choice(
                [True, False, False, False])
            self.last_event_time = current_time

        now_iso = datetime.now(timezone.utc).isoformat()
        events_xml = ""

        if self.motion_detected:
            events_xml += f'''
            <wsnt:NotificationMessage>
                <wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">
                    tns1:RuleEngine/CellMotionDetector/Motion
                </wsnt:Topic>
                <wsnt:Message>
                    <tt:Message UtcTime="{now_iso}">
                        <tt:Source>
                            <tt:SimpleItem Name="VideoSourceConfigurationToken" Value="vs_default"/>
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
                    <tt:Message UtcTime="{now_iso}">
                        <tt:Source>
                            <tt:SimpleItem Name="VideoSourceConfigurationToken" Value="vs_default"/>
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
            <tev:CurrentTime>{now_iso}</tev:CurrentTime>
            <tev:TerminationTime>{now_iso}</tev:TerminationTime>
            {events_xml}
        </tev:PullMessagesResponse>
    </soap:Body>
</soap:Envelope>'''
        return web.Response(text=response, content_type="application/soap+xml")

    # -- Imaging service operations -------------------------------------------

    def _get_imaging_settings(self, _element: etree._Element) -> web.Response:
        response = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
               xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl"
               xmlns:tt="http://www.onvif.org/ver10/schema">
    <soap:Body>
        <timg:GetImagingSettingsResponse>
            <timg:ImagingSettings>
                <tt:Brightness>{self.imaging_settings["brightness"]}</tt:Brightness>
                <tt:Contrast>{self.imaging_settings["contrast"]}</tt:Contrast>
                <tt:Saturation>{self.imaging_settings["saturation"]}</tt:Saturation>
                <tt:Sharpness>{self.imaging_settings["sharpness"]}</tt:Sharpness>
            </timg:ImagingSettings>
        </timg:GetImagingSettingsResponse>
    </soap:Body>
</soap:Envelope>'''
        return web.Response(text=response, content_type="application/soap+xml")

    def _set_imaging_settings(self, element: etree._Element) -> web.Response:
        settings = element.find(
            f".//{{{ONVIF_NAMESPACES['timg']}}}ImagingSettings",
        )
        if settings is not None:
            for key in self.imaging_settings:
                elem = settings.find(
                    f".//{{{ONVIF_NAMESPACES['tt']}}}{key.capitalize()}")
                if elem is not None and elem.text:
                    self.imaging_settings[key] = float(elem.text)

        logger.info("Imaging settings updated: %s", self.imaging_settings)

        ns_timg = ONVIF_NAMESPACES["timg"]
        resp = etree.Element(f"{{{ns_timg}}}SetImagingSettingsResponse")
        return self._build_soap_response(resp)
