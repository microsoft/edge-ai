---
title: DSS Dynamic Key Enricher WASM Module
description: WASM map operator that enriches messages with data from the AIO Distributed State Store using a dynamically constructed key from the incoming message
author: Edge AI Team
ms.date: 2026-06-09
ms.topic: reference
keywords:
  - wasm
  - state-store
  - dss
  - enrichment
  - azure-iot-operations
  - dataflow
  - dynamic-key
estimated_reading_time: 12
---

## DSS Dynamic Key Enricher WASM Module

WASM map operator that enriches incoming JSON messages with data read from the AIO Distributed State Store (DSS). The operator constructs the DSS lookup key dynamically from message content using a JSON Pointer, reads the stored record, and merges selected fields into the outgoing message.

```text
input → [dss_enricher] → output
```

This module is the **read-side companion** to [514-wasm-msg-to-dss](../514-wasm-msg-to-dss/README.md). The write module stores entity state in the DSS; this module reads it back. When both modules share the same `keyPath` and `keyPrefix`, the read pipeline automatically finds data written by the write pipeline — no custom code required beyond configuration.

> [!TIP]
> Built-in AIO enrichment (`datasets` with `$context`) only supports static DSS keys known at deployment time. Use this operator when the lookup key is derived from the incoming message, the key space is large or dynamic, or a single pipeline must handle messages that reference different entities.

## Architecture

This component implements a single `#[map_operator]` using the [Azure IoT Operations WASM SDK](https://learn.microsoft.com/azure/iot-operations/develop-edge-apps/howto-develop-wasm-modules?tabs=rust).

The operator follows a two-phase lifecycle:

* **Init phase**: Reads `keyPath`, `keyPrefix`, `outputPath`, `fields`, `onMissing`, and `onError` from `ModuleConfiguration.properties`. Validates that required parameters are present and well-formed. Returns `false` to halt the dataflow if validation fails, providing fast-fail at deployment time. Configuration is stored in a `OnceLock` for write-once, read-many access.
* **Process phase**: For each incoming message, parses the JSON payload, extracts the key value at the configured JSON Pointer path, constructs the full DSS key as `{keyPrefix}{extractedKey}`, reads the stored record with `state_store::get`, extracts the selected fields, and merges them into the outgoing message.

The operator is passthrough-first: state store errors and missing keys never drop messages by default. The original message is returned unchanged unless enrichment data is successfully merged. State changes are read on demand — the operator performs a pure read with no side effects on DSS state.

### Data Flow

```text
┌─────────────────────────────────────────────────────────────────┐
│ Incoming Message                                                 │
│ { "deviceId": "sensor-001", "temperature": 22.5 }              │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                    ┌───────────▼───────────┐
                    │ Extract key value      │
                    │ keyPath=/deviceId      │
                    │ → "sensor-001"         │
                    └───────────┬───────────┘
                                │
                    ┌───────────▼───────────┐
                    │ Construct DSS key      │
                    │ keyPrefix=device:      │
                    │ → "device:sensor-001"  │
                    └───────────┬───────────┘
                                │
                    ┌───────────▼───────────┐
                    │ state_store::get()     │
                    │ → stored JSON or None  │
                    └───────────┬───────────┘
                                │
              ┌─────────────────┼─────────────────┐
              │ Found           │ Not Found        │
              ▼                 ▼                  │
┌─────────────────────┐  ┌──────────────────┐     │
│ Merge stored fields │  │ onMissing=skip:  │     │
│ into output message │  │ pass through     │     │
│                     │  │ onMissing=error: │     │
│                     │  │ drop message     │     │
└──────────┬──────────┘  └──────────────────┘     │
           │                                       │
           ▼                                       │
┌─────────────────────────────────────────────────────────────────┐
│ Enriched Message                                                 │
│ { "deviceId": "sensor-001", "temperature": 22.5,               │
│   "location": "building-A", "calibration": 1.05 }             │
└─────────────────────────────────────────────────────────────────┘
```

## Folder Structure

```text
515-wasm-dss-enricher/
├── .cargo/
│   └── config.toml                 # WASM target and AIO SDK registry
├── .nobuild                        # Skip CI Docker builds
├── README.md                       # This file
├── operators/
│   └── dss-enricher/
│       ├── Cargo.toml              # Package definition (cdylib)
│       └── src/
│           └── lib.rs              # Map operator implementation
├── resources/
│   └── graphs/
│       └── graph-dss-enricher.yaml # WASM graph definition (OCI artifact)
└── scripts/
    ├── build-wasm.sh               # Build WASM module
    └── push-to-acr.sh             # Push module and graph to ACR
```

## Prerequisites

* [Rust toolchain](https://rustup.rs/) with `wasm32-wasip2` target
* [ORAS CLI](https://oras.land/docs/installation) for pushing to container registry
* [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with container registry access
* An Azure Container Registry (ACR) instance

## Deployment

### Step 1: Deploy the Full Stack

Deploy the [Full Single Node Cluster](../../../blueprints/full-single-node-cluster/) blueprint using [dataflow-graphs-dss-enricher.tfvars.example](../../../blueprints/full-single-node-cluster/terraform/dataflow-graphs-dss-enricher.tfvars.example) as the starting point for your `terraform.tfvars`.

This creates the complete infrastructure including ACR, the AIO cluster, and the dataflow graph referencing the WASM module. The graph will temporarily reference an ACR artifact that does not yet exist. The graph enters a pending state until Steps 2-4 publish the module.

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

The compiled WASM module is output to `operators/dss-enricher/target/wasm32-wasip2/release/dss_enricher.wasm`.

### Step 4: Push to Azure Container Registry

Push the compiled module and graph definition to your Azure Container Registry using the provided script. Pass your ACR name as an argument (without the `.azurecr.io` suffix). The script tags the artifacts with the version from `Cargo.toml` and pushes to ACR.

```bash
./scripts/push-to-acr.sh <acr_name>
```

This pushes:

* `<acr_name>.azurecr.io/dss-enricher:<version>` : WASM module
* `<acr_name>.azurecr.io/dss-enricher-graph:<version>` : Graph definition

Once the artifacts are available in ACR, the dataflow graph resolves and begins processing.

## Updating the Version

To release a new version of the module:

1. Increment the version in [operators/dss-enricher/Cargo.toml](operators/dss-enricher/Cargo.toml):

   ```toml
   [package]
   version = "2.0.0"
   ```

2. Update the graph artifact reference in your `terraform.tfvars` to match the new version:

   ```hcl
   artifact = "dss-enricher-graph:2.0.0"
   ```

3. Rebuild and push the updated artifacts:

   ```bash
   ./scripts/build-wasm.sh
   ./scripts/push-to-acr.sh <acr_name>
   ```

## Configuration

### Graph Definition Parameters

| Parameter    | Required | Default | Description                                                                                                                                                  |
|--------------|----------|---------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `keyPath`    | Yes      | (none)  | RFC 6901 JSON Pointer to the field used as the DSS lookup key. Examples: `/id`, `/data/entityId`, `/items/0/ref`                                              |
| `keyPrefix`  | No       | (empty) | String prepended to the extracted key value. Example: `device:` produces key `device:sensor-001`                                                             |
| `outputPath` | No       | (empty) | JSON path where enriched data is injected. Empty = merge at root. Example: `context` nests under `$.context`                                                  |
| `fields`     | No       | `*`     | Comma-separated list of fields to extract from the stored record. `*` = all top-level fields. Example: `location,calibration,name`                           |
| `onMissing`  | No       | `skip`  | Behavior when key is not found in DSS: `skip` (passthrough with warning), `error` (return error, drops message), `default` (inject empty object at outputPath) |
| `onError`    | No       | `skip`  | Behavior on state store errors: `skip` (passthrough with warning), `error` (return error)                                                                    |

### Validation Rules

The init phase returns `false` and halts the dataflow when any of the following validations fail:

* `keyPath` must be non-empty and start with `/` (RFC 6901)
* `outputPath` if provided must be a valid identifier (alphanumeric, underscores, dots)
* `fields` if provided must be non-empty comma-separated identifiers
* `onMissing` must be one of `skip`, `error`, or `default`
* `onError` must be one of `skip` or `error`

### Configuration Examples

**Simple enrichment — merge all stored fields at root:**

```text
keyPath=/deviceId
keyPrefix=device:
```

* Incoming: `{"deviceId": "sensor-001", "temp": 22}` and DSS `device:sensor-001` = `{"location": "lab"}`
* Output: `{"deviceId": "sensor-001", "temp": 22, "location": "lab"}`

**Selective fields under a namespace:**

```text
keyPath=/deviceId
keyPrefix=device:
outputPath=deviceContext
fields=name,category
```

* Incoming: `{"deviceId": "X", "value": 1}` and DSS `device:X` = `{"name": "Widget", "category": "A", "internal_code": "secret"}`
* Output: `{"deviceId": "X", "value": 1, "deviceContext": {"name": "Widget", "category": "A"}}`

**Strict mode — drop messages without matching state:**

```text
keyPath=/deviceId
keyPrefix=device:
onMissing=error
```

Messages referencing unknown device IDs are dropped with an error.

## Two-Pipeline Stitching with 514-wasm-msg-to-dss

This operator pairs with [514-wasm-msg-to-dss](../514-wasm-msg-to-dss/README.md) to implement a write/read stitching pattern across two independent pipelines. Pipeline A writes device state to the DSS; Pipeline B enriches telemetry by reading that state back using a dynamically constructed key.

```text
                        MQTT Broker
                       ┌───────────┐
  Device State         │           │       Telemetry Events
  Updates              │           │       (reference device)
        │              │           │              │
        ▼              │           │              ▼
  ┌──────────────┐     │           │     ┌──────────────────┐
  │ Pipeline A   │     │           │     │ Pipeline B       │
  │ 514: msg-to- │     │           │     │ 515: dss-        │
  │ dss-key      │     │           │     │ enricher         │
  │ (WRITE)      │     │           │     │ (READ)           │
  └──────┬───────┘     │           │     └────┬────────┬────┘
         │             │           │          │        │
         ▼             │           │          │        ▼
  ┌─────────────────┐  │           │          │  ┌──────────┐
  │ DSS             │  │           │          │  │ Enriched │
  │ device:sensor-1 │◄─┼───────────┼──────────┘  │ message  │
  │ device:sensor-2 │  │           │             │ to sink  │
  │ ...             │  │           │             └──────────┘
  └─────────────────┘  └───────────┘
```

### Pipeline A: Write device state to DSS (514)

Line A publishes a message each time device configuration changes. Pipeline A uses [514-wasm-msg-to-dss](../514-wasm-msg-to-dss/README.md) to store the full payload in the DSS with a TTL.

**Graph configuration**: `keyPath=/deviceId`, `keyPrefix=device:`, `ttlSeconds=3600`

Example message on `devices/+/config`:

```json
{
  "deviceId": "sensor-001",
  "location": "building-A",
  "calibration": 1.05,
  "name": "intake-temp",
  "updatedAt": "2026-06-09T09:14:00Z"
}
```

Result: DSS key `device:sensor-001` stores the full JSON payload.

### Pipeline B: Enrich telemetry with stored device state (515)

A second DataflowGraph processes telemetry from the same devices. Pipeline B uses this operator to look up the stored configuration and merge it into each reading.

**Graph configuration**: `keyPath=/deviceId`, `keyPrefix=device:`, `outputPath=deviceContext`, `fields=location,calibration,name`, `onMissing=skip`

Example message on `telemetry/+/readings`:

```json
{
  "deviceId": "sensor-001",
  "temperature": 22.5,
  "timestamp": "2026-06-09T14:22:00Z"
}
```

The enriched output sent to the sink:

```json
{
  "deviceId": "sensor-001",
  "temperature": 22.5,
  "timestamp": "2026-06-09T14:22:00Z",
  "deviceContext": {
    "location": "building-A",
    "calibration": 1.05,
    "name": "intake-temp"
  }
}
```

### Why this works

* **Symmetric key construction**: Both modules build the key as `{keyPrefix}{value-at-keyPath}`. Using the same `keyPath` and `keyPrefix` in both pipelines guarantees the read side finds what the write side stored.
* **TTL alignment**: The TTL set by Pipeline A controls how long stored state is available to Pipeline B. Size the TTL to cover the expected delay between a state update and the correlated telemetry.
* **`onMissing` safety net**: When Pipeline B references a device whose state was never written or whose TTL expired, the `onMissing` setting controls whether the message passes through unchanged (`skip`) or is dropped (`error`).
* **No custom read-side enrichment logic**: Pipeline B requires only graph configuration — the dynamic key lookup that built-in enrichment cannot perform is handled entirely by this operator.

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

### Messages pass through without enrichment

When `onMissing=skip` (the default) and `onError=skip`, the operator returns the original message whenever the key is missing or a read fails. Check the dataflow logs for warnings:

* `Key '...' not found in state store`: The write pipeline has not stored this key, or its TTL expired. Confirm Pipeline A is running and that both pipelines use the same `keyPath` and `keyPrefix`.
* `keyPath '...' not found in message`: The incoming message does not contain the configured pointer path. Verify the source topic payload shape.
* `Stored value for key '...' is not valid JSON`: The DSS record was not written as JSON. Confirm the write side stores JSON objects.

### Init validation errors

The operator returns `false` during init if required configuration is missing or invalid. Check the dataflow logs for specific error messages:

* `Missing required configuration: 'keyPath'`: Add the `keyPath` parameter to the graph definition.
* `Invalid keyPath '...'`: The value must start with `/` and follow RFC 6901 JSON Pointer syntax.
* `Invalid onMissing value '...'`: Use `skip`, `error`, or `default`.
* `Invalid onError value '...'`: Use `skip` or `error`.

## Capacity and Performance Considerations

The `dss-enricher` operator performs one synchronous `state_store::get()` call per message. This design is appropriate for low-to-moderate frequency enrichment but is not suitable for high-throughput telemetry streams.

> [!WARNING]
> Do not use this operator on high-speed message topics (thousands of messages per second). Each message triggers a synchronous state store read. At high volumes this adds per-message latency and increases broker memory pressure.

Before deploying, evaluate the expected message rate on the source topic and consider:

* **Message rate**: If the source topic exceeds a few hundred messages per second, filter or sample messages upstream before they reach this operator. Use a [Filter transform](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/howto-dataflow-graphs-filter-route?tabs=portal) to reduce the read rate.
* **State store caching**: The AIO runtime caches frequently accessed keys. Repeated lookups for the same key benefit from this layer.
* **Payload growth**: Enriched messages are larger than originals. Monitor broker memory profiles when merging large stored records.
* **TTL alignment**: Ensure the TTL set by the write pipeline (514) covers the expected delay before this read pipeline processes correlated messages.
* **Key cardinality**: Thousands of distinct keys increase the DSS memory footprint. Monitor state store resource usage and adjust `keyPrefix` granularity or TTL accordingly.
* **Broker memory profile**: For workloads with sustained volume, review the broker's memory profile (`Tiny`, `Low`, `Medium`, `High`).
  See [Configure broker settings for high availability, scaling, and memory usage](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/howto-configure-availability-scale?tabs=portal)
  for memory profile options and sizing guidance.

## Limitations

* Each operator invocation looks up exactly **one key**. Multi-key enrichment (correlating against an array of IDs) requires a custom operator or multiple chained instances.
* Only top-level field extraction is supported in `fields`. Nested field selection requires `*` (all fields) with downstream post-processing.
* The operator does not subscribe to KEYNOTIFY. State changes are reflected only on the next `get` call, not reactively.
* Source fields always take precedence during root-level merge. Use `outputPath` to isolate enrichment data when override behavior is needed.
* Not designed for high-throughput telemetry. See [Capacity and Performance Considerations](#capacity-and-performance-considerations) for sizing guidance.

## References

* [Develop WASM Modules for AIO](https://learn.microsoft.com/azure/iot-operations/develop-edge-apps/howto-develop-wasm-modules?tabs=rust)
* [Use WASM with Data Flow Graphs](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/howto-dataflow-graph-wasm?tabs=portal)
* [WASM Module Host APIs](https://learn.microsoft.com/azure/iot-operations/develop-edge-apps/concepts-wasm-modules#host-apis)
* [Enrich Data with External Datasets](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/howto-dataflow-graphs-enrich)
* [514-wasm-msg-to-dss: Message to DSS Key Writer](../514-wasm-msg-to-dss/README.md)
* [ORAS CLI Documentation](https://oras.land/docs/)
* [AIO State Store Overview](https://learn.microsoft.com/azure/iot-operations/develop-edge-apps/concept-about-state-store-protocol)
* [Filter and Route Data in Data Flow Graphs](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/howto-dataflow-graphs-filter-route?tabs=portal)
* [Configure Broker Availability, Scaling, and Memory](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/howto-configure-availability-scale?tabs=portal)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

<!-- markdownlint-disable MD036 -->

_🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers._

<!-- markdownlint-enable MD036 -->
