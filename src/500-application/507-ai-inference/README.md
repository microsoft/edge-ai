---
title: AI Inference Service
description: Production-ready AI inference service with dual-backend machine learning capabilities for edge computing, supporting ONNX Runtime and Candle (pure Rust) inference engines with MQTT integration
author: Edge AI Team
ms.date: 2026-09-30
ms.topic: how-to
estimated_reading_time: 10
keywords:
  - ai inference
  - onnx runtime
  - candle
  - rust
  - mqtt
  - edge computing
  - azure iot operations
  - machine learning
  - docker compose
  - kubernetes
  - image snapshot schema
---

A production-ready AI inference service that provides dual-backend machine learning capabilities for edge computing environments. Supports both ONNX Runtime and Candle (pure Rust) inference engines with MQTT integration for real-time processing.

## Prerequisites

### For Development

**Recommended**: Use the provided VS Code devcontainer for the best development experience. The devcontainer includes all required tools and dependencies.

1. **Open in devcontainer**:
   - VS Code: Reopen the repository in the devcontainer when prompted
   - All tools (Rust, Docker, kubectl, etc.) are pre-installed

2. **Manual setup** (if not using devcontainer):
   - Docker and Docker Compose
   - Rust 1.89+ toolchain
   - Protocol Buffers compiler (`protoc`)
     - macOS: `brew install protobuf`
     - Ubuntu/Debian: `sudo apt-get install protobuf-compiler`
     - RHEL/Fedora: `sudo dnf install protobuf-devel`
   - MQTT broker (Mosquitto) for local testing

### For Production Deployment

- Azure IoT Operations cluster (compatible with version in main branch)
- Azure Container Registry access
- kubectl configured for your cluster

For complete getting started guide, see the [main repository documentation](../../../docs/getting-started/).

## Architecture Overview

This component implements a scalable AI inference service designed for industrial edge computing scenarios. It features:

- **Dual Backend Support**: ONNX Runtime (220ms avg) and Candle (155ms avg) inference engines
- **MQTT Integration**: Azure IoT Operations SDK with enhanced connection resilience
- **Real-time Processing**: Optimized inference times for edge deployment, averaging 220ms for ONNX Runtime and 155ms for Candle
- **Production Ready**: 24.8MB container size with comprehensive monitoring

## Directory Structure

```text
507-ai-inference/
├── docker-compose.yaml          # Local development environment
├── services/                    # Service implementations
│   ├── ai-edge-inference/       # Main inference service (Rust)
│   ├── ai-edge-inference-crate/ # Shared Rust crate
│   ├── snapshot-normalizer/     # MQTT snapshot adapter (Rust)
│   └── snapshot-normalizer-core/ # Snapshot normalization library (Rust)
├── charts/                      # Kubernetes deployment manifests
│   ├── base/                    # Base Kubernetes resources
│   ├── snapshot-normalizer/     # Helm chart for the snapshot adapter
│   └── model-downloader-job.yaml
└── resources/                   # Configuration and model files
    ├── model_configs/           # Model configuration files
    ├── models/                  # ML model files (if present)
    ├── schemas/                 # Published message contracts
    └── mosquitto.conf           # MQTT broker configuration
```

## Snapshot Normalizer Core

`services/snapshot-normalizer-core/` is a standalone Rust **library crate**. It
is not a service, not a container, and not a deployable unit. It builds the
canonical `image_snapshot` v1 request value from raw JPEG bytes and does
nothing else.

### What the library does

- Classifies a byte slice as JPEG by its start-of-image marker prefix
- Applies caller-supplied maxima to the raw payload and to the serialized envelope
- Base64-encodes the payload with the standard, padded alphabet
- Builds and serializes the canonical envelope value
- Offers a fixed-capacity recent-hash duplicate detector, a byte-free FNV-1a 64-bit payload digest, and a fixed-cardinality counter set

Envelope construction is pure: it reads no clock, draws no randomness, performs
no input or output, and depends on no transport. The same input always yields
the same envelope.

### Non-goals and limits

- **MQTT and any other transport are out of scope.** The crate publishes nothing, subscribes to nothing, and links no transport client.
- **Topic-derived identity is out of scope.** `camera_id` and `device_name` are opaque caller-supplied strings. Nothing is parsed out of a topic, and the envelope carries no `source_topic`.
- No camera is acquired, opened, or driven by this crate; the caller supplies bytes that are already in memory.
- No character-set check and no length bound are applied to identifiers.
- No size bound is baked in. `SizeLimits` holds caller-supplied maxima, so the crate stays deployment-neutral. A length equal to a maximum is accepted; only a greater length is rejected.
- Payload digests are not a cryptographic commitment and payload bytes are never stored or logged.

### Published contract

The emitted value is defined by
[`resources/schemas/image-snapshot-v1.schema.json`](resources/schemas/image-snapshot-v1.schema.json).

Required: `message_type` (constant `image_snapshot`), `schema_version`,
`camera_id`, `timestamp` (integer epoch seconds), `image_data` (standard-alphabet
Base64), `device_name`.

Optional and emitted when supplied: `metadata` (free-form object) and
`correlation_id` (string). Both are omitted when absent rather than emitted as
`null`.

Optional and never emitted by this producer: `location`, a
`[latitude, longitude]` pair reserved in the contract so consumers keep
accepting envelopes from other producers.

The schema sets `additionalProperties: true`. Readers are tolerant: unknown
members are accepted and discarded rather than rejected, so a later field
addition stays non-breaking. The schema documents recommended bounds of 4 MiB
maximum raw JPEG and 8 MiB maximum serialized envelope; those are caller-configured
defaults, not schema-enforced limits.

See [`services/snapshot-normalizer-core/README.md`](services/snapshot-normalizer-core/README.md)
for the full public surface.

## Snapshot Normalizer

`services/snapshot-normalizer/` is the MQTT adapter built on the core library.
It subscribes to a binary JPEG snapshot topic, such as a media connector
`snapshot-to-mqtt` stream, and publishes each accepted snapshot as an
`image_snapshot` v1 request to
`edge-ai/v1/snapshot-normalizer/{camera-id}/camera/snapshots`, which the
inference service receives through its `edge-ai/+/+/+/camera/snapshots` input
filter.

- Carries CloudEvents attributes as MQTTv5 user properties
- Deduplicates on the producer-supplied CloudEvents `id`, never on content
- Refuses to start when its output topic matches its own input filter
- Deploys with the [`charts/snapshot-normalizer`](charts/snapshot-normalizer/) Helm chart as one replica per camera, with a unique client ID per pod

See [`services/snapshot-normalizer/README.md`](services/snapshot-normalizer/README.md)
for configuration, delivery semantics, and an authorization example.

## Quick Start

### Local Development

1. **Ensure prerequisites** (if not using devcontainer, install manually):

   ```bash
   # Start local MQTT broker (if not already running)
   docker run -d -p 1883:1883 --name mosquitto eclipse-mosquitto:latest
   ```

2. **Start the development environment:**

   ```bash
   cd src/500-application/507-ai-inference

   # Default: ONNX Runtime backend
   docker-compose up --build

   # Or specify backend explicitly
   AI_BACKEND=onnx docker-compose up --build   # ONNX Runtime (default)
   AI_BACKEND=candle docker-compose up --build # Candle (pure Rust)
   ```

   > **Note**: This configuration uses the MQTT broker running on the host via `host.docker.internal` (port 1883).

3. **Test inference with sample image:**

   ```bash
   # Send test message to the AI inference service
   mosquitto_pub -h localhost -p 1883 -t "edge-ai/test/facility/camera/snapshots" -m '{
     "image_data": "base64_encoded_image_here",
     "device_id": "test-camera-01",
     "timestamp": "'$(date +%s)'"
   }'
   ```

4. **Monitor results:**

   ```bash
   # Subscribe to inference results
   mosquitto_sub -h localhost -p 1883 -t "edge-ai/+/+/ai/inference/+"
   ```

### Production Deployment

Deploy to Kubernetes using the provided manifests:

```bash
kubectl apply -k charts/base/
```

## Configuration

### Environment Variables

| Variable              | Description               | Default                                               |
|-----------------------|---------------------------|-------------------------------------------------------|
| `AIO_BROKER_HOSTNAME` | MQTT broker hostname      | `host.docker.internal`                                |
| `AIO_BROKER_TCP_PORT` | MQTT broker port          | `1883`                                                |
| `MQTT_INPUT_TOPICS`   | Input topic patterns      | `edge-ai/+/+/camera/snapshots`                        |
| `TOPIC_PREFIX`        | Output topic prefix       | `edge-ai/business_unit/facility/gateway_id`           |
| `DEFAULT_BACKEND`     | Default inference backend | `onnx`                                                |
| `ENABLE_DUAL_BACKEND` | Enable backend comparison | `true`                                                |
| `MODEL_CONFIG_PATH`   | Model configuration file  | `/app/resources/model_configs/industrial-safety.yaml` |
| `RUST_LOG`            | Logging level             | `info,ai_edge_inference=debug`                        |

### Topic Structure

```bash
# Input Topics
edge-ai/business_unit/facility/gateway_id/device_id/camera/snapshots
edge-ai/business_unit/facility/gateway_id/device_id/sensors/temperature

# Output Topics
edge-ai/business_unit/facility/gateway_id/device_id/ai/inference/vision
edge-ai/business_unit/facility/gateway_id/device_id/ai/inference/sensor
edge-ai/business_unit/facility/gateway_id/device_id/ai/status
```

## Model Support

### Supported Models

- **TinyYOLOv2**: Object detection with bounding boxes (63MB model)
- **MobileNet**: Image classification optimized for edge devices
- **Industrial Safety**: Custom safety detection model for industrial environments

> **Note**: Development placeholders are included in `resources/models/` to allow the service to build and run without errors. Replace with actual ONNX models for production use.

### Model Configuration

Models are configured via YAML files in `resources/model_configs/`:

```yaml
# Example: industrial-safety.yaml
name: "industrial-safety-detector"
model_path: "/models/industrial-safety.onnx"
preprocessing:
  resize: [224, 224]
  normalize: true
confidence_threshold: 0.7
```

### Adding Production Models

Replace placeholder models in `resources/models/` with actual ONNX models:

```bash
# Example: Replace with real model
cp /path/to/real/model.onnx resources/models/default.onnx

# Update configuration
vi resources/model_configs/industrial-safety.yaml

# Restart service
docker-compose restart ai-edge-inference
```

**Model Requirements**: ONNX format, compatible with ONNX Runtime 1.15+, recommended size < 50MB for repository storage.

## Performance Metrics

- **ONNX Runtime**: 220ms average inference time
- **Candle Backend**: 155ms average inference time
- **Container Size**: 24.8MB optimized for edge deployment
- **Memory Usage**: < 512MB typical operation
- **Throughput**: 4-6 inferences/second per backend

## Development

### Building Services

```bash
# Build with specific backend using docker
cd services/ai-edge-inference
docker build --build-arg BACKEND=onnx -t ai-edge-inference:onnx .
docker build --build-arg BACKEND=candle -t ai-edge-inference:candle .

# Or use docker-compose from project root
AI_BACKEND=onnx docker-compose build
AI_BACKEND=candle docker-compose build

# Build services directly with cargo
cd services/ai-edge-inference
cargo build --release --features onnx-runtime --no-default-features  # ONNX
cargo build --release --features candle --no-default-features        # Candle

# Build shared crate
cd services/ai-edge-inference-crate
cargo build --release
```

**Backend Characteristics:**

- **ONNX**: ~200-300MB image, full ONNX model support, GPU acceleration capable
- **Candle**: ~50-100MB image, pure Rust, fastest startup, resource-constrained environments

### Testing

```bash
# Run unit tests
cd services/ai-edge-inference
cargo test

# Run integration tests
./tests/test-dual-backend-real.sh

# Run performance benchmarks
./tests/test-real-dual-backend-comprehensive.sh
```

### Adding New Models

1. Add model file to `resources/models/`
2. Create configuration in `resources/model_configs/`
3. Update service configuration
4. Test with development environment

## Monitoring and Observability

The service provides comprehensive monitoring capabilities:

- **Health Checks**: HTTP endpoint at `/health`
- **Metrics**: Prometheus-compatible metrics at `/metrics`
- **Logging**: Structured JSON logging with configurable levels
- **Tracing**: OpenTelemetry integration for distributed tracing

## Security Considerations

- MQTT connections support TLS encryption
- Model validation and sandboxing
- Input sanitization for image data
- Resource limits for inference workloads

## Troubleshooting

### Common Issues

1. **MQTT Connection Failed**: Check broker hostname and port configuration
2. **Model Loading Error**: Verify model file path and permissions
3. **High Memory Usage**: Adjust model batch size or enable model sharing
4. **Slow Inference**: Check GPU availability and model optimization

### Debug Commands

```bash
# Check service logs
docker-compose logs ai-edge-inference

# Test MQTT connectivity
docker-compose exec ai-edge-inference mosquitto_pub -h host.docker.internal -t test -m "hello"

# Validate model configuration
docker-compose exec ai-edge-inference cat /app/resources/model_configs/industrial-safety.yaml
```

## Contributing

See the main repository [CONTRIBUTING.md](../../../CONTRIBUTING.md) for development guidelines and contribution process.

## License

This component is part of the edge-ai project and follows the same licensing terms.

---

_AI and automation capabilities described in this scenario should be implemented following responsible AI principles, including fairness, reliability, safety, privacy, inclusiveness, transparency, and accountability. Organizations should ensure appropriate governance, monitoring, and human oversight are in place for all AI-powered solutions._

<!-- markdownlint-disable MD036 -->

_🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers._

<!-- markdownlint-enable MD036 -->
