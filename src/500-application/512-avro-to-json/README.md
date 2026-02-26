---
title: Avro to JSON WASM Module
description: WASM map operator that transforms Apache Avro binary data to JSON for Azure IoT Operations dataflow graphs
author: Edge AI Team
ms.date: 2026-02-26
ms.topic: reference
keywords:
  - avro
  - json
  - wasm
  - azure-iot-operations
  - dataflow
  - kafka
estimated_reading_time: 8
---

## Overview

WASM map operator that converts Apache Avro binary data to JSON in Azure IoT Operations dataflow graphs. Designed for Kafka-to-MQTT transformation scenarios where the source system produces Avro-encoded messages and the destination expects JSON.

```text
Kafka (Avro) → AIO DataFlow Source → [avro_to_json map] → AIO MQTT topic (JSON)
```

The operator supports multiple Avro encoding formats including Object Container File (with embedded schema), schema-based decoding via configuration, and single-object encoding detection.

## Architecture

This component implements a single `#[map_operator]` using the Azure IoT Operations WASM SDK. Unlike the [511-rust-embedded-wasm-provider](../511-rust-embedded-wasm-provider/README.md) which uses WIT component composition, this module is a standalone map operator compiled directly to `wasm32-wasip2`.

The operator receives Avro binary payloads from the dataflow source, transforms them to JSON, and forwards the result to the dataflow sink.

## Folder Structure

```text
512-avro-to-json/
├── .cargo/
│   └── config.toml                 # WASM target and AIO SDK registry
├── README.md                       # This file
├── operators/
│   └── avro-to-json/
│       ├── Cargo.lock              # Dependency lock file
│       ├── Cargo.toml              # Package definition (cdylib)
│       └── src/
│           └── lib.rs              # Map operator implementation
├── resources/
│   ├── graphs/
│   │   └── graph-avro-to-json.yaml # WASM graph definition (OCI artifact)
│   └── schemas/
│       └── equipment-telemetry.avsc # Sample Avro schema
└── scripts/
    ├── build-wasm.sh               # Build WASM module
    ├── push-to-acr.sh              # Push module and graph to ACR
    └── generate_test_data.py       # Generate test Avro files
```

## Prerequisites

### Rust Toolchain

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup target add wasm32-wasip2
```

### ORAS CLI

The [ORAS CLI](https://oras.land/docs/installation) pushes WASM modules and graph definitions to your container registry as OCI artifacts.

### Azure CLI

Required for authenticating with Azure Container Registry.

```bash
az login
```

## Build

Build the WASM module using the provided script:

```bash
cd src/500-application/512-avro-to-json
./scripts/build-wasm.sh
```

To build manually without the script:

```bash
cd src/500-application/512-avro-to-json
cargo build --release \
  --target wasm32-wasip2 \
  --manifest-path operators/avro-to-json/Cargo.toml \
  --config .cargo/config.toml
```

The compiled WASM module is output to `operators/avro-to-json/target/wasm32-wasip2/release/avro_to_json.wasm`.

## Push to ACR

Push the compiled WASM module and graph definition to Azure Container Registry:

```bash
./scripts/push-to-acr.sh <acr_name>
```

This pushes two OCI artifacts:

- `<acr_name>.azurecr.io/avro-to-json:<version>` — WASM module
- `<acr_name>.azurecr.io/avro-to-json-graph:<version>` — Graph definition with version substituted

## Deployment

This component follows the edge-ai deployment convention where dataflow endpoints and graphs are managed through Terraform, not raw Kubernetes manifests.

Deploy using the [`full-single-node-cluster`](../../../blueprints/full-single-node-cluster/README.md) blueprint (or another applicable blueprint). The dataflow infrastructure is managed by [`src/100-edge/130-messaging`](../../100-edge/130-messaging/README.md) which provisions DataflowEndpoints and DataflowGraphs via Terraform.

To integrate this module into a blueprint deployment, add the WASM registry endpoint and graph artifact reference to your blueprint's dataflow configuration variables.

## Configuration

### Graph Definition Parameters

| Parameter    | Required | Default | Description                                                                                                            |
| ------------ | -------- | ------- | ---------------------------------------------------------------------------------------------------------------------- |
| `avroSchema` | No       | (none)  | Avro schema as a JSON string. Required when messages are raw Avro binary without embedded schema. Omit for OCF format. |

### Schema Handling

**Option A: Schema embedded in messages (Object Container File format)**

If your source produces Avro Object Container File format (messages start with magic bytes `Obj\x01`), omit the `avroSchema` configuration. The module auto-detects the schema from the message header.

**Option B: Raw Avro binary (schema provided via configuration)**

If messages contain raw Avro binary without an embedded schema, provide the schema as a JSON string in the `avroSchema` graph configuration parameter.

## Avro Format Detection

The operator tries parsing strategies in this order:

| Priority | Format                 | Detection                  | Schema Source                         |
| -------- | ---------------------- | -------------------------- | ------------------------------------- |
| 1        | Configured schema      | `avroSchema` parameter set | Configuration                         |
| 2        | Object Container File  | Magic bytes `Obj\x01`      | Embedded in message header            |
| 3        | Single-object encoding | Marker `0xC3 0x01`         | Not supported (returns error)         |
| 4        | Unknown                | None of the above          | Returns error with diagnostic message |

## Avro Type Mapping

| Avro Type             | JSON Type | Notes                                    |
| --------------------- | --------- | ---------------------------------------- |
| null                  | null      |                                          |
| boolean               | boolean   |                                          |
| int, long             | number    |                                          |
| float, double         | number    |                                          |
| string                | string    |                                          |
| bytes, fixed          | string    | UTF-8 if valid, otherwise base64-encoded |
| enum                  | string    | Symbol name                              |
| array                 | array     | Recursive conversion                     |
| map                   | object    | Recursive conversion                     |
| record                | object    | Field names as keys                      |
| union                 | (varies)  | Unwrapped to selected variant            |
| decimal, bigdecimal   | number    | Unscaled integer value                   |
| date, time, timestamp | number    | Epoch-based numeric value                |
| duration              | object    | `{ months, days, millis }`               |
| uuid                  | string    | Standard UUID format                     |

## Sample Schema

The `resources/schemas/equipment-telemetry.avsc` file contains a sample Avro schema representing process manufacturing equipment telemetry. It covers key Avro types (string, enum, double, long, union, nested record) and can be used for testing the module's conversion capabilities.

## Test Data Generation

Generate sample Avro test files using the provided Python script:

```bash
pip install avro-python3
python3 scripts/generate_test_data.py
```

This creates:

- `test_binary.avro` — Raw Avro binary (requires schema to decode)
- `test_container.avro` — Object Container File format (schema embedded)
- `schema.json` — Schema in JSON format
- `expected_output.json` — Expected JSON output after transformation

## Troubleshooting

### Build fails with `can't find crate for std`

The WASM target is not installed:

```bash
rustup target add wasm32-wasip2
```

### Build fails with `oras CLI not found`

Install the ORAS CLI from <https://oras.land/docs/installation>.

### ACR push fails with authentication error

Ensure you are logged in with the Azure CLI:

```bash
az login
az acr login --name <acr_name>
```

## Limitations

- **Single-object encoding** requires schema registry lookup (not implemented). Use Object Container File format or provide schema via configuration.
- **Snappy compression** is disabled for WASM compatibility. Messages compressed with snappy cannot be decoded. Use deflate or no compression.
- **Schema evolution** requires updating the `avroSchema` configuration parameter when the producer changes schema. Consider using Object Container File format to avoid this.

## References

- [Develop WASM Modules for AIO](https://learn.microsoft.com/en-us/azure/iot-operations/develop-edge-apps/howto-develop-wasm-modules?tabs=rust)
- [Use WASM with Data Flow Graphs](https://learn.microsoft.com/en-us/azure/iot-operations/connect-to-cloud/howto-dataflow-graph-wasm?tabs=portal)

## License

MIT
