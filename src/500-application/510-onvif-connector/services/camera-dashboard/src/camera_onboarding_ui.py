"""NiceGUI controls for explicit, review-only camera onboarding."""

import asyncio

from camera_onboarding import CameraOnboarding, OnboardingError, generate_proposal
from nicegui import ui


def render_camera_onboarding(device, username, password):
    """Render one candidate without modifying preview cameras on any failure."""
    host = device["host"]
    if ":" in host:
        host = f"[{host}]"
    state = CameraOnboarding(
        f'http://{host}:{device["port"]}/onvif/device_service', device["name"],
    )
    ui.label("Asset proposal preflight (separate from preview)").classes("text-subtitle2")
    endpoint = ui.input("ONVIF endpoint", value=state.endpoint).classes("w-full")
    display_name = ui.input("Asset display name", value=state.display_name).classes("w-full")
    selected = ui.checkbox("Include camera in proposal", value=False)
    status = ui.label("Candidate: inspect, select a profile, then verify a decoded frame.")
    profile = ui.select({}, label="Inspected media profile", value=None).classes("w-full")
    stream_uri = ui.input("Selected RTSP URI").classes("w-full")
    topic = ui.input("Snapshot MQTT topic", placeholder="Required publish topic").classes("w-full")
    rate = ui.input("Snapshots per second", placeholder="Required positive finite number")
    username_secret = ui.input("Username secret/key", placeholder="camera-auth/username")
    password_secret = ui.input("Password secret/key", placeholder="camera-auth/password")

    def sync_connection(_event=None):
        state.edit_connection(endpoint.value, username.value, password.value)
        profile.options = {item["token"]: item["name"] for item in state.profiles}
        profile.update()
        if not state.profile:
            profile.value = None
            stream_uri.value = ""
        status.set_text(f"Status: {state.status}")

    for control in (endpoint, username, password):
        control.on_value_change(sync_connection)

    def select_profile(event):
        match = next((item for item in state.profiles if item["token"] == event.value), None)
        if match:
            state.edit_profile(match["token"], match["name"], match["stream_uri"])
            stream_uri.value = match["stream_uri"]
        else:
            state.profile = None
            state._invalidate()
        status.set_text(f"Status: {state.status}")

    def edit_uri(event):
        if state.profile:
            state.edit_profile(state.profile["token"], state.profile["name"], event.value)
        else:
            state._invalidate()
        status.set_text(f"Status: {state.status}")

    profile.on_value_change(select_profile)
    stream_uri.on_value_change(edit_uri)

    async def inspect():
        sync_connection()
        profile.value = None
        stream_uri.value = ""
        try:
            if await state.inspect():
                profile.options = {item["token"]: item["name"] for item in state.profiles}
                profile.update()
                ui.notify("ONVIF inspected. Explicitly select a media profile.", type="positive")
            else:
                ui.notify("Inspection failed or inputs changed; inspect the current endpoint again.", type="warning")
        except asyncio.CancelledError:
            raise
        finally:
            status.set_text(f"Status: {state.status}")

    async def verify():
        sync_connection()
        try:
            verified = await state.verify()
            ui.notify(
                "Decoded frame verified (point-in-time only)." if verified
                else "Frame verification failed or inputs changed.",
                type="positive" if verified else "warning",
            )
        except OnboardingError as error:
            ui.notify(str(error), type="warning")
        except asyncio.CancelledError:
            raise
        except Exception:
            ui.notify("Frame decoder failed; existing preview cameras are unchanged.", type="negative")
        finally:
            status.set_text(f"Status: {state.status}")

    ui.button("Inspect ONVIF", on_click=inspect)
    ui.button("Verify decoded frame", on_click=verify)

    def proposal():
        sync_connection()
        state.selected = selected.value is True
        state.display_name = display_name.value
        if not state.selected:
            return None
        return state.proposal(topic.value, rate.value, username_secret.value, password_secret.value)

    return proposal


def render_proposal_export(proposals):
    """Export only explicitly selected, verified candidates through the fixed CLI."""
    output = ui.input("New private output directory", placeholder="Existing parent/new-directory")
    running = {"task": None}

    async def generate():
        if running["task"] is not None:
            ui.notify("Proposal generation is already running.", type="warning")
            return
        running["task"] = asyncio.current_task()
        try:
            cameras = [camera for proposal in proposals if (camera := proposal()) is not None]
            if not cameras:
                raise OnboardingError("incomplete", "Explicitly select at least one verified camera")
            if not output.value.strip():
                raise OnboardingError("filesystem", "Enter a new private output directory")
            result = await generate_proposal(cameras, output.value)
            ui.notify(
                f'Private proposal written: {result["tfvars_path"]}. Review before deployment.',
                type="positive",
            )
        except OnboardingError as error:
            ui.notify(f"{error.code}: {error}", type="negative")
        except asyncio.CancelledError:
            ui.notify("Proposal generation cancelled; check for partial private output.", type="warning")
            raise
        except Exception:
            ui.notify("Proposal generation failed; existing preview cameras are unchanged.", type="negative")
        finally:
            running["task"] = None

    def cancel():
        if running["task"] is not None:
            running["task"].cancel()

    ui.label(
        "Frame verification is not MQTT ingestion evidence. No assets are deployed by this workflow."
    ).classes("text-caption")
    ui.button("Generate asset proposal", on_click=generate)
    ui.button("Cancel proposal generation", on_click=cancel)
