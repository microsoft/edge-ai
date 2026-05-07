"""Camera dashboard application entry point.

NiceGUI-based web dashboard that displays live RTSP camera feeds as MJPEG
streams, provides ONVIF PTZ control via MQTT, and supports runtime camera
addition through manual RTSP URL entry or ONVIF network discovery.

Pages:
    / — Main dashboard with camera grid, add-camera form, PTZ controls, event feed
    /camera/{cam_id} — Single-camera full-size view with dedicated PTZ controls
    /mjpeg/{cam_id} — Raw MJPEG stream endpoint (registered by mjpeg_server)
    /health — Health check endpoint
"""
import os
from urllib.parse import quote, urlparse

from camera_manager import CameraManager
from mjpeg_server import register_mjpeg_routes
from mqtt_handler import MQTTHandler
from nicegui import app, ui
from onvif_discovery import ONVIFDiscovery, discover_onvif_devices
from ptz_controller import PTZController

camera_manager = CameraManager()
events_log = []


def on_mqtt_event(topic, payload):
    """Append incoming MQTT event to the in-memory log (max 100 entries)."""
    timestamp = payload.get("timestamp", "N/A")
    event_type = payload.get("type", "unknown")
    events_log.insert(0, f"[{timestamp}] {topic}: {event_type}")
    if len(events_log) > 100:
        events_log.pop()


mqtt = MQTTHandler(
    broker=os.getenv("MQTT_BROKER", "localhost"),
    port=int(os.getenv("MQTT_PORT", "1883")),
    topic_prefix=os.getenv("MQTT_TOPIC_PREFIX", "onvif-camera"),
    on_event_callback=on_mqtt_event,
)

ptz = PTZController()

_onvif_host = os.getenv("ONVIF_HOST", "")
_onvif_username = os.getenv("ONVIF_USERNAME", "")
_onvif_password = os.getenv("ONVIF_PASSWORD", "")

fps = int(os.getenv("VIDEO_FPS", "15"))
jpeg_quality = int(os.getenv("JPEG_QUALITY", "75"))

register_mjpeg_routes(app, camera_manager, fps=fps, jpeg_quality=jpeg_quality)


def register_camera(name, rtsp_url, onvif_host=None, onvif_port=None,
                    onvif_username=None, onvif_password=None):
    """Register a camera for RTSP capture and optional ONVIF PTZ control."""
    camera_manager.add_camera(name, rtsp_url)
    parsed = urlparse(rtsp_url)
    host = onvif_host or parsed.hostname or _onvif_host
    username = onvif_username or parsed.username or _onvif_username or ""
    password = onvif_password or parsed.password or _onvif_password or ""
    port = onvif_port or int(os.getenv("ONVIF_PORT", "80"))
    if host:
        ptz.register(name, host=host, username=username, password=password,
                     port=port)


# Load initial cameras from env
_urls = os.getenv("CAMERA_URLS", "").split(",")
_names = os.getenv("CAMERA_NAMES", "").split(",")
for _name, _url in zip(_names, _urls, strict=False):
    if _url.strip():
        register_camera(_name.strip(), _url.strip())


@ui.page("/camera/{cam_id}")
def camera_view(cam_id: str):
    """Single-camera view with full-size MJPEG feed and PTZ controls."""
    ui.dark_mode(True)

    cameras = {c["id"] for c in camera_manager.list_cameras()}
    if cam_id not in cameras:
        ui.label(f"Camera '{cam_id}' not found").classes("text-h5 text-red")
        ui.link("Back to dashboard", "/").classes("text-h6")
        return

    async def send_ptz_single(action, **kwargs):
        getattr(mqtt, action)(cam_id, **kwargs)
        if ptz.has_ptz(cam_id):
            try:
                result = await getattr(ptz, action)(cam_id, **kwargs)
                if not result:
                    ui.notify(f"PTZ {action} failed", type="negative")
            except Exception as e:
                ui.notify(f"PTZ error: {e}", type="negative")

    with ui.header().classes("items-center justify-between"):
        with ui.row().classes("items-center gap-4"):
            ui.link("← Dashboard", "/").classes("text-white text-h6 no-underline")
            ui.label(f"Camera: {cam_id}").classes("text-h4")

    safe_cam_id = quote(cam_id, safe='')

    with ui.column().classes("w-full p-4 items-center"):
        with ui.card().classes("w-full max-w-4xl"):
            ui.html(
                f'<img src="/mjpeg/{safe_cam_id}" '
                f'style="width:100%;max-height:75vh;" />'
            )

        with ui.card().classes("max-w-md"):
            ui.label("PTZ Control").classes("text-h6 text-center")

            with ui.grid(columns=3).classes("gap-1 justify-center"):
                ui.label("")
                ui.button("Up", on_click=lambda: send_ptz_single(
                    "tilt", direction="up")).props("dense")
                ui.label("")
                ui.button("Left", on_click=lambda: send_ptz_single(
                    "pan", direction="left")).props("dense")
                ui.button("Home", on_click=lambda: send_ptz_single(
                    "home")).props("dense color=accent")
                ui.button("Right", on_click=lambda: send_ptz_single(
                    "pan", direction="right")).props("dense")
                ui.label("")
                ui.button("Down", on_click=lambda: send_ptz_single(
                    "tilt", direction="down")).props("dense")
                ui.label("")

            with ui.row().classes("gap-2 justify-center mt-2"):
                ui.button(
                    "Zoom +", on_click=lambda: send_ptz_single(
                        "zoom", direction="in")).props("dense")
                ui.button(
                    "Zoom -", on_click=lambda: send_ptz_single(
                        "zoom", direction="out")).props("dense")


@ui.page("/")
def dashboard():
    """Main dashboard page with camera grid, discovery, PTZ, and event feed."""
    ui.dark_mode(True)

    initial_cameras = camera_manager.list_cameras()
    selected_camera = {"id": initial_cameras[0]["id"] if initial_cameras else None}
    camera_options = {c["id"]: c["id"] for c in initial_cameras}
    grid_container = None

    async def send_ptz(action, **kwargs):
        cam_id = selected_camera["id"]
        if not cam_id:
            ui.notify("Select a camera first", type="warning")
            return
        getattr(mqtt, action)(cam_id, **kwargs)
        if ptz.has_ptz(cam_id):
            try:
                result = await getattr(ptz, action)(cam_id, **kwargs)
                if not result:
                    ui.notify(f"PTZ {action} failed for {cam_id}", type="negative")
            except Exception as e:
                ui.notify(f"PTZ error: {e}", type="negative")

    with ui.header().classes("items-center justify-between"):
        ui.label("ONVIF Camera Dashboard").classes("text-h4")

    with ui.row().classes("w-full gap-4 p-4"):
        # Left column: camera input, selector, video
        with ui.column().classes("flex-grow"):
            # Camera input form
            with ui.card().classes("w-full"):
                ui.label("Add Camera").classes("text-h6")
                url_input = ui.input(
                    "RTSP URL", placeholder="rtsp://user:pass@host:554/stream")
                name_input = ui.input("Camera Name", placeholder="camera-1")

                def add_camera():
                    url = url_input.value.strip()
                    name = name_input.value.strip()
                    if url and name:
                        register_camera(name, url)
                        camera_options[name] = name
                        camera_select.options = camera_options
                        camera_select.update()
                        url_input.value = ""
                        name_input.value = ""
                        rebuild_grid()
                        ui.notify(f"Added camera: {name}")

                ui.button("Add Camera", on_click=add_camera).props(
                    "color=primary")

            # Network Discovery
            with ui.card().classes("w-full"):
                ui.label("Network Discovery").classes("text-h6")
                probe_input = ui.input(
                    "Target IP(s)",
                    placeholder="192.168.1.100 or 192.168.1.100:8000",
                ).classes("w-full").tooltip(
                    "Single IP or IP:port. "
                    "Comma-separated for multiple addresses. "
                    "Append :port to set a custom ONVIF port."
                )

                discovery_dialog = ui.dialog()
                with discovery_dialog, ui.card().classes("min-w-[500px]"):
                    discovery_container = ui.column().classes("w-full")

                def populate_discovery_dialog(devices):
                    discovery_container.clear()
                    with discovery_container:
                        ui.label("Discovered Cameras").classes("text-h6")
                        if not devices:
                            ui.label(
                                "No cameras found on the network."
                            ).classes("text-body1 text-grey")
                        for dev in devices:
                            with ui.card().classes("w-full q-mb-sm"):
                                ui.label(dev["name"]).classes(
                                    "text-subtitle1 font-bold")
                                ui.label(
                                    f'{dev["host"]}:{dev["port"]}'
                                ).classes("text-caption text-grey")
                                with ui.row().classes(
                                        "items-end gap-2 w-full"):
                                    u = ui.input(
                                        "Username", value="admin",
                                    ).classes("flex-grow")
                                    p = ui.input(
                                        "Password", password=True,
                                        password_toggle_button=True,
                                    ).classes("flex-grow")

                                    async def add_found(
                                            d=dev, user=u, pwd=p):
                                        try:
                                            disc = ONVIFDiscovery(
                                                d["host"], d["port"],
                                                user.value, pwd.value)
                                            uri = await disc.get_stream_uri()
                                            if not uri:
                                                ui.notify(
                                                    f'No stream on {d["host"]}',
                                                    type="warning")
                                                return
                                            parsed = urlparse(uri)
                                            cred = (
                                                f"{quote(user.value, safe='')}:"
                                                f"{quote(pwd.value, safe='')}")
                                            netloc = (
                                                f"{cred}@{parsed.hostname}"
                                                f":{parsed.port or 554}")
                                            rtsp_url = parsed._replace(
                                                netloc=netloc).geturl()
                                            cam_id = (
                                                d["name"].lower()
                                                .replace(" ", "-")
                                                .replace("(", "")
                                                .replace(")", ""))
                                            register_camera(
                                                cam_id, rtsp_url,
                                                onvif_host=d["host"],
                                                onvif_port=d["port"],
                                                onvif_username=user.value,
                                                onvif_password=pwd.value)
                                            camera_options[cam_id] = cam_id
                                            camera_select.options = (
                                                camera_options)
                                            camera_select.update()
                                            rebuild_grid()
                                            ui.notify(
                                                f"Added: {cam_id}",
                                                type="positive")
                                        except Exception as exc:
                                            ui.notify(
                                                f"Failed: {exc}",
                                                type="negative")

                                    ui.button(
                                        "Add", on_click=add_found,
                                    ).props("dense color=primary")
                        ui.button(
                            "Close", on_click=discovery_dialog.close,
                        ).classes("self-end q-mt-md")

                async def run_discovery():
                    discover_btn.props("loading")
                    try:
                        targets = probe_input.value.strip() or None
                        devices = await discover_onvif_devices(
                            timeout=5, target_hosts=targets)
                        populate_discovery_dialog(devices)
                        discovery_dialog.open()
                    except Exception as exc:
                        ui.notify(
                            f"Discovery error: {exc}", type="negative")
                    finally:
                        discover_btn.props(remove="loading")

                discover_btn = ui.button(
                    "Discover Cameras", on_click=run_discovery,
                ).props("color=secondary icon=search")

            # Camera selector (for PTZ target)
            with ui.card().classes("w-full"):
                ui.label("PTZ Target Camera").classes("text-h6")

                def on_camera_select(e):
                    selected_camera["id"] = e.value

                camera_select = ui.select(
                    camera_options, label="Camera",
                    value=selected_camera["id"],
                    on_change=on_camera_select,
                ).classes("w-full")

            # Video grid — all registered cameras
            with ui.card().classes("w-full"):
                ui.label("Camera Feeds").classes("text-h6")
                grid_container = ui.element("div").classes(
                    "grid gap-2 w-full"
                ).style(
                    "grid-template-columns: repeat(auto-fill, minmax(400px, 1fr))"
                )

            def rebuild_grid():
                if grid_container is None:
                    return
                grid_container.clear()
                cameras = camera_manager.list_cameras()
                with grid_container:
                    if not cameras:
                        ui.label("No cameras configured. Add cameras above or configure CAMERA_URLS in .env"
                                 ).classes("text-body1 text-grey")
                    for cam in cameras:
                        with ui.card().classes(
                            "w-full cursor-pointer hover:shadow-lg"
                        ).on(
                            "click",
                            lambda c=cam: ui.navigate.to(
                                f'/camera/{c["id"]}', new_tab=True),
                        ):
                            ui.label(cam["id"]).classes(
                                "text-subtitle2 font-bold")
                            ui.html(
                                f'<img src="/mjpeg/{quote(cam["id"], safe="")}" '
                                f'style="width:100%;max-height:50vh;" />'
                            )

            rebuild_grid()

        # Right column: PTZ controls, event feed
        with ui.column().classes("w-80"):
            # PTZ controls
            with ui.card().classes("w-full"):
                ui.label("PTZ Control").classes("text-h6")

                with ui.grid(columns=3).classes("gap-1 justify-center"):
                    ui.label("")
                    ui.button("Up", on_click=lambda: send_ptz(
                        "tilt", direction="up")).props("dense")
                    ui.label("")
                    ui.button("Left", on_click=lambda: send_ptz(
                        "pan", direction="left")).props("dense")
                    ui.button("Home", on_click=lambda: send_ptz(
                        "home")).props("dense color=accent")
                    ui.button("Right", on_click=lambda: send_ptz(
                        "pan", direction="right")).props("dense")
                    ui.label("")
                    ui.button("Down", on_click=lambda: send_ptz(
                        "tilt", direction="down")).props("dense")
                    ui.label("")

                with ui.row().classes("gap-2 justify-center mt-2"):
                    ui.button(
                        "Zoom +", on_click=lambda: send_ptz("zoom", direction="in")).props("dense")
                    ui.button(
                        "Zoom -", on_click=lambda: send_ptz("zoom", direction="out")).props("dense")

            # Event feed
            with ui.card().classes("w-full"):
                ui.label("Event Feed").classes("text-h6")
                event_log_display = ui.log(max_lines=50).classes("w-full h-64")

                async def refresh_events():
                    for entry in events_log[:10]:
                        event_log_display.push(entry)

                ui.button("Refresh", on_click=refresh_events).props(
                    "dense flat icon=refresh")


try:
    mqtt.connect()
except ConnectionError:
    print("MQTT connection failed — dashboard will run without MQTT")
except Exception:
    print("MQTT unexpected error — dashboard will run without MQTT")

ui.run(
    host=os.getenv("DASHBOARD_HOST", "0.0.0.0"),
    port=int(os.getenv("DASHBOARD_PORT", "5001")),
    title="Camera Dashboard",
    reload=False,
    reconnect_timeout=30.0,
)
