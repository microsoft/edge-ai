"""NiceGUI controls for deterministic camera onboarding."""

import asyncio
from pathlib import Path
from urllib.parse import quote, urlparse

from camera_onboarding import (
    OnboardingError,
    classify_inspection_error,
    verify_rtsp_feed,
    write_onboarding_outputs,
)
from nicegui import ui
from onvif_discovery import ONVIFDiscovery, discover_onvif_devices


def render_camera_onboarding(
        camera_options,
        camera_select,
        register_camera_callback,
        rebuild_grid_callback):
    """Render the discovery, inspection, verification, and output workflow."""
    selections = []

    with ui.card().classes("w-full"):
        ui.label("Camera Onboarding Preflight").classes("text-h6")
        scope_mode = ui.radio(
            ["Explicit targets", "Multicast"], value="Explicit targets"
        ).props("inline")
        scope_input = ui.input(
            "Approved target scope",
            placeholder=(
                "192.168.1.100, 192.168.1.100:8000, "
                "192.168.1.0/24, or 192.168.1.10-20"
            ),
        ).classes("w-full")
        results = ui.column().classes("w-full")

        def render_results(candidates):
            selections.clear()
            results.clear()
            unreachable_count = sum(
                candidate["status"] == "unreachable"
                for candidate in candidates
            )
            visible_candidates = [
                candidate
                for candidate in candidates
                if candidate["status"] != "unreachable"
            ]
            with results:
                if unreachable_count:
                    ui.label(
                        f"{unreachable_count} approved endpoints were "
                        "unreachable and are hidden."
                    ).classes("text-caption text-grey")
                if not visible_candidates:
                    ui.label(
                        "No candidates found in the approved scope."
                    ).classes("text-body1 text-grey")
                for candidate in visible_candidates:
                    _render_candidate(
                        candidate,
                        selections,
                        camera_options,
                        camera_select,
                        register_camera_callback,
                        rebuild_grid_callback,
                    )

        async def discover():
            discovery_button.props("loading")
            try:
                multicast = scope_mode.value == "Multicast"
                targets = None if multicast else scope_input.value.strip() or None
                candidates = await discover_onvif_devices(
                    timeout=5,
                    target_hosts=targets,
                    multicast=multicast,
                )
                render_results(candidates)
            except ValueError as exc:
                ui.notify(str(exc), type="negative")
            except OSError:
                ui.notify(
                    "Discovery failed because the approved network scope "
                    "could not be reached",
                    type="negative",
                )
            finally:
                discovery_button.props(remove="loading")

        def generate():
            cameras = [_camera_output(selection) for selection in selections]
            try:
                output_directory = (
                    Path(__file__).resolve().parents[3]
                    / ".camera-onboarding"
                )
                discovery_path, tfvars_path = write_onboarding_outputs(
                    cameras, output_directory
                )
                ui.notify(
                    f"Generated {tfvars_path} and {discovery_path}",
                    type="positive",
                )
                output_actions.clear()
                with output_actions:
                    ui.label("Terraform proposal generated.").classes(
                        "text-positive"
                    )
                    ui.button(
                        "Copy Terraform Proposal",
                        icon="content_copy",
                        on_click=lambda: _copy_proposal(tfvars_path),
                    ).props("outline color=positive")
                    ui.button(
                        "Download Terraform Proposal",
                        icon="download",
                        on_click=lambda: ui.download.file(
                            tfvars_path,
                            filename=tfvars_path.name,
                            media_type="text/plain",
                        ),
                    ).props("outline color=positive")
            except OnboardingError as exc:
                ui.notify(str(exc), type="negative")
            except OSError as exc:
                ui.notify(
                    f"Could not write the local proposal: {exc}",
                    type="negative",
                )

        with ui.row().classes("gap-2"):
            discovery_button = ui.button(
                "Discover Approved Scope", on_click=discover
            ).props("color=secondary icon=search")
            ui.button(
                "Generate Terraform Proposal", on_click=generate
            ).props("color=positive icon=description")
        output_actions = ui.row().classes("items-center gap-2")


def _render_candidate(
        candidate,
        selections,
        camera_options,
        camera_select,
        register_camera_callback,
        rebuild_grid_callback):
    selection = {
        "candidate": candidate,
        "inspection": None,
        "feed_verification": None,
    }
    selections.append(selection)

    with ui.card().classes("w-full q-mb-sm"):
        ui.label(candidate["name"]).classes("text-subtitle1 font-bold")
        ui.label(
            f"{candidate['host']}:{candidate['port']}"
        ).classes("text-caption text-grey")
        ui.label(
            f"Status: {candidate['status']} | Evidence: "
            f"{', '.join(candidate.get('evidence', [])) or 'none'}"
        ).classes("text-caption")
        if candidate.get("error"):
            ui.label(candidate["error"]).classes("text-caption text-negative")
        if candidate["status"] == "unreachable":
            return

        with ui.row().classes("items-end gap-2 w-full"):
            username = ui.input("Username", value="admin").classes("flex-grow")
            password = ui.input(
                "Password", password=True, password_toggle_button=True
            ).classes("flex-grow")

        profile_select = ui.select({}, label="Media profile").classes("w-full")
        include_checkbox = ui.checkbox("Include in Terraform proposal")
        include_checkbox.set_enabled(False)
        secret_prefix = f"camera-{candidate['host'].replace('.', '-')}"
        with ui.row().classes("w-full gap-2"):
            username_secret = ui.input(
                "Username secret name", value=f"{secret_prefix}-username"
            ).classes("flex-grow")
            password_secret = ui.input(
                "Password secret name", value=f"{secret_prefix}-password"
            ).classes("flex-grow")
        status_label = ui.label(
            "Authenticate and inspect before verification."
        ).classes("text-caption")

        async def inspect():
            try:
                discovery = ONVIFDiscovery(
                    candidate["host"],
                    candidate["port"],
                    username.value,
                    password.value,
                )
                inspection = await discovery.discover()
                if not inspection["profiles"]:
                    selection["inspection"] = {
                        "status": "unsupported",
                        "error": "No ONVIF media profiles were reported",
                    }
                    status_label.text = (
                        "Status: unsupported - no ONVIF media profiles"
                    )
                    return
                selection["inspection"] = inspection
                selection["feed_verification"] = None
                include_checkbox.value = False
                include_checkbox.set_enabled(False)
                profile_select.options = {
                    profile["token"]: profile["name"]
                    for profile in inspection["profiles"]
                }
                profile_select.value = inspection["profiles"][0]["token"]
                profile_select.update()
                status_label.text = "Status: capabilities_inspected"
                ui.notify(
                    f"Authenticated: {candidate['host']}", type="positive"
                )
            except Exception as exc:
                failure = classify_inspection_error(exc)
                selection["inspection"] = failure
                selection["feed_verification"] = None
                status_label.text = (
                    f"Status: {failure['status']} - {failure['error']}"
                )
                ui.notify(failure["error"], type="negative")

        async def verify():
            inspection = selection.get("inspection")
            if (
                not inspection
                or inspection.get("status") != "capabilities_inspected"
            ):
                ui.notify("Authenticate and inspect first", type="warning")
                return
            selected_profile = _selected_profile(
                inspection, profile_select.value
            )
            if not selected_profile:
                ui.notify("Select a media profile", type="warning")
                return

            rtsp_uri = _credentialed_uri(
                selected_profile["stream_uri"],
                username.value,
                password.value,
            )
            status_label.text = "Status: verifying_live_feed"
            verification = await asyncio.to_thread(
                verify_rtsp_feed, rtsp_uri
            )
            verification["profile_token"] = selected_profile["token"]
            selection["feed_verification"] = verification
            if verification["status"] != "verified_live_feed":
                include_checkbox.value = False
                include_checkbox.set_enabled(False)
                status_label.text = (
                    "Status: feed_verification_failed - "
                    f"{verification['error']}"
                )
                ui.notify(verification["error"], type="negative")
                return

            include_checkbox.set_enabled(True)
            status_label.text = (
                "Status: verified_live_feed - "
                f"{verification['frame_width']}x"
                f"{verification['frame_height']} frame received"
            )
            camera_id = _camera_id(candidate["name"])
            register_camera_callback(
                camera_id,
                rtsp_uri,
                onvif_host=candidate["host"],
                onvif_port=candidate["port"],
                onvif_username=username.value,
                onvif_password=password.value,
            )
            camera_options[camera_id] = camera_id
            camera_select.options = camera_options
            camera_select.update()
            rebuild_grid_callback()
            ui.notify(
                "Live frame verified and camera added to the dashboard",
                type="positive",
            )

        with ui.row().classes("gap-2"):
            ui.button(
                "Authenticate & Inspect", on_click=inspect
            ).props("dense color=primary")
            ui.button(
                "Verify Live Feed", on_click=verify
            ).props("dense color=secondary")

        selection.update(
            {
                "include": include_checkbox,
                "password_secret": password_secret,
                "profile": profile_select,
                "username_secret": username_secret,
            }
        )


def _camera_output(selection):
    inspection = selection.get("inspection")
    profile = None
    if inspection and inspection.get("status") == "capabilities_inspected":
        profile = _selected_profile(
            inspection, selection["profile"].value
        )
    candidate = selection["candidate"]
    include = selection.get("include")
    username_secret = selection.get("username_secret")
    password_secret = selection.get("password_secret")
    return {
        "selected": bool(getattr(include, "value", False)),
        "display_name": candidate["name"],
        "candidate": candidate,
        "device": inspection.get("device", {}) if inspection else {},
        "inspection": inspection,
        "selected_profile": profile,
        "feed_verification": selection.get("feed_verification"),
        "username_secret_name": getattr(username_secret, "value", None),
        "password_secret_name": getattr(password_secret, "value", None),
    }


def _selected_profile(inspection, token):
    return next(
        (
            profile
            for profile in inspection["profiles"]
            if profile["token"] == token
        ),
        None,
    )


def _credentialed_uri(uri, username, password):
    parsed = urlparse(uri)
    credentials = (
        f"{quote(username, safe='')}:{quote(password, safe='')}"
    )
    host = parsed.hostname or ""
    netloc = f"{credentials}@{host}:{parsed.port or 554}"
    return parsed._replace(netloc=netloc).geturl()


def _camera_id(value):
    return (
        value.lower()
        .replace(" ", "-")
        .replace("(", "")
        .replace(")", "")
    )


def _copy_proposal(path):
    ui.clipboard.write(path.read_text(encoding="utf-8"))
    ui.notify("Terraform proposal copied to the clipboard", type="positive")
