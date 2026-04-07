---
title: Message to DSS Key Writer WASM Module
description: WASM map operator that writes any JSON message to the AIO Distributed State Store with configurable key extraction and TTL
author: Edge AI Team
ms.date: 2026-04-07
ms.topic: reference
keywords:
  - wasm
  - state-store
  - dss
  - azure-iot-operations
  - dataflow
  - enrichment
estimated_reading_time: 8
---

## Message to DSS Key Writer WASM Module

WASM map operator that writes any incoming JSON message to the AIO Distributed State Store (DSS) under a configurable key extracted via JSON Pointer, with configurable TTL and full passthrough behavior.

```text
MQTT → [msg_to_dss_key] → MQTT
```

> [!TIP]
> After writing state with this operator, downstream pipelines can read back the stored data using AIO's built-in enrichment transforms with `datasets` and `$context` syntax. No additional WASM development is required for the read side. See [Using Built-in Enrichment to Read from DSS](#using-built-in-enrichment-to-read-from-dss).

## Architecture

This component implements a single `#[map_operator]` using the [Azure IoT Operations WASM SDK](https://learn.microsoft.com/azure/iot-operations/develop-edge-apps/howto-develop-wasm-modules?tabs=rust).

The operator follows a two-phase lifecycle:

* **Init phase**: Reads `keyPath`, `keyPrefix`, `ttlSeconds`, and `onMissing` from `ModuleConfiguration.properties`. Validates that required parameters are present and well-formed. Returns `false` to halt the dataflow if validation fails, providing fast-fail at deployment time. Configuration is stored in a `OnceLock` for write-once, read-many access.
* **Process phase**: For each incoming message, parses the JSON payload, extracts the key value at the configured JSON Pointer path, writes the full message to the DSS under `{keyPrefix}{extractedKey}` with the configured TTL, and returns the original message unchanged.

State store write errors are logged but do not drop the message, ensuring pipeline continuity. The original message is always returned to downstream nodes regardless of state store outcomes.

## Folder Structure

```text
514-wasm-msg-to-dss/
├── .cargo/
│   └── config.toml                 # WASM target and AIO SDK registry
├── README.md                       # This file
├── operators/
│   └── msg-to-dss-key/
│       ├── Cargo.lock              # Dependency lock file (generated)
│       ├── Cargo.toml              # Package definition (cdylib)
│       └── src/
│           └── lib.rs              # Map operator implementation
├── resources/
│   └── graphs/
│       └── graph-msg-to-dss-key.yaml # WASM graph definition (OCI artifact)
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

Deploy the [Full Single Node Cluster](../../../blueprints/full-single-node-cluster/) blueprint using [dataflow-graphs-msg-to-dss.tfvars.example](../../../blueprints/full-single-node-cluster/terraform/dataflow-graphs-msg-to-dss.tfvars.example) as the starting point for your `terraform.tfvars`.

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

The compiled WASM module is output to `operators/msg-to-dss-key/target/wasm32-wasip2/release/msg_to_dss_key.wasm`.

### Step 4: Push to Azure Container Registry

Push the compiled module and graph definition to your Azure Container Registry using the provided script. Pass your ACR name as an argument (without the `.azurecr.io` suffix). The script tags the artifacts with the version from `Cargo.toml` and pushes to ACR.

```bash
./scripts/push-to-acr.sh <acr_name>
```

This pushes:

* `<acr_name>.azurecr.io/msg-to-dss-key:<version>` : WASM module
* `<acr_name>.azurecr.io/msg-to-dss-key-graph:<version>` : Graph definition

Once the artifacts are available in ACR, the dataflow graph resolves and begins processing.

## Updating the Version

To release a new version of the module:

1. Increment the version in [operators/msg-to-dss-key/Cargo.toml](operators/msg-to-dss-key/Cargo.toml):

   ```toml
   [package]
   version = "2.0.0"
   ```

2. Update the graph artifact reference in your `terraform.tfvars` to match the new version:

   ```hcl
   artifact = "msg-to-dss-key-graph:2.0.0"
   ```

3. Rebuild and push the updated artifacts:

   ```bash
   ./scripts/build-wasm.sh
   ./scripts/push-to-acr.sh <acr_name>
   ```

## Configuration

### Graph Definition Parameters

| Parameter    | Required | Default | Description                                                                                              |
|--------------|----------|---------|----------------------------------------------------------------------------------------------------------|
| `keyPath`    | Yes      | (none)  | RFC 6901 JSON Pointer to the field used as the DSS key. Examples: `/id`, `/data/record_id`, `/items/0/id` |
| `keyPrefix`  | No       | (empty) | String prepended to the extracted key value. Example: `device:` produces keys like `device:sensor-001`    |
| `ttlSeconds` | Yes      | (none)  | Time-to-live in seconds for the DSS entry. Use `0` for no expiration.                                    |
| `onMissing`  | No       | `skip`  | Behavior when `keyPath` is not found in the message. `skip` logs a warning and passes through. `error` drops the message. |

### Key Extraction Examples

The `keyPath` parameter uses RFC 6901 JSON Pointer syntax to extract a value from the incoming message and use it as the state store key. The following examples show how different JSON messages map to DSS keys.

**Configuration**: `keyPath=/deviceId`, `keyPrefix=device:`, `ttlSeconds=3600`

Incoming message:

```json
{
  "deviceId": "sensor-001",
  "temperature": 22.5,
  "humidity": 45.2,
  "timestamp": "2026-04-07T10:30:00Z"
}
```

Result: DSS key `device:sensor-001` stores the full JSON payload. The original message passes through unchanged.

**Configuration**: `keyPath=/metadata/assetId`, `keyPrefix=asset:`, `ttlSeconds=7200`

Incoming message:

```json
{
  "metadata": {
    "assetId": "pump-42",
    "location": "building-A"
  },
  "readings": {
    "pressure": 101.3,
    "flow_rate": 15.7
  }
}
```

Result: DSS key `asset:pump-42` stores the full JSON payload.

**Configuration**: `keyPath=/sensors/0/id`, `keyPrefix=`, `ttlSeconds=600`

Incoming message:

```json
{
  "batchId": "batch-99",
  "sensors": [
    { "id": "temp-A", "value": 21.0 },
    { "id": "temp-B", "value": 23.5 }
  ]
}
```

Result: DSS key `temp-A` stores the full JSON payload. The pointer `/sensors/0/id` selects the `id` field of the first array element.

**Configuration**: `keyPath=/id`, `keyPrefix=`, `ttlSeconds=86400`, `onMissing=error`

Incoming message without the expected field:

```json
{
  "name": "unknown-device",
  "temperature": 19.0
}
```

Result: the operator returns an error because `/id` is not found and `onMissing=error`. The message is dropped and does not reach the sink.

### Store-Only Mode (Discard After Write)

In some scenarios, the goal is to write data to the DSS without forwarding the message to any downstream consumer. Because the `msg-to-dss-key` operator always passes the original message through, you can add a built-in [Filter transform](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/howto-dataflow-graphs-filter-route?tabs=portal) after this operator to drop all messages.

A filter rule where the expression always evaluates to `true` drops every message:

```text
MQTT → [msg_to_dss_key] → [filter: true] → (no output)
```

In the DataflowGraph definition, add a built-in filter node after the WASM graph node with a rule that always matches:

```yaml
filter:
  - inputs:
      - "1"              # Literal constant, always present
    expression: "true"   # Always evaluates to true, drops every message
```

A destination node is still required in the pipeline definition, but no messages reach it. Use the default MQTT endpoint with a designated "discard" topic.

This pattern is useful when:

* Pipeline A writes device state to the DSS for later enrichment by Pipeline B, and the original message has no other consumer.
* You want to populate a lookup table in the DSS from a configuration topic without re-publishing the data.

Reference: [Filter and route data in data flow graphs](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/howto-dataflow-graphs-filter-route?tabs=portal)

### Using Built-in Enrichment to Read from DSS

After writing state with this operator, downstream pipelines can read back the stored data using AIO's built-in enrichment feature. This creates a two-pipeline stitching pattern: one pipeline writes entity state to the DSS, and a second pipeline enriches incoming events with that stored state using only built-in transforms.

#### Pipeline A: Write entity state to DSS

The `msg-to-dss-key` operator writes messages (for example, device configuration updates) to the DSS:

```text
MQTT topic: devices/+/config
  → [msg_to_dss_key: keyPath=/deviceId, keyPrefix=device:, ttlSeconds=3600]
  → MQTT topic: devices/config/ack
```

Result: the DSS contains keys like `device:sensor-001` with the full JSON payload `{"deviceId":"sensor-001","calibration":1.05,...}`.

#### Pipeline B: Enrich telemetry with stored state

A second DataflowGraph processes telemetry from the same devices. It uses a built-in map transform with a `datasets` configuration to look up the stored configuration:

```yaml
datasets:
  - key: "device:sensor-001"      # Static DSS key written by pipeline A
    inputs:
      - "$source.deviceId"        # From the incoming telemetry message
      - "$context.deviceId"       # From the stored config record
    expression: "$1 == $2"
```

Rules in the same transform reference the matched fields using `$context(<alias>)`:

```yaml
map:
  - inputs:
      - "$context(device-sensor-001).calibration"
      - "$source.rawValue"
    output: "calibratedValue"
    expression: "$1 * $2"
```

#### Enrichment behavior reference

| Aspect | Behavior |
|---|---|
| Dataset source | DSS key specified as a static string in the DataflowGraph resource |
| Data format | NDJSON (newline-delimited JSON). A single JSON object without a trailing newline is valid single-record NDJSON. |
| Match expression | Boolean expression comparing `$source` fields against `$context` fields |
| Context access | `$context(<alias>).<field>` in map, filter, or branch expressions |
| Supported transforms | Built-in map, filter, and branch transforms |
| Dynamic key lookup | Not supported by built-in enrichment. Requires a custom WASM state reader operator. |

> [!NOTE]
> The `msg-to-dss-key` operator stores each message as a single JSON object per key. This is compatible with AIO enrichment because a single JSON object is valid single-record NDJSON. For multi-record datasets (multiple entities under one key), populate the state store directly using the [AIO state store CLI](https://github.com/Azure/iot-operations-sdks/tree/main/tools/statestore-cli) with NDJSON content.

Reference: [Enrich data with external datasets in data flow graphs](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/howto-dataflow-graphs-enrich)

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

### State store write failures in logs

State store write errors are logged but do not drop messages. Common causes:

* The DSS is not initialized on the cluster. Verify that AIO IoT Operations is deployed and the state store is healthy.
* The key exceeds the maximum allowed length. Reduce `keyPrefix` length or select a shorter key field.

### Init validation errors

The operator returns `false` during init if required configuration is missing or invalid. Check the dataflow logs for specific error messages:

* `Missing required configuration: 'keyPath'`: Add the `keyPath` parameter to the graph definition.
* `Missing required configuration: 'ttlSeconds'`: Add the `ttlSeconds` parameter to the graph definition.
* `Invalid keyPath '...'`: The value must start with `/` and follow RFC 6901 JSON Pointer syntax.
* `Invalid onMissing value '...'`: Use `skip` or `error`.

## Capacity and Performance Considerations

The `msg-to-dss-key` operator writes to the AIO Distributed State Store on every message. This design is appropriate for low-to-moderate frequency updates (device state, configuration changes, periodic snapshots) but is not suitable for high-throughput telemetry streams.

> [!WARNING]
> Do not use this operator on high-speed message topics (thousands of messages per second). Each message triggers a synchronous state store write. At high volumes this can overwhelm the DSS, increase broker memory pressure, and degrade pipeline throughput across the cluster.

Before deploying, evaluate the expected message rate on the source topic and consider:

* **Message rate**: If the source topic exceeds a few hundred messages per second, filter or sample messages upstream before they reach this operator. Use a [Filter transform](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/howto-dataflow-graphs-filter-route?tabs=portal) to reduce the write rate.
* **TTL sizing**: Short TTL values cause frequent key expiration and re-creation. Choose TTL values that match the expected update interval for each entity.
* **Key cardinality**: Writing to thousands of distinct keys increases the DSS memory footprint. Monitor state store resource usage and adjust `keyPrefix` granularity or TTL accordingly.
* **Broker memory profile**: The MQTT broker's memory profile affects how much data can be buffered in flight. For workloads that generate sustained write volume, review the broker's memory profile (`Tiny`, `Low`, `Medium`, `High`) and consider whether disk-backed persistence is appropriate.
  See [Configure broker settings for high availability, scaling, and memory usage](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/howto-configure-availability-scale?tabs=portal)
  for memory profile options and sizing guidance.

## Limitations

* `onMissing=skip` is the default behavior. Messages where the `keyPath` is not found are silently passed through with only a log warning.
* Each key stores a single JSON object. The operator does not produce multi-record NDJSON datasets.
* Dynamic key lookup at enrichment time (where the key name is determined from the incoming message) is not supported by built-in enrichment and requires a custom WASM state reader operator.
* Not designed for high-throughput telemetry. See [Capacity and Performance Considerations](#capacity-and-performance-considerations) for sizing guidance.

## References

* [Develop WASM Modules for AIO](https://learn.microsoft.com/azure/iot-operations/develop-edge-apps/howto-develop-wasm-modules?tabs=rust)
* [Use WASM with Data Flow Graphs](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/howto-dataflow-graph-wasm?tabs=portal)
* [Enrich Data with External Datasets](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/howto-dataflow-graphs-enrich)
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
