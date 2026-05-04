---
title: End-to-End Leak Detection Pipeline Architecture for Edge AI
description: Architecture Decision Record for implementing a visual leak detection pipeline using Azure IoT Operations on the edge. Covers the end-to-end architecture from camera ingestion through on-site AI inference to cloud notification, with analysis of substitutable components including inference models, camera connectors, and notification channels.
author: Edge AI Team
ms.date: 2026-03-09
ms.topic: architecture
estimated_reading_time: 15
keywords:
  - leak-detection
  - edge-ai
  - azure-iot-operations
  - inference-pipeline
  - onnx
  - yolov8
  - sse-connector
  - media-connector
  - onvif
  - rtsp
  - mqtt-broker
  - eventhub
  - notification
  - logic-app
  - oil-and-gas
  - energy-utilities
  - computer-vision
  - architecture-decision-record
  - adr
---

## Status

- [X] Draft
- [ ] Proposed
- [ ] Accepted
- [ ] Deprecated

## Context

Pipeline operators in oil & gas, water utilities, and industrial facilities require continuous, real-time visibility into infrastructure integrity.
Manual inspections are infrequent, cover limited ground, and miss slow-developing leaks.
A single major leak event can cost $100M+ in remediation, fines, and reputational damage.
Operators need to detect leaks faster, respond before incidents escalate, and demonstrate regulatory compliance — all while working within the constraints of remote sites with intermittent connectivity, limited compute, and harsh physical environments.

The Edge AI accelerator provides reusable infrastructure components for building edge AI solutions on Azure IoT Operations.
This ADR documents how those components are composed into an end-to-end leak detection pipeline — and where the architecture supports substitution so that Forward Deployment Engineers (FDEs) can adapt the pipeline to customer-specific requirements.

### Business Drivers

The following drivers shape the architecture (sourced from BDR-001):

- **Detect leaks faster**: Reduce mean time to detection by ~70% compared to manual inspection cycles
- **Operate without cloud dependency**: Core detection and alerting must function on-site with no cloud round-trip
- **Support model flexibility**: Operators may bring their own models or require vendor-neutral model hosting
- **Accommodate diverse camera setups**: Deployment sites vary in camera types, protocols, and capabilities
- **Build operator trust**: Every alert must include visual evidence (timestamp, camera ID, bounding box, confidence score)
- **Enable manage-by-exception**: Replace routine site visits with continuous AI-based monitoring and Remote Operations Centre awareness

### Product Design Constraints

The PDR-001 defines the accelerator as a **narrow, opinionated inference pipeline** — from camera frame to alert — with explicit extensibility points where customers integrate, replace, or extend capabilities. The accelerator owns the detection path; severity classification, escalation, dispatch, and compliance are customer-owned.

### Scope

This ADR addresses the architectural question:

> **How should an FDE architect a visual leak detection pipeline using Azure IoT Operations on the edge, given that the inference model, camera ingestion method, and notification channel are substitutable?**

The decision covers five pipeline layers:

1. **Camera ingestion** — How camera feeds enter the system
2. **On-site inference** — How frames are processed for leak detection
3. **On-site messaging** — How components communicate on the edge
4. **Cloud routing** — How detection events reach cloud services
5. **Notification** — How operators are alerted

This ADR is scoped to **single-node deployments** — one Kubernetes cluster per site running all pipeline components on a single VM. Multi-site and multi-node deployment topologies require additional triage and are not covered here.

## Decision

Implement the leak detection pipeline as a five-layer architecture deployed on a single-node Azure IoT Operations cluster, where each layer is independently substitutable:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                         EDGE (On-Site)                                 │
│                                                                        │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────────┐  │
│  │  IP Camera   │    │  Analytics   │    │  Camera Simulator        │  │
│  │  (RTSP)      │    │  Camera (SSE)│    │  (ONVIF/RTSP)            │  │
│  └──────┬───────┘    └──────┬───────┘    └────────────┬─────────────┘  │
│         │                   │                         │                │
│         ▼                   ▼                         ▼                │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────────┐  │
│  │    Media      │    │     SSE      │    │       ONVIF              │  │
│  │  Connector    │    │  Connector   │    │     Connector            │  │
│  │  (508)        │    │  (509)       │    │     (510)                │  │
│  └──────┬───────┘    └──────┬───────┘    └────────────┬─────────────┘  │
│         │ Snapshots         │ Events                  │ Events         │
│         ▼                   ▼                         ▼                │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    AIO MQTT Broker (FC-03)                      │   │
│  │  Topics:                                                        │   │
│  │    snapshots/{site}/{camera}/image         (QoS 0)              │   │
│  │    events/{site}/{camera}/heartbeat        (QoS 0)              │   │
│  │    alerts/{site}/{camera}/leak/dlqc        (QoS 1)              │   │
│  │    alerts/{site}/{camera}/leak/basic       (QoS 1)              │   │
│  │    edge-ai/+/+/+/inference/onnx/#          (QoS 1)              │   │
│  └──────────────────────────┬──────────────────────────────────────┘   │
│                             │                                          │
│         ┌───────────────────┼────────────────────┐                     │
│         ▼                   │                    ▼                     │
│  ┌──────────────┐           │           ┌──────────────────────────┐   │
│  │  AI Edge     │           │           │  Media Capture Service   │   │
│  │  Inference   │           │           │  (503)                   │   │
│  │  (507)       │           │           │  Evidence snapshots      │   │
│  │  ONNX model  │           │           │  → ACSA cloud storage    │   │
│  └──────┬───────┘           │           └──────────────────────────┘   │
│         │ Detection results │                                          │
│         ▼                   │                                          │
│  ┌──────────────────────────┴──────────────────────────────────────┐   │
│  │                 AIO Dataflow Engine                              │   │
│  │  EventHub dataflows:  edge-ai/+/+/+/inference/onnx/#            │   │
│  └──────────────────────────┬──────────────────────────────────────┘   │
│                             │                                          │
└─────────────────────────────┼──────────────────────────────────────────┘
                              │ Detection events
                              ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         CLOUD (Azure)                                  │
│                                                                        │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────────┐  │
│  │  Azure       │    │  Logic App   │    │  Azure Blob Storage      │  │
│  │  Event Hub   │───▶│  (Stateful   │    │  (Evidence snapshots)    │  │
│  │              │    │  dedup)      │    │                          │  │
│  └──────────────┘    └──────┬───────┘    └──────────────────────────┘  │
│                             │                                          │
│                             ▼                                          │
│                      ┌──────────────┐                                  │
│                      │  Microsoft   │                                  │
│                      │  Teams       │                                  │
│                      │  (Alert)     │                                  │
│                      └──────────────┘                                  │
│                                                                        │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Observability: Grafana · Log Analytics · Azure Monitor         │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### Reference Implementation

The `blueprints/full-single-node-cluster` blueprint (applied with `leak-detection.tfvars.example`) implements this architecture using:

| Layer             | Reference Implementation                                                 | Component                                         |
|-------------------|--------------------------------------------------------------------------|---------------------------------------------------|
| Camera ingestion  | ONVIF Camera Simulator (simulated RTSP) + Media Connector (snapshotting) | onvif-camera-simulator, 503-media-capture-service |
| On-site inference | AI Edge Inference with YOLOv8n ONNX model (server-side)                  | 507-ai-inference                                  |
| On-site messaging | AIO MQTT Broker with structured topic hierarchy                          | 110-iot-ops                                       |
| Cloud routing     | AIO EventHub Dataflows                                                   | 130-messaging                                     |
| Notification      | Logic App → Microsoft Teams with Table Storage deduplication             | 045-notification                                  |

The current end-to-end pipeline uses a **simulated RTSP camera** — the ONVIF Camera Simulator — which produces real H.264 RTSP streams from JPEG or MP4 sources.
The Media Connector ingests these RTSP streams, extracts JPEG snapshots at a configurable interval, and publishes them to the MQTT broker for server-side inference by the AI Edge Inference service.
The SSE Connector (509-sse-connector) is also deployed and available as an alternative ingestion path for analytics cameras with onboard inference, but the primary detection flow runs through RTSP snapshotting.

### Substitutable Components

The architecture is designed so that each layer can be swapped independently. The MQTT broker is the integration backbone — components are decoupled through well-defined topic contracts.

## Decision Drivers

1. **Cloud independence for core detection** (TR-01): The on-site pipeline must detect leaks and produce alerts without any cloud connectivity. Cloud is used for notification routing and analytics, not for detection.
2. **Component modularity** (NFR-07, PDR EXT-01 through EXT-08): Each pipeline stage must be independently replaceable so FDEs can adapt to customer camera types, model preferences, and notification requirements.
3. **Operator trust through visual evidence** (BDR §4): Every detection event must carry a timestamp, camera ID, detection type, confidence score, and snapshot with bounding box overlay.
4. **Latency within seconds** (NFR-01): Detection results must be produced within seconds of snapshot extraction, bounded by model inference time.
5. **Alert deduplication** (BDR Q4): A continuous leak must generate a single actionable alert, not repeated notifications. Alert state management (open / acknowledged / closed) prevents operator fatigue.
6. **Disconnected resilience** (NFR-04): If cloud connectivity is lost, detection continues on-site; alerts queue and deliver when connectivity resumes.

## Considered Options

### Layer 1: Camera Ingestion

#### Option A: Media Connector with RTSP Cameras (Server-Side Inference)

The AIO Media Connector ingests RTSP streams from commodity IP cameras, extracts JPEG snapshots at a configurable interval (default ~5 seconds), and publishes them to MQTT for server-side inference.

**Pros:**

- Works with any RTSP-capable IP camera (widest hardware compatibility)
- Proven integration pattern with AIO MQTT broker
- Snapshot interval is configurable; adaptive intervals possible
- Decoupled from inference — multiple models can consume the same snapshot stream
- Camera simulator available for development and demonstration

**Cons:**

- Latency limited by snapshot interval (0.5–5 seconds between frames)
- Snapshots may miss fast events occurring between capture intervals
- Higher network bandwidth for JPEG image payloads over MQTT
- Server-side compute bears full inference load

**Best fit:** Sites with commodity RTSP cameras and no onboard analytics capability. Most common deployment scenario.

#### Option B: SSE Connector with Analytics Cameras (Camera-Side Inference)

The SSE Connector maintains a persistent HTTP connection to analytics cameras that perform onboard inference and emit detection events via Server-Sent Events. The connector maps SSE event types (HEARTBEAT, ALERT, ALERT_DLQC) to MQTT topics.

**Pros:**

- Near-real-time event delivery (sub-second latency)
- Camera performs inference — reduces edge compute requirements
- Structured event types (HEARTBEAT, ALERT, ALERT_DLQC) with well-defined schemas
- Lower network bandwidth (events, not images)
- Automatic reconnection with built-in SSE retry

**Cons:**

- Requires analytics cameras with onboard inference and SSE endpoint (limited hardware selection)
- Camera vendor controls the detection model and confidence thresholds
- Less flexibility to run custom models server-side
- SSE is unidirectional (server to client only)

**Best fit:** Sites with analytics cameras that have onboard leak detection models and SSE capability.

#### Option C: ONVIF Connector with PTZ Cameras

The ONVIF Connector discovers ONVIF-compliant cameras, subscribes to camera events (motion, tampering), controls PTZ operations, and retrieves media stream URIs. Events are published to MQTT.

**Pros:**

- Standardised protocol (ONVIF Profile S/T) reduces vendor lock-in
- Device discovery and capability introspection
- PTZ control enables dynamic camera positioning in response to detected events
- Event subscription for motion detection and alarms

**Cons:**

- ONVIF event types (motion, tampering) are generic — not leak-specific
- Still requires server-side inference for leak detection
- More complex integration (SOAP-based protocol)
- Not all cameras support the required ONVIF profiles

**Best fit:** Sites with ONVIF-compliant pan-tilt-zoom cameras where dynamic repositioning adds value to the detection workflow.

#### Selected Approach: Option A (RTSP + Media Connector) as Primary Detection Path

The leak detection scenario uses a **simulated RTSP camera** (ONVIF Camera Simulator) with the **Media Connector for snapshotting** as the primary detection path.
The Media Connector extracts JPEG snapshots from the RTSP stream and publishes them to MQTT, where the AI Edge Inference service performs server-side leak detection.
The SSE Connector is deployed alongside as an alternative ingestion path for analytics cameras with onboard detection, but the current end-to-end pipeline exercises the RTSP → snapshot → server-side inference flow.

FDEs should select the ingestion path based on customer camera capabilities:

- **Commodity RTSP cameras** (most common): Use Option A for detection and evidence capture — this is the path the reference scenario demonstrates
- **Analytics cameras with SSE**: Use Option B for detection events, Option A for post-event evidence capture
- **ONVIF cameras**: Use Option C for discovery and PTZ, combined with Option A for frame extraction

### Layer 2: On-Site Inference

#### Option A: ONNX Runtime with YOLOv8 (Reference Implementation)

AI Edge Inference service subscribes to MQTT snapshot topics, runs frames through a YOLOv8n ONNX model, and publishes detection results (bounding box, confidence, detection type) back to MQTT.

**Pros:**

- ONNX is vendor-neutral and runs on CPU, GPU, or NPU via execution providers
- YOLOv8n is optimised for edge deployment (small model size, fast inference)
- Well-defined model interface contract (input: JPEG image → output: detection JSON)
- Model swap via container redeployment or PVC-based model loading
- Sample water leak detection model provided for demonstration

**Cons:**

- General-purpose object detection; not optimised for specific leak types without fine-tuning
- CPU-only inference on standard edge hardware (no GPU acceleration in reference VM)
- Single-model architecture; multi-model requires additional inference instances

**Best fit:** Most deployments. YOLOv8n provides a strong baseline; customers fine-tune or replace with domain-specific models.

#### Option B: Analytics Camera Onboard Inference

Analytics cameras with embedded AI chipsets perform inference on-device and emit structured detection events directly. No server-side inference is required.

**Pros:**

- Zero server-side compute for inference
- Camera vendor optimises model for their hardware (dedicated NPU/VPU)
- Lower latency (no frame transfer to server)
- Scales naturally with camera count (each camera is self-contained)

**Cons:**

- Camera vendor controls the model; limited flexibility to run custom models
- Detection quality depends on vendor's training data and model updates
- Vendor lock-in for inference capability
- Difficult to run multi-model pipelines or ensemble approaches

**Best fit:** Sites where the camera vendor provides a validated leak detection model and the operator accepts vendor-managed inference.

#### Option C: Multi-Model Pipeline (Parallel Inference)

Multiple inference instances subscribe to the same MQTT snapshot stream, each running a different model (e.g., liquid leak detection + gas plume detection + flame detection).

**Pros:**

- Detects multiple hazard types simultaneously
- Models can be developed and updated independently
- Confidence scoring across models enables multi-signal correlation
- Supports the BDR target of up to 85% false positive reduction through correlation

**Cons:**

- Linear increase in compute requirements per model
- Results aggregation logic required (customer-owned)
- More complex deployment and monitoring
- Resource contention on constrained edge hardware

**Best fit:** Sites with sufficient compute capacity and multi-hazard detection requirements. Extends Option A with additional model instances.

#### Selected Approach: Option A (ONNX/YOLOv8) as Reference

The reference scenario provides a YOLOv8n ONNX model as the default implementation. The model interface contract — input image format, output schema (detection flag, type, bounding box, confidence), and ONNX packaging — enables customers to substitute their own models (EXT-01). FDEs deploy the sample model for initial demonstration and guide customers through model replacement.

### Layer 3: On-Site Messaging

The AIO MQTT Broker is the only considered option. It is the messaging backbone of Azure IoT Operations, operates entirely on-site with no cloud dependency, and provides the decoupling point between all pipeline components. Topic structure follows the UNS (Unified Namespace) pattern established in the accelerator.

### Layer 4: Cloud Routing

#### Option A: EventHub Dataflows (Reference Implementation)

AIO Dataflow Engine routes detection results from MQTT topics to Azure Event Hub for cloud-side processing. EventHub provides high-throughput event ingestion, consumer group isolation, and integration with downstream Azure services.

**Pros:**

- High throughput and built-in partitioning
- Consumer groups enable multiple downstream subscribers without contention
- Native integration with Logic Apps, Azure Functions, Stream Analytics, and Fabric RTI
- Retention period configurable for replay and reprocessing

**Cons:**

- Requires Event Hub namespace provisioning and management
- Cost scales with throughput units and retention
- Not bidirectional (cloud-to-edge commands require a separate channel)

#### Option B: EventGrid Dataflows

AIO Dataflow Engine routes detection results to Azure Event Grid for event-driven cloud processing.

**Pros:**

- Native event routing with filtering and fan-out
- Pay-per-event pricing for low-volume workloads
- Built-in dead-lettering and retry

**Cons:**

- Lower throughput ceiling than EventHub for high-volume streams
- Less suited for ordered event processing
- Filtering and routing logic adds complexity

#### Selected Approach: Option A (EventHub Dataflows)

EventHub Dataflows are the reference implementation. The reference scenario explicitly disables EventGrid dataflows. FDEs may enable EventGrid for customers who need event-driven fan-out to multiple Azure services or prefer pay-per-event pricing.

### Layer 5: Notification

#### Option A: Logic App → Microsoft Teams (Reference Implementation)

A Logic App triggered by EventHub receives detection events, checks alert state in Azure Table Storage to deduplicate ongoing leaks, and delivers alerts to a Microsoft Teams channel with timestamp, camera ID, detection type, confidence score, and snapshot image.

**Pros:**

- Low-code integration with Teams (familiar to operators)
- Stateful deduplication prevents alert fatigue from continuous leaks
- "Close leak" action re-arms alerting per camera
- Evidence snapshots persisted to Azure Blob Storage
- No custom code required for the notification path

**Cons:**

- Teams dependency (not suitable for organisations without Microsoft 365)
- Logic App execution latency adds seconds to notification delivery
- Alert payload limited by Teams message card format
- Logic App pricing based on connector executions

**Best fit:** Organisations using Microsoft Teams as their collaboration platform.

#### Option B: Azure Functions → Email / SMS

An Azure Function triggered by EventHub processes detection events and delivers notifications via SendGrid (email), Twilio (SMS), or other programmable communication APIs.

**Pros:**

- Flexible delivery targets (email, SMS, push notification, webhook)
- Full programmatic control over alert formatting and routing
- Lower per-execution cost than Logic App for high volumes

**Cons:**

- Requires custom code development and maintenance
- Third-party service dependencies (SendGrid, Twilio)
- Alert deduplication must be implemented in code
- No visual low-code designer

**Best fit:** Organisations needing multi-channel notification or not using Microsoft Teams.

#### Option C: Direct SCADA / Process Control Integration

Detection events routed from EventHub (or directly from MQTT via edge gateway) into existing process control systems (SCADA, DCS, historian).

**Pros:**

- Integrates into the operator's existing operational workflow
- No new notification tool for operators to learn
- Enables automated response (e.g., valve closure, pump shutdown)

**Cons:**

- Requires site-specific SCADA integration (OPC UA, Modbus, proprietary APIs)
- Integration complexity varies significantly by customer
- Security boundaries between IT and OT networks complicate deployment
- Not provided by the accelerator; customer-owned integration

**Best fit:** Mature operations with existing SCADA infrastructure and defined automated response procedures.

#### Selected Approach: Option A (Logic App → Teams) as Reference

The reference scenario provides Teams notification with stateful deduplication. FDEs guide customers to extend or replace the notification target (EXT-02) based on their operational tools and collaboration platform.

## Decision Conclusion

The leak detection pipeline architecture uses a **layered, MQTT-brokered design** where each layer is decoupled through topic contracts and independently substitutable. The reference implementation is realized as a *scenario* on top of `blueprints/full-single-node-cluster` (using `leak-detection.tfvars.example`) and provides an opinionated starting point:

| Layer            | Reference Choice                                       | Substitution Guidance                                                                     |
|------------------|--------------------------------------------------------|-------------------------------------------------------------------------------------------|
| Camera ingestion | RTSP Camera Simulator + Media Connector (snapshotting) | Swap to SSE Connector (analytics cameras) or ONVIF Connector based on camera capabilities |
| Inference        | YOLOv8n ONNX model via AI Edge Inference               | Replace ONNX model file; conform to model interface contract (EXT-01)                     |
| Messaging        | AIO MQTT Broker                                        | Not substitutable — foundational to Azure IoT Operations                                  |
| Cloud routing    | EventHub Dataflows                                     | Enable EventGrid Dataflows for event-driven fan-out scenarios                             |
| Notification     | Logic App → Teams (stateful dedup)                     | Replace with Azure Functions, SCADA integration, or custom webhook (EXT-02)               |

### Key Architectural Principles

1. **MQTT as the integration backbone**: All on-site components communicate through the AIO MQTT Broker. This decoupling enables independent deployment, scaling, and replacement of pipeline stages.
2. **Cloud-independent detection**: The on-site pipeline (camera → MQTT → inference → MQTT) operates without cloud connectivity. Cloud services handle notification routing and analytics — not detection.
3. **Model interface contract over model lock-in**: The inference service defines an input/output contract (JPEG in, detection JSON out). Any ONNX model conforming to this contract can be deployed without changing the pipeline.
4. **Alert deduplication at the notification layer**: Stateful deduplication in the Logic App (or customer equivalent) ensures one alert per leak event, with explicit close/re-arm actions. This directly addresses the operator trust condition of minimal false alarms.
5. **Evidence capture alongside detection**: Media Capture Service persists snapshot evidence to ACSA-backed cloud storage, providing visual proof independent of the alert delivery mechanism.

## Consequences

### Positive

- **FDEs can adapt to customer environments** without rearchitecting the pipeline — swap camera connectors, replace inference models, or redirect notifications independently
- **Detection operates without cloud** — sites with intermittent connectivity maintain continuous monitoring
- **Sample model accelerates time to demo** — ≤ 2 weeks from engagement start to working demonstration (BDR target)
- **Visual evidence in every alert** builds operator trust — timestamp, camera, bounding box, confidence, and snapshot image
- **Stateful deduplication** prevents alert fatigue from continuous leaks
- **Observability stack** (Grafana, Log Analytics, Azure Monitor) provides system health visibility from day one

### Negative

- **Sample model is not production-grade** — customers must bring their own trained model for production deployment; model training and lifecycle management are out of scope
- **Teams notification is a starting point** — operators using SCADA, email, or SMS must implement their own notification integration (EXT-02)
- **Single-node cluster limits** — the reference implementation targets a single VM; multi-camera deployments exceeding hardware capacity require scaling guidance; multi-site deployment topology requires further triage
- **Severity classification is customer-owned** — the accelerator produces a confidence score but does not map it to green/yellow/red thresholds (EXT-03)
- **No real-time video streaming** — the pipeline processes snapshots, not live video; real-time streaming for ROC verification is a desirable capability not included in the initial delivery

### Neutral

- **Multi-model pipelines** are supported architecturally (multiple inference instances subscribing to the same MQTT topics) but not implemented in the reference scenario
- **Edge-local event storage** is an open question (PDR OQ-04) — currently detection events are persisted only when they reach cloud; fully disconnected audit review requires additional implementation

## References

- [full-single-node-cluster blueprint (host of the leak detection scenario)](../../blueprints/full-single-node-cluster/README.md)

## Related ADRs

- [SSE Connector for Real-Time Event Streaming](./sse-connector-real-time-event-streaming.md)
- [Edge Video Streaming and Image Capture](./edge-video-streaming-and-image-capture.md)
- [ONVIF Connector for IP Camera Integration](./onvif-connector-camera-integration.md)
- [AI Edge Inference Dual Backend Architecture](./ai-edge-inference-dual-backend-architecture.md)
- [UNS Asset Metadata Topic Structure](./uns-asset-metadata-topic-structure.md)
