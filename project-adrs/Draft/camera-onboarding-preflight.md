# Camera Onboarding Preflight and Terraform Proposal

Date: **2026-10-08**

## Status

- [x] Draft
- [ ] Proposed
- [ ] Accepted
- [ ] Deprecated
- [ ] Superseded

## Decision

Provide camera onboarding as a deterministic preflight workflow in the ONVIF camera dashboard.
The workflow discovers candidates only within an engineer-approved network scope, authenticates
selected ONVIF devices, inspects their media profiles, verifies a selected RTSP stream by receiving
a decoded frame, and generates a reviewable Azure IoT Operations Terraform proposal.

Azure IoT Operations and Azure Device Registry remain the operational source of truth. The
preflight workflow does not maintain a parallel persistent camera registry and never applies
Terraform automatically.

## Context

Camera onboarding requires more evidence than an open network port or a vendor fingerprint.
Engineers need to distinguish an address that responded to a bounded probe from an authenticated
ONVIF device, inspected capabilities, and a stream that has delivered a usable frame.

The repository already contains an ONVIF camera dashboard, Azure IoT Operations Akri connector
templates, and authoritative Terraform types for namespaced devices and assets. A prose-only agent
that invents configuration from a broad discovery manifest would duplicate these contracts and
could produce stale or unsafe deployment values.

Camera discovery also handles confidential operational data, including IP addresses, device
identifiers, physical locations, and network topology. Credentials and credential-bearing stream
URLs must not enter generated files, logs, source control, or conversation history.

## Decision drivers

- Restrict all probing to an explicitly approved address, address and port, CIDR, range, or
  explicitly selected WS-Discovery multicast scope.
- Preserve distinct candidate, authentication, capability-inspection, and feed-verification states.
- Require a decoded RTSP frame before representing a selected profile as verified.
- Generate values that match the repository's current `namespaced_devices` and
  `namespaced_assets` Terraform types.
- Use credential secret references instead of usernames, passwords, tokens, or credential-bearing
  endpoint addresses.
- Keep generated evidence and proposals local and gitignored by default.
- Preserve the existing dashboard preview, manual camera addition, MQTT, and PTZ behavior.
- Keep generation deterministic and prevent duplicate logical resources.
- Avoid a second persistent registry or an automatic deployment path.

## Considered options

### Generate configuration through agent instructions only

This option was rejected because prose can drift from Terraform contracts, generate speculative
HCL, or omit required security checks. The agent may guide the workflow, but checked-in code must
perform discovery normalization, verification, sanitization, naming, deduplication, and rendering.

### Use a discovery manifest as the primary integration contract

This option was rejected as the deployment path. A broad multi-vendor manifest encourages
collection and persistence of data that Azure IoT Operations does not require and creates another
contract to maintain. Confidential discovery evidence remains a local diagnostic snapshot rather
than an operational registry or source-controlled deployment input.

### Treat an open TCP port as a discovered camera

This option was rejected because an open port does not prove that an endpoint is a camera, supports
ONVIF, accepts the supplied credentials, exposes a usable media profile, or delivers a live stream.
An open port is retained only as candidate evidence.

### Maintain a persistent onboarding registry

This option was rejected because it would duplicate Azure Device Registry and introduce
synchronization, drift, lifecycle, and credential-management concerns.

### Use custom Akri connectors for all vendor-specific discovery

This option was rejected for preflight-only enrichment. Lightweight, reviewed vendor adapters may
enrich approved-scope discovery when needed. A custom Akri connector is appropriate only when Azure
IoT Operations requires ongoing communication through a proprietary protocol.

### Implement a deterministic dashboard preflight

This option was selected because it reuses the existing operator interface and ONVIF integration,
keeps credentials in memory, supports engineer selection, verifies the actual media path, and
renders directly from current repository contracts.

## Decision Conclusion

The camera dashboard implements the following state progression:

1. `candidate` records bounded TCP or WS-Discovery evidence.
2. `unreachable` records an approved endpoint that did not accept a connection.
3. `unauthorized`, `unsupported`, and `unknown` preserve distinct inspection failures.
4. `capabilities_inspected` records successful ONVIF authentication and media profile retrieval.
5. `feed_verification_failed` records a selected RTSP profile that did not deliver a decoded frame.
6. `verified_live_feed` records a selected profile after a frame is received.

Multicast is never an implicit fallback. Target expansion is bounded and cannot exceed the
explicitly approved scope. Unknown adapter values remain unknown and are not converted to
unsupported capabilities.

Engineers may select a subset of verified cameras. Generation produces:

- `camera-discovery-results.json`, containing confidential evidence and sanitized errors; and
- `camera-onboarding.tfvars.example`, containing stable device and asset names, credential-free
  stream endpoints, Kubernetes secret references, selected profile metadata, and only inspected
  capabilities.

Both files are written under the component's gitignored `.camera-onboarding/` directory with
restricted local permissions. The Terraform proposal enables the native Akri Media connector and
matches the current full single-node blueprint and `111-assets` variable contracts. It is intended
for review and manual integration into the deployment workflow.

The Camera Onboarding custom agent points engineers to this deterministic implementation. It does
not generate alternate configuration, request credentials in chat, execute generated adapter code,
or apply infrastructure.

## Consequences

### Positive

- Engineers can validate discovery, authentication, capabilities, and live video before deployment.
- Network scanning is bounded by explicit approval, with multicast requiring a separate choice.
- Generated Terraform is deterministic, schema-aligned, credential-free, and reviewable.
- Azure IoT Operations remains the deployment and operational source of truth.
- Existing dashboard functionality remains available after onboarding.
- Failure states provide actionable diagnostics without treating candidates as confirmed cameras.

### Negative

- The preflight is ephemeral; restarting the dashboard requires discovery and selection to be
  repeated.
- Large approved scopes still generate network traffic, although probes are bounded and
  concurrency-limited.
- Feed verification depends on OpenCV and camera/network behavior and can fail because of codec,
  transport, latency, or firewall constraints.
- Secret objects referenced by the generated proposal must be provisioned separately.
- Vendor-specific capabilities remain unknown unless ONVIF exposes them or a reviewed enrichment
  adapter is added.

### Follow-up considerations

- Add reviewed vendor enrichment adapters only for demonstrated gaps in ONVIF preflight data.
- Add a custom Akri connector only when an ongoing proprietary protocol is required at runtime.
- Promote this ADR through the repository's Proposed and Accepted process after project review.
