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

This component implements a single `#[map_operator]` using the [Azure IoT Operations WASM SDK](https://learn.microsoft.com/azure/iot-operations/develop-edge-apps/howto-develop-wasm-modules?tabs=rust).

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
    └── push-to-acr.sh              # Push module and graph to ACR
```

## Prerequisites

- [Rust toolchain](https://rustup.rs/) with `wasm32-wasip2` target
- [ORAS CLI](https://oras.land/docs/installation) for pushing to container registry
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with container registry access
- A Kafka broker producing Avro-encoded messages

## Deployment

### Step 1: Deploy the Full Stack

Deploy the [Full Single Node Cluster](../../../blueprints/full-single-node-cluster/) blueprint using [dataflow-graphs-avro-json.tfvars.example](../../../blueprints/full-single-node-cluster/terraform/dataflow-graphs-avro-json.tfvars.example) as the starting point for your `terraform.tfvars`.

This creates the complete infrastructure including ACR, the AIO cluster, and a [Kafka DataflowEndpoint](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/howto-configure-kafka-endpoint?tabs=portal) (`kafka-source`) connecting to your Kafka broker. It also provisions the dataflow graph referencing the WASM module. The graph will temporarily reference an ACR artifact that does not yet exist — this is expected. The graph enters a pending state until Steps 2–4 publish the module.

> [!NOTE]
> If the full stack is already deployed from a previous run, skip to Step 2.

### Step 2: Install WASM Target

```bash
rustup target add wasm32-wasip2
```

### Step 3: Build the Module

Run the build script from the application root:

```bash
./scripts/build-wasm.sh
```

The compiled WASM module is output to `operators/avro-to-json/target/wasm32-wasip2/release/avro_to_json.wasm`.

### Step 4: Push to Azure Container Registry

Push the compiled module and graph definition to your Azure Container Registry using the provided script. Pass your ACR name as an argument (without the `.azurecr.io` suffix). The script tags the artifacts with the version from `Cargo.toml` and pushes to ACR.

```bash
./scripts/push-to-acr.sh <acr_name>
```

This pushes:

- `<acr_name>.azurecr.io/avro-to-json:<version>` — WASM module
- `<acr_name>.azurecr.io/avro-to-json-graph:<version>` — Graph definition

Once the artifacts are available in ACR, the dataflow graph resolves and begins processing.

## Updating the Version

To release a new version of the module:

1. Increment the version in [operators/avro-to-json/Cargo.toml](operators/avro-to-json/Cargo.toml):

   ```toml
   [package]
   version = "2.0.0"
   ```

2. Update the graph artifact reference in your `terraform.tfvars` to match the new version:

   ```hcl
   artifact = "graph-avro-to-json:2.0.0"
   ```

3. Rebuild and push the updated artifacts:

   ```bash
   ./scripts/build-wasm.sh
   ./scripts/push-to-acr.sh <acr_name>
   ```

## Configuration

### Graph Definition Parameters

| Parameter    | Required | Default | Description                                                                                                            |
| ------------ | -------- | ------- | ---------------------------------------------------------------------------------------------------------------------- |
| `avroSchema` | No       | (none)  | Avro schema as a JSON string. Required when messages are raw Avro binary without embedded schema. Omit for OCF format. |

### Schema Handling

#### Option A: Schema embedded in messages (Object Container File format)

If your source produces Avro Object Container File format (messages start with magic bytes `Obj\x01`), omit the `avroSchema` configuration. The module auto-detects the schema from the message header.

### Option B: Raw Avro binary (schema provided via configuration)

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
| union                 | (varies)  | Unwrapped to selected variant                                       |
| decimal               | number    | Unscaled integer value (scale information not preserved from schema) |
| bigdecimal            | string    | String representation preserving all decimal places                 |
| date, time, timestamp | number    | Epoch-based numeric value                                           |
| duration              | object    | `{ months, days, millis }`                                          |
| uuid                  | string    | Standard UUID format                                                |

## Sample Schema

The `resources/schemas/equipment-telemetry.avsc` file contains a sample Avro schema representing process manufacturing equipment telemetry. It covers key Avro types (string, enum, double, long, union, nested record) and can be used for testing the module's conversion capabilities.

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

This project is licensed under the MIT License - see the LICENSE file for details.

---

<!-- markdownlint-disable MD036 -->

_🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers._

<!-- markdownlint-enable MD036 -->
