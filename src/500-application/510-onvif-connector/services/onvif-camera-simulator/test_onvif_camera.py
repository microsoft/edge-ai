"""Unit tests for ONVIFCameraSimulator pure methods."""

import os

import pytest
from lxml import etree

from onvif_camera import ONVIFCameraSimulator


@pytest.fixture
def camera():
    os.environ.pop("ONVIF_DEVICE_ID", None)
    os.environ.pop("ONVIF_HOST", None)
    os.environ.pop("ONVIF_PORT", None)
    return ONVIFCameraSimulator()


NS = {
    "soap": "http://www.w3.org/2003/05/soap-envelope",
    "tds": "http://www.onvif.org/ver10/device/wsdl",
    "trt": "http://www.onvif.org/ver10/media/wsdl",
    "tptz": "http://www.onvif.org/ver20/ptz/wsdl",
    "timg": "http://www.onvif.org/ver20/imaging/wsdl",
    "tt": "http://www.onvif.org/ver10/schema",
}


def _parse_soap(response) -> etree._Element:
    return etree.fromstring(response.text.encode("utf-8"))


class TestCreateSoapFault:
    def test_returns_500_status(self, camera):
        resp = camera._create_soap_fault("something broke")
        assert resp.status == 500

    def test_content_type_is_soap_xml(self, camera):
        resp = camera._create_soap_fault("err")
        assert resp.content_type == "application/soap+xml"

    def test_fault_string_in_body(self, camera):
        resp = camera._create_soap_fault("kaboom")
        root = _parse_soap(resp)
        text = root.find(".//soap:Body/soap:Fault/soap:Reason/soap:Text", NS)
        assert text is not None
        assert text.text == "kaboom"


class TestHandleGetDeviceInformation:
    def test_contains_manufacturer(self, camera):
        root = _parse_soap(camera._handle_get_device_information())
        el = root.find(".//tds:Manufacturer", NS)
        assert el is not None
        assert el.text == "Edge AI Simulator"

    def test_contains_model(self, camera):
        root = _parse_soap(camera._handle_get_device_information())
        el = root.find(".//tds:Model", NS)
        assert el is not None
        assert el.text == "ONVIF-PTZ-4K"

    def test_contains_firmware_version(self, camera):
        root = _parse_soap(camera._handle_get_device_information())
        el = root.find(".//tds:FirmwareVersion", NS)
        assert el is not None
        assert el.text == "1.0.0"

    def test_contains_serial_number(self, camera):
        root = _parse_soap(camera._handle_get_device_information())
        el = root.find(".//tds:SerialNumber", NS)
        assert el is not None
        assert len(el.text) == 8

    def test_contains_hardware_id(self, camera):
        root = _parse_soap(camera._handle_get_device_information())
        el = root.find(".//tds:HardwareId", NS)
        assert el is not None
        assert el.text == camera.device_id


class TestHandleGetCapabilities:
    def test_includes_media_capability(self, camera):
        root = _parse_soap(camera._handle_get_capabilities())
        media = root.find(".//tt:Media", NS)
        assert media is not None

    def test_includes_ptz_capability(self, camera):
        root = _parse_soap(camera._handle_get_capabilities())
        ptz = root.find(".//tt:PTZ", NS)
        assert ptz is not None

    def test_includes_events_capability(self, camera):
        root = _parse_soap(camera._handle_get_capabilities())
        events = root.find(".//tt:Events", NS)
        assert events is not None

    def test_includes_imaging_capability(self, camera):
        root = _parse_soap(camera._handle_get_capabilities())
        imaging = root.find(".//tt:Imaging", NS)
        assert imaging is not None


class TestHandleGetProfiles:
    def test_returns_three_profiles(self, camera):
        root = _parse_soap(camera._handle_get_profiles())
        profiles = root.findall(".//trt:Profiles", NS)
        assert len(profiles) == 3

    def test_profile_tokens_match(self, camera):
        root = _parse_soap(camera._handle_get_profiles())
        tokens = {p.get("token") for p in root.findall(".//trt:Profiles", NS)}
        assert tokens == {"profile_s_h264", "profile_s_jpeg", "profile_t_h265"}

    def test_h264_profile_resolution(self, camera):
        root = _parse_soap(camera._handle_get_profiles())
        for profile in root.findall(".//trt:Profiles", NS):
            if profile.get("token") == "profile_s_h264":
                w = profile.find(".//tt:Width", NS)
                h = profile.find(".//tt:Height", NS)
                assert w.text == "1920"
                assert h.text == "1080"


class TestHandlePtzCommand:
    def _make_ptz_element(self, pan, tilt, zoom):
        ns_tt = "http://www.onvif.org/ver10/schema"
        root = etree.Element("AbsoluteMove")
        position = etree.SubElement(root, f"{{{ns_tt}}}Position")
        pt = etree.SubElement(position, f"{{{ns_tt}}}PanTilt")
        pt.set("x", str(pan))
        pt.set("y", str(tilt))
        z = etree.SubElement(position, f"{{{ns_tt}}}Zoom")
        z.set("x", str(zoom))
        return root

    def test_updates_pan_position(self, camera):
        elem = self._make_ptz_element(45.0, 0.0, 1.0)
        camera._handle_ptz_command(elem)
        assert camera.ptz_position["pan"] == 45.0

    def test_updates_tilt_position(self, camera):
        elem = self._make_ptz_element(0.0, -30.0, 1.0)
        camera._handle_ptz_command(elem)
        assert camera.ptz_position["tilt"] == -30.0

    def test_updates_zoom_position(self, camera):
        elem = self._make_ptz_element(0.0, 0.0, 5.0)
        camera._handle_ptz_command(elem)
        assert camera.ptz_position["zoom"] == 5.0

    def test_returns_soap_response(self, camera):
        elem = self._make_ptz_element(0.0, 0.0, 1.0)
        resp = camera._handle_ptz_command(elem)
        assert resp.content_type == "application/soap+xml"
        root = _parse_soap(resp)
        assert root.find(".//tptz:MoveResponse", NS) is not None


class TestHandleGetImagingSettings:
    def test_contains_brightness(self, camera):
        root = _parse_soap(camera._handle_get_imaging_settings())
        el = root.find(".//tt:Brightness", NS)
        assert el is not None
        assert float(el.text) == 50.0

    def test_contains_contrast(self, camera):
        root = _parse_soap(camera._handle_get_imaging_settings())
        el = root.find(".//tt:Contrast", NS)
        assert float(el.text) == 50.0

    def test_reflects_updated_settings(self, camera):
        camera.imaging_settings["brightness"] = 75.0
        root = _parse_soap(camera._handle_get_imaging_settings())
        el = root.find(".//tt:Brightness", NS)
        assert float(el.text) == 75.0
