---
description: 'RPI research topic from DT Solution Space for Camera Onboarding Agent in microsoft/edge-ai'
---
<!-- markdownlint-disable-file -->

# Research Topic: Camera Onboarding Agent for Edge AI Applications

## Research Topic

The camera-discovery skill (hve-core) produces a 25-field YAML manifest per camera. Today, engineers manually translate this manifest into app-specific configuration for each 500-level edge application (508-media-connector, 510-onvif-connector, 515-camera-dashboard). No automation exists.

**Research question:** What configuration does each target 500-level app require to onboard a camera, and how should an onboarding agent map discovery manifest fields to each app's config format?

**Validated directions:**
- Pluggable output generator pattern (one generator per target app)
- Agent lives in microsoft/edge-ai repo alongside the apps
- Consumes the standard camera discovery manifest YAML as input
- Azure IoT Operations is the platform layer

**What remains uncertain:**
- Exact config schemas for 508, 510, 515 (and other relevant apps)
- Whether Azure IoT Operations has a native asset onboarding API the agent should target
- Credential handling between discovery manifest and deployed configs
- Whether apps support hot-reload or require restart

## Known Constraints

### Environmental

- Each 500-level app has its own configuration format (no shared standard) — **Blocker**: the agent must handle N distinct output formats
- Azure IoT Operations is the underlying platform layer
- Agent lives in microsoft/edge-ai repository alongside target apps
- Apps are containerized with Docker, deployed via Helm charts

### Workflow

- No existing onboarding automation — this is greenfield
- Single vendor per site, but workflow must be vendor-agnostic across projects
- Engineers provision 3-100 cameras per site

## Observed Context

- Engineers' first priority is always "connect to known IP and confirm the feed works" via RTSP URL
- The discovery manifest serves as both human confirmation (RTSP URL visible) and machine contract (edge tools ingest it)
- The manifest is positioned as step one of a multi-step onboarding journey that doesn't yet exist
- Full 25-field manifest in a single run is preferred — no partial or quick modes needed

## Investigation Priorities

| Priority | Item | Rationale |
|---|---|---|
| 1 | Config schema for 508-media-connector | Primary camera integration point — what env vars, Helm values, or config files does it need per camera? |
| 2 | Config schema for 510-onvif-connector | ONVIF-specific camera connection — overlaps with discovery ONVIF adapter output |
| 3 | Config schema for 515-camera-dashboard | RTSP feed display — likely simplest mapping (URL + label) |
| 4 | Azure IoT Operations asset definition API | Does the platform provide a standard way to register cameras as managed assets? |
| 5 | Credential flow from manifest to app configs | How are RTSP credentials securely passed without appearing in plaintext configs? |
| 6 | Hot-reload capability of target apps | Can config be updated without container restart? Affects onboarding UX |
| 7 | Feasibility of shared config standard across apps | Would a common camera config schema reduce agent complexity? |

## DT Artifact Paths

- `.copilot-tracking/dt/camera-discovery/coaching-state.md` — DT session state with full progression
- `.copilot-tracking/dt/camera-discovery/01-scope-statement.md` — Consumer-driven manifest schema rationale
- `.copilot-tracking/dt/camera-discovery/01-architecture-concept.md` — Adapter pattern architecture
- `.copilot-tracking/dt/camera-discovery/handoff-solution-space.md` — Full Solution Space exit artifact with constraints and assumptions
- `.github/skills/experimental/camera-discovery/SKILL.md` — Discovery skill documentation with manifest format
- `.github/skills/experimental/camera-discovery/scripts/adapters/base.py` — VendorAdapter contract (reference for output generator pattern)

## Target Repository

`https://github.com/microsoft/edge-ai/tree/main/src/500-application`

Key directories to investigate:
- `508-media-connector/` — Akri media connector for camera integration
- `510-onvif-connector/` — ONVIF connector for IP camera integration
- `515-camera-dashboard/` — Web dashboard for RTSP feeds with PTZ control
