---
exit_point: "concept-validated"
dt_method: 6
dt_space: "solution"
handoff_target: "researcher"
date: "2026-05-26"
---
<!-- markdownlint-disable-file -->

# Solution Space Exit Handoff: Camera Discovery → Onboarding Agent

## Artifacts

| Path | Type | Confidence |
|---|---|---|
| .copilot-tracking/dt/camera-discovery/01-scope-statement.md | scope-statement | validated |
| .copilot-tracking/dt/camera-discovery/01-architecture-concept.md | concept-sketch | validated |
| .github/skills/experimental/camera-discovery/scripts/adapters/ | implementation | validated |
| .github/skills/experimental/camera-discovery/SKILL.md | documentation | validated |

## Validated Concept: Camera Onboarding Agent

**Location:** microsoft/edge-ai repository

**Purpose:** Consume the camera discovery manifest (YAML) and generate app-specific configuration for each deployed 500-level edge application, eliminating manual camera onboarding.

**Architecture:** Pluggable output generator pattern (mirrors the discovery adapter pattern):

- One input contract: camera discovery manifest
- Multiple output generators: one per target 500-level app
- Target apps: 508-media-connector, 510-onvif-connector, 515-camera-dashboard (and others as needed)

**User journey:** Run discovery (hve-core skill) → get manifest → onboarding agent generates configs → deploy to edge site

## Constraints

| Constraint | Source | Confidence | Category | Severity |
|---|---|---|---|---|
| Single vendor per site; multi-vendor across projects | User interview (DT coaching session) | validated | Workflow | Minor |
| Each 500-level app has its own config format (no shared standard) | User interview + GitHub repo analysis | validated | Environmental | Blocker |
| Azure IoT Operations is the platform layer | User interview | validated | Environmental | Minor |
| No existing onboarding automation | User interview | validated | Workflow | Blocker |
| Agent must live in edge-ai repo alongside apps it configures | User decision | validated | Environmental | Minor |
| Discovery manifest is the input contract (25-field YAML) | Implementation evidence | validated | Physical | Minor |

## Assumptions

| Assumption | Confidence | Status | Impact |
|---|---|---|---|
| Discovery manifest format is stable enough to build on | validated | validated | high |
| 500-level apps have documented/discoverable config schemas | assumed | untested | high |
| Pluggable output generator pattern scales to new apps | assumed | untested | medium |
| Engineers want full manifest (not partial/quick modes) | validated | validated | low |
| RTSP URL in manifest is sufficient for feed confirmation | validated | validated | low |
| Onboarding agent can read app README/env templates for schema discovery | assumed | untested | medium |

## Validated Patterns

| Pattern | Evidence |
|---|---|
| Engineers prioritize "connect and confirm feed" as first action | Direct user statement: "highest priority is to connect a camera at a known IP and check out its feed" |
| Consistent workflow across sites is the primary value of vendor abstraction | User confirmed portability across projects (not mixed-fleet) is the driver |
| Full 25-field discovery in one shot preferred over partial modes | User stated "better to have all the needed data from the full discovery" |
| Manifest serves as machine-readable contract for edge tools | User confirmed media connector and 500-level apps consume manifest data |
| Discovery manifest is step one of a multi-step onboarding journey | User stated "the discovery manifest is a first step to smooth camera onboarding" |

## Technical Unknowns

| Unknown | Priority | Source |
|---|---|---|
| Config format for each 500-level app (env vars, Helm values, MQTT topics) | high | Each app has its own format — needs per-app investigation |
| Azure IoT Operations asset definition schema for camera onboarding | high | Platform integration not yet mapped |
| Whether apps can hot-reload config or require restart after onboarding | medium | Deployment workflow unknown |
| How credentials flow from manifest to app configs securely | high | Security boundary between discovery and deployment |
| Whether a shared config standard across apps is feasible/desired | medium | Could simplify agent but requires cross-app coordination |
