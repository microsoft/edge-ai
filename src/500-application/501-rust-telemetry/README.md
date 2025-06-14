---
title: Rust Telemetry with OpenTelemetry
description: Distributed tracing with OpenTelemetry and an MQTT broker written in Rust, leveraging the Azure IoT Operations SDK for observable microservices deployed to edge environments
author: Edge AI Team
ms.date: 06/07/2025
ms.topic: tutorial
keywords:
  - rust
  - telemetry
  - opentelemetry
  - mqtt broker
  - azure iot operations sdk
  - distributed tracing
  - microservices
  - edge computing
  - grafana
  - docker
estimated_reading_time: 10
---

## Rust Telemetry with OpenTelemetry

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)

This project demonstrates distributed tracing with OpenTelemetry and an MQTT broker written in Rust. It leverages the **Azure IoT Operations SDK** for Rust to build observable microservices that can be deployed to edge environments and integrated with the Azure IoT Operations (AIO) ecosystem.

## Application Overview

The Rust Telemetry application consists of two main microservices built with the Azure IoT Operations SDK:

1. **Sender Service**: Generates simulated temperature telemetry data and publishes it to an MQTT topic with the OpenTelemetry trace context embedded in the message properties.
2. **Receiver Service**: Subscribes to the MQTT topic, receives the data, extracts the trace context from message properties, and logs the message.

The application also includes comprehensive observability features through OpenTelemetry, with integration to Grafana for dashboards and visualizations.

## Architecture

```ascii
┌─────────────┐     MQTT      ┌─────────────┐       ┌───────────────┐
│   Sender    │───publish────▶│    MQTT     │◀──────│   Receiver    │
│  Service    │  (telemetry)  │   Broker    │ subscribe  Service    │
└─────────────┘               └─────────────┘       └───────────────┘
       │                                                     │
       │                                                     │
       └──────────────┐               ┌────────────────────┘
                      ▼               ▼
               ┌─────────────────────────────┐
               │     OpenTelemetry           │
               │        Collector            │
               └─────────────────────────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │     Grafana     │
                     │    Dashboard    │
                     └─────────────────┘
```

## Features

- **Azure IoT Operations SDK**: Uses the official Rust SDK for AIO integration
- **Rust-based Microservices**: Lightweight, high-performance services with efficient resource usage
- **MQTT Integration**: Compatible with Azure IoT Operations (AIO) MQTT broker
- **End-to-end Observability**: Full OpenTelemetry instrumentation with tracing
- **Distributed Tracing**: Propagation of trace context through MQTT message properties
- **Eclipse Mosquitto Broker**: Lightweight MQTT broker included in the docker-compose
- **Grafana Visualization**: Pre-configured dashboards for trace analysis
- **Configurable**: All components can be customized via environment variables
- **Containerized**: All services packaged as Docker containers for easy deployment
- **Local Development**: Full stack runs locally with Docker Compose

## Getting Started

### Running Locally

#### Prerequisites

- Docker and Docker Compose
- Rust (optional, only for local development)

#### Docker Compose

The easiest way to run the application locally is with Docker Compose:

```bash
# Start all services (MQTT broker, sender, receiver, OpenTelemetry collector, Grafana)
docker compose up -d

# View the logs
docker compose logs -f

# Stop all services
docker compose down
```

#### Accessing Dashboards

- **Grafana**: `http://localhost:3000`
  - Default credentials: admin/admin

## Configuration

For a comprehensive list of Azure IoT Operations configuration options, see [Connection Settings](https://github.com/Azure/iot-operations-sdks/blob/main/doc/reference/connection-settings.md#settings).

### Docker Compose Configuration

The application can be configured using environment variables in the Docker Compose file:

### Sender Service

| Variable              | Description                | Docker Compose Default |
|-----------------------|----------------------------|------------------------|
| `AIO_BROKER_HOSTNAME` | MQTT broker hostname       | mosquitto-broker       |
| `AIO_BROKER_TCP_PORT` | MQTT broker port           | 1883                   |
| `AIO_MQTT_CLIENT_ID`  | MQTT client ID             | telemetry-sender       |
| `AIO_MQTT_USE_TLS`    | Whether to use TLS         | false                  |
| `TOPIC`               | Topic to publish telemetry | sample/telemetry       |
| `OTEL_SERVICE_NAME`   | Service name for telemetry | telemetry.sender       |
| `RUST_LOG`            | Log level                  | info                   |

### Receiver Service

| Variable              | Description                      | Docker Compose Default |
|-----------------------|----------------------------------|------------------------|
| `AIO_BROKER_HOSTNAME` | MQTT broker hostname             | mosquitto-broker       |
| `AIO_BROKER_TCP_PORT` | MQTT broker port                 | 1883                   |
| `AIO_MQTT_CLIENT_ID`  | MQTT client ID                   | telemetry-receiver     |
| `AIO_MQTT_USE_TLS`    | Whether to use TLS               | false                  |
| `TOPIC`               | Topic to subscribe for telemetry | sample/telemetry       |
| `OTEL_SERVICE_NAME`   | Service name for telemetry       | telemetry.receiver     |
| `RUST_LOG`            | Log level                        | info                   |

## Development

### Building the Services Locally

If you want to build and run the services without Docker:

```bash
# Build and run the sender
cd services/sender
cargo build --release
cargo run --release

# In another terminal, build and run the receiver
cd services/receiver
cargo build --release
cargo run --release
```

### Project Structure

```text
501-rust-telemetry/
├── docker-compose.yaml      # Container orchestration for all services
├── resources/               # Configuration files
│   ├── mosquitto.conf       # MQTT broker configuration
│   └── otel-collector-config.yaml  # OpenTelemetry collector config
└── services/                # Application services
    ├── sender/              # Telemetry generator service
    │   ├── Cargo.toml       # Rust dependencies and metadata
    │   ├── Dockerfile       # Container definition
    │   └── src/             # Rust source code
    └── receiver/            # Telemetry processor service
        ├── Cargo.toml       # Rust dependencies and metadata
        ├── Dockerfile       # Container definition
        └── src/             # Rust source code
```

## Integration with Azure IoT Operations

This example is designed to work with Azure IoT Operations (AIO). To use with AIO:

1. Configure the sender and receiver services to connect to your AIO MQTT broker
2. Update the environment variables to match your AIO deployment
3. Deploy the containers to your AIO-enabled Kubernetes cluster

## Azure Application Insights Integration

The OpenTelemetry collector can support sending telemetry data to Azure Application Insights. To enable this integration:

1. Create an Azure Application Insights resource or use an existing one
2. Obtain the connection string from the Application Insights resource
3. Uncomment the [OpenTelemetry config](./resources/otel-collector-config.yaml) `azuremonitor` sections and include the connection string.

This allows you to view the distributed traces in the Azure Application Insights portal along with other application telemetry.

## OpenTelemetry Feature

The application is fully instrumented with OpenTelemetry to provide:

- Distributed tracing across services with context propagation via MQTT message properties
- Metrics for performance monitoring
- Logs integrated with trace context
- Visualization through Grafana dashboards

### Viewing Traces in Grafana

After starting the application with Docker Compose, follow these steps to view distributed traces:

1. Open Grafana at [`http://localhost:3000`](http://localhost:3000) (credentials: admin/admin)
2. Navigate to the Explore section (compass icon in the left sidebar)
3. Select "Tempo" as the data source from the dropdown at the top
4. Click on the "Search" tab
5. In the search interface:
   - Set the time range to the period when your application was running
   - Filter for service name: `telemetry.sender` or `telemetry.receiver`
   - Click "Run query"
6. Select any trace to see the full distributed trace showing message flow:
   - Sender service creating and publishing messages
   - Message transport via MQTT broker
   - Receiver service processing messages
   - Trace context propagation between services

You can see the complete end-to-end journey of each telemetry message through the system, including timing data and any logs associated with each span.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
