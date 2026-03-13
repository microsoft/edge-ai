# Dual-Component Video Architecture for Recording and Live Streaming

Date: **2026-03-02** [Format=YYYY-MM-DD]

## Status

* [ ] Draft
* [ ] Proposed
* [x] Accepted
* [ ] Deprecated
* [ ] Superseded by NNNN

## Decision

Adopt a dual-component video architecture where the Media Capture Service (503) handles continuous recording, event-driven capture, and cloud archival while the Media Connector (508) handles live RTSP streaming, snapshots, and ONVIF camera management.

## Context

The industrial video surveillance pilot requires continuous 24/7 recording with cloud sync, event-driven capture with pre-event buffering, live video redistribution, and time-based video queries. Six limitations in the Media Connector prevent it from serving as the sole video capture component. A detailed analysis is documented in the solution ADR: [Dual-Component Video Architecture](../../docs/solution-adr-library/dual-component-video-architecture.md).

## Decision drivers

* Media Connector lacks continuous recording, ring buffer, and cloud sync capabilities
* Media Capture Service lacks live RTSP proxying and ONVIF camera management
* Each component excels in its domain without runtime dependency on the other
* Reduces operational surface area by using purpose-built components

## Considered options

* Single-component architecture using Media Connector only (rejected — 6 limitations)
* Single-component architecture using Media Capture Service only (rejected — no live streaming)
* Dual-component architecture with complementary responsibilities (selected)

## Decision Conclusion

Adopt the dual-component architecture. The Media Capture Service (503) handles all recording and cloud archival. The Media Connector (508) handles live RTSP streaming and ONVIF management.

## Consequences

* Two components must be deployed and configured independently
* Clear separation of concerns simplifies debugging and scaling
* Future video features route to the appropriate component based on capability
* Architecture pattern is documented and reusable via the solution ADR library
