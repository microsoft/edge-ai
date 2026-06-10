---
title: AIO DSS Write and Enrich WASM Operators
description: Two WASM map operators for AIO Distributed State Store interactions over MQTT, a write side that stores JSON messages under a configurable key and a read side that enriches messages from a dynamically constructed key
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
estimated_reading_time: 12
---

## AIO DSS Write and Enrich WASM Operators

Two WASM map operators for AIO Distributed State Store (DSS) interactions over MQTT. The write side stores any incoming JSON message under a configurable key extracted via JSON Pointer, with a configurable TTL and full passthrough behavior. The read side enriches incoming messages with data read from the DSS using a key constructed dynamically from message content.

```text
write:  input → [msg_to_dss_key]   → output   (message stored in DSS)
enrich: input → [dss_enricher_key] → output   (message enriched from DSS)
```

> [!TIP]
> When the lookup key is static and known at deployment time, downstream pipelines can read stored data using AIO's built-in enrichment transforms with `datasets` and `$context` syntax, with no additional WASM development required.
> See [Using Built-in Enrichment to Read from DSS](#using-built-in-enrichment-to-read-from-dss). When the key is derived from message content, use the `dss-enricher-key` operator described below.

## Operators

This component packages two complementary operators that share the same key construction logic, building the DSS key as `{keyPrefix}{value-at-keyPath}`.

### Write side: `msg-to-dss-key`

Writes each incoming JSON message to the DSS under the constructed key with a TTL, then passes the original message through unchanged. Use it to populate entity state such as device configuration, lot metadata, or lookup tables for later reads.

### Read and enrich side: `dss-enricher-key`

Reads a stored DSS record using a key built dynamically from the incoming message, then merges selected fields into the outgoing message. Use it when the lookup key is derived from message content, the key space is large or dynamic, or a single pipeline must handle messages that reference different entities.

When both operators share the same `keyPath` and `keyPrefix`, the read pipeline automatically finds data written by the write pipeline with no custom code required beyond configuration.

## Architecture

Each operator implements a single `#[map_operator]` using the [Azure IoT Operations WASM SDK](https://learn.microsoft.com/azure/iot-operations/develop-edge-apps/howto-develop-wasm-modules?tabs=rust). Both follow a two-phase lifecycle.

The init phase reads and validates parameters from `ModuleConfiguration.properties`, returning `false` to halt the dataflow when validation fails for fast-fail at deployment time, and stores configuration in a `OnceLock` for write-once, read-many access. The process phase runs once per incoming message.

### Write operator process phase

The `msg-to-dss-key` operator parses the JSON payload, extracts the key value at the configured JSON Pointer path, writes the full message to the DSS under `{keyPrefix}{extractedKey}` with the configured TTL, and returns the original message unchanged. State store write errors are logged but do not drop the message, ensuring pipeline continuity. The original message is always returned to downstream nodes regardless of state store outcomes.

### Enrich operator process phase

The `dss-enricher-key` operator parses the JSON payload, extracts the key value at the configured JSON Pointer path, constructs the DSS key as `{keyPrefix}{extractedKey}`, reads the stored record with `state_store::get`, extracts the selected fields, and merges them into the outgoing message. The operator is passthrough-first: state store errors and missing keys never drop messages by default, and the read is a pure lookup with no side effects on DSS state.

## Folder Structure

```text
514-wasm-msg-to-dss/
├── .cargo/
│   └── config.toml                 # WASM target and AIO SDK registry
├── README.md                       # This file
├── operators/
│   ├── msg-to-dss-key/
│   │   ├── Cargo.lock              # Dependency lock file (generated)
│   │   ├── Cargo.toml              # Package definition (cdylib)
│   │   └── src/
│   │       └── lib.rs              # Write map operator implementation
│   └── dss-enricher-key/
│       ├── Cargo.lock              # Dependency lock file (generated)
│       ├── Cargo.toml              # Package definition (cdylib)
│       └── src/
│           └── lib.rs              # Enrich map operator implementation
├── resources/
│   └── graphs/
│       ├── graph-msg-to-dss-key.yaml   # Write graph definition (OCI artifact)
│       └── graph-dss-enricher-key.yaml # Enrich graph definition (OCI artifact)
└── scripts/
    ├── build-wasm.sh               # Build WASM modules
    └── push-to-acr.sh             # Push modules and graphs to ACR
```

## Prerequisites

* [Rust toolchain](https://rustup.rs/) with `wasm32-wasip2` target
* [ORAS CLI](https://oras.land/docs/installation) for pushing to container registry
* [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with container registry access
* An Azure Container Registry (ACR) instance

## Deployment

### Step 1: Deploy the Full Stack

Deploy the [Full Single Node Cluster](../../../blueprints/full-single-node-cluster/) blueprint using [dataflow-graphs-msg-to-dss.tfvars.example](../../../blueprints/full-single-node-cluster/terraform/dataflow-graphs-msg-to-dss.tfvars.example) as the starting point for your `terraform.tfvars`.
The example defines Pipeline A for the write side (`msg-to-dss-key`) and an optional Pipeline B for the read and enrich side (`dss-enricher-key`). Remove the second pipeline from `dataflow_graphs` to deploy the write side only.

This creates the complete infrastructure including ACR, the AIO cluster, and the dataflow graphs referencing the WASM modules. The graphs will temporarily reference ACR artifacts that do not yet exist. They enter a pending state until Steps 2-4 publish the modules.

> [!NOTE]
> If the full stack is already deployed from a previous run, skip to Step 2.

### Step 2: Install WASM Target

```bash
rustup target add wasm32-wasip2
```

### Step 3: Build the Modules

Run the build script from the application root to build both operators:

```bash
./scripts/build-wasm.sh
```

To build a single operator, pass its name:

```bash
./scripts/build-wasm.sh msg-to-dss-key
./scripts/build-wasm.sh dss-enricher-key
```

The compiled WASM modules are output to:

* `operators/msg-to-dss-key/target/wasm32-wasip2/release/msg_to_dss_key.wasm`
* `operators/dss-enricher-key/target/wasm32-wasip2/release/dss_enricher_key.wasm`

### Step 4: Push to Azure Container Registry

Push the compiled modules and graph definitions to your Azure Container Registry using the provided script. Pass your ACR name as an argument (without the `.azurecr.io` suffix). The script tags the artifacts with the version from each operator's `Cargo.toml` and pushes to ACR.

```bash
./scripts/push-to-acr.sh <acr_name>
```

To push a single operator, pass its name after the ACR name:

```bash
./scripts/push-to-acr.sh <acr_name> msg-to-dss-key
./scripts/push-to-acr.sh <acr_name> dss-enricher-key
```

This pushes four artifacts:

* `<acr_name>.azurecr.io/msg-to-dss-key:<version>` : write WASM module
* `<acr_name>.azurecr.io/msg-to-dss-key-graph:<version>` : write graph definition
* `<acr_name>.azurecr.io/dss-enricher-key:<version>` : enrich WASM module
* `<acr_name>.azurecr.io/dss-enricher-key-graph:<version>` : enrich graph definition

Once the artifacts are available in ACR, the dataflow graphs resolve and begin processing.

## Updating the Version

Each operator is versioned independently from its own `Cargo.toml`. To release a new version of an operator:

1. Increment the version in the operator's `Cargo.toml` (for example [operators/dss-enricher-key/Cargo.toml](operators/dss-enricher-key/Cargo.toml)):

   ```toml
   [package]
   version = "2.0.0"
   ```

2. Update the matching graph artifact reference in your `terraform.tfvars`:

   ```hcl
   artifact = "dss-enricher-key-graph:2.0.0"
   ```

3. Rebuild and push the updated operator:

   ```bash
   ./scripts/build-wasm.sh dss-enricher-key
   ./scripts/push-to-acr.sh <acr_name> dss-enricher-key
   ```

## Configuration

### Write Operator Parameters (`msg-to-dss-key`)

| Parameter    | Required | Default | Description                                                                                                               |
|--------------|----------|---------|---------------------------------------------------------------------------------------------------------------------------|
| `keyPath`    | Yes      | (none)  | RFC 6901 JSON Pointer to the field used as the DSS key. Examples: `/id`, `/data/record_id`, `/items/0/id`                 |
| `keyPrefix`  | No       | (empty) | String prepended to the extracted key value. Example: `device:` produces keys like `device:sensor-001`                    |
| `ttlSeconds` | Yes      | (none)  | Time-to-live in seconds for the DSS entry. Use `0` for no expiration.                                                     |
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

### Enrich Operator Parameters (`dss-enricher-key`)

| Parameter    | Required | Default | Description                                                                                                                                                    |
|--------------|----------|---------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `keyPath`    | Yes      | (none)  | RFC 6901 JSON Pointer to the field used as the DSS lookup key. Examples: `/id`, `/data/entityId`, `/items/0/ref`                                               |
| `keyPrefix`  | No       | (empty) | String prepended to the extracted key value. Example: `device:` produces key `device:sensor-001`                                                               |
| `outputPath` | No       | (empty) | JSON path where enriched data is injected. Empty merges at root. Example: `context` nests under `$.context`                                                    |
| `fields`     | No       | `*`     | Comma-separated list of fields to extract from the stored record. `*` extracts all top-level fields. Example: `location,calibration,name`                      |
| `onMissing`  | No       | `skip`  | Behavior when key is not found in DSS: `skip` (passthrough with warning), `error` (return error, drops message), `default` (inject empty object at outputPath) |
| `onError`    | No       | `skip`  | Behavior on state store errors: `skip` (passthrough with warning), `error` (return error)                                                                      |

#### Enrich Validation Rules

The init phase returns `false` and halts the dataflow when any of the following validations fail:

* `keyPath` must be non-empty and start with `/` (RFC 6901)
* `outputPath` if provided must be a valid identifier (alphanumeric, underscores, dots)
* `fields` if provided must be non-empty comma-separated identifiers
* `onMissing` must be one of `skip`, `error`, or `default`
* `onError` must be one of `skip` or `error`

#### Enrich Configuration Examples

Merge all stored fields at the root:

```text
keyPath=/deviceId
keyPrefix=device:
```

* Incoming: `{"deviceId": "sensor-001", "temp": 22}` and DSS `device:sensor-001` = `{"location": "lab"}`
* Output: `{"deviceId": "sensor-001", "temp": 22, "location": "lab"}`

Select fields under a namespace:

```text
keyPath=/deviceId
keyPrefix=device:
outputPath=deviceContext
fields=name,category
```

* Incoming: `{"deviceId": "X", "value": 1}` and DSS `device:X` = `{"name": "Widget", "category": "A", "internal_code": "secret"}`
* Output: `{"deviceId": "X", "value": 1, "deviceContext": {"name": "Widget", "category": "A"}}`

Strict mode that drops messages without matching state:

```text
keyPath=/deviceId
keyPrefix=device:
onMissing=error
```

Messages referencing unknown device IDs are dropped with an error.

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

| Aspect               | Behavior                                                                                                                                     |
|----------------------|----------------------------------------------------------------------------------------------------------------------------------------------|
| Dataset source       | DSS key specified as a static string in the DataflowGraph resource                                                                           |
| Data format          | NDJSON (newline-delimited JSON). A single JSON object without a trailing newline is valid single-record NDJSON.                              |
| Match expression     | Boolean expression comparing `$source` fields against `$context` fields                                                                      |
| Context access       | `$context(<alias>).<field>` in map, filter, or branch expressions                                                                            |
| Supported transforms | Built-in map, filter, and branch transforms                                                                                                  |
| Dynamic key lookup   | Not supported by built-in enrichment. Use the [`dss-enricher-key`](#enrich-operator-parameters-dss-enricher-key) operator in this component. |

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

### Write init validation errors

The `msg-to-dss-key` operator returns `false` during init if required configuration is missing or invalid. Check the dataflow logs for specific error messages:

* `Missing required configuration: 'keyPath'`: Add the `keyPath` parameter to the graph definition.
* `Missing required configuration: 'ttlSeconds'`: Add the `ttlSeconds` parameter to the graph definition.
* `Invalid keyPath '...'`: The value must start with `/` and follow RFC 6901 JSON Pointer syntax.
* `Invalid onMissing value '...'`: Use `skip` or `error`.

### Enriched messages pass through without enrichment

When `onMissing=skip` (the default) and `onError=skip`, the `dss-enricher-key` operator returns the original message whenever the key is missing or a read fails. Check the dataflow logs for warnings:

* `Key '...' not found in state store`: The write pipeline has not stored this key, or its TTL expired. Confirm the write pipeline is running and that both operators use the same `keyPath` and `keyPrefix`.
* `keyPath '...' not found in message`: The incoming message does not contain the configured pointer path. Verify the source topic payload shape.
* `Stored value for key '...' is not valid JSON`: The DSS record was not written as JSON. Confirm the write side stores JSON objects.

### Enrich init validation errors

The `dss-enricher-key` operator returns `false` during init if required configuration is missing or invalid. Check the dataflow logs for specific error messages:

* `Missing required configuration: 'keyPath'`: Add the `keyPath` parameter to the graph definition.
* `Invalid keyPath '...'`: The value must start with `/` and follow RFC 6901 JSON Pointer syntax.
* `Invalid onMissing value '...'`: Use `skip`, `error`, or `default`.
* `Invalid onError value '...'`: Use `skip` or `error`.

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

The `dss-enricher-key` operator carries the same constraints on the read path. It performs one synchronous `state_store::get` per message, so avoid high-speed topics where each message adds read latency and broker memory pressure. The AIO runtime caches frequently accessed keys, so repeated lookups for the same key benefit from that layer. Enriched messages are larger than originals, so monitor broker memory profiles when merging large stored records.

## Example: Food Manufacturing Lot Traceability

A food factory operates two production lines on different schedules. The **Filling Line (Line A)** fills containers with product throughout the day and publishes lot metadata to MQTT (~1,000 lots/day). The **Packaging Line (Line B)** picks up completed lots hours or a day later. When packaging begins, Line B emits an event referencing the lot number. This event needs the original production context from Line A to produce a consolidated traceability record for compliance and analytics.

```text
                        MQTT Broker
                       ┌───────────┐
  Filling Line A       │           │       Packaging Line B
  (lot completion)     │           │       (packaging start)
        │              │           │              │
        ▼              │           │              ▼
  ┌───────────┐        │           │        ┌───────────┐
  │ Topic:    │        │           │        │ Topic:    │
  │ lots/     │        │           │        │ packaging/│
  │ completed │        │           │        │ started   │
  └─────┬─────┘        │           │        └─────┬─────┘
        │              │           │              │
        ▼              │           │              ▼
  ┌──────────────┐     │           │     ┌──────────────────┐
  │ Pipeline A   │     │           │     │ Pipeline B       │
  │ msg_to_dss   │     │           │     │ dss_enricher_key │
  │ key          │     │           │     │ from DSS         │
  └──────┬───────┘     │           │     └────┬────────┬────┘
         │             │           │          │        │
         ▼             │           │          │        ▼
  ┌─────────────┐      │           │          │  ┌──────────┐
  │ DSS         │      │           │          │  │ Enriched │
  │ lot:LOT-001 │◄─────┼───────────┼──────────┘  │ message  │
  │ lot:LOT-002 │      │           │             │ to cloud │
  │ ...         │      │           │             └──────────┘
  └─────────────┘      └───────────┘
```

### Pipeline A: Write lot metadata to DSS

Line A publishes a message each time a lot is completed. Pipeline A uses `msg-to-dss-key` to store the full payload in the DSS with a 48-hour TTL, providing a window for Line B to consume the lot.

**Graph configuration**: `keyPath=/lotId`, `keyPrefix=lot:`, `ttlSeconds=172800`

Example message on `lots/completed`:

```json
{
  "lotId": "LOT-2026-04-08-0042",
  "productType": "apple-sauce-500ml",
  "fillWeight": 502.3,
  "qualityGrade": "A",
  "lineId": "filling-line-A",
  "completedAt": "2026-04-08T09:14:00Z"
}
```

Result: DSS key `lot:LOT-2026-04-08-0042` stores the full JSON payload.

### Pipeline B: Enrich packaging events with lot context

When Line B begins packaging a lot, it publishes a lean event referencing the lot number. Each event references a different lot, so the DSS key is known only at runtime. Built-in enrichment cannot help here because its `datasets` configuration requires a static key string fixed at deployment time. Pipeline B uses the `dss-enricher-key` operator, which builds the lookup key dynamically from each message and merges the stored lot metadata into the outgoing event.

Example message on `packaging/started`:

```json
{
  "lotId": "LOT-2026-04-08-0042",
  "packagingLineId": "packaging-line-B",
  "containerId": "CNT-7891",
  "startedAt": "2026-04-08T14:22:00Z"
}
```

Pipeline B configures `dss-enricher-key` to construct the same key Pipeline A wrote (`lot:` prepended to the `lotId` value) and merge the selected lot fields into the message at the root.

**Graph configuration**: `keyPath=/lotId`, `keyPrefix=lot:`, `fields=productType,fillWeight,qualityGrade,completedAt`

For each packaging event the operator extracts the value at `/lotId`, reads the DSS record at `lot:<lotId>`, and merges the configured fields into the outgoing message. Source fields take precedence, so the event's own `lotId` and timestamps are preserved.

The enriched output sent to the cloud:

```json
{
  "lotId": "LOT-2026-04-08-0042",
  "packagingLineId": "packaging-line-B",
  "containerId": "CNT-7891",
  "startedAt": "2026-04-08T14:22:00Z",
  "productType": "apple-sauce-500ml",
  "fillWeight": 502.3,
  "qualityGrade": "A",
  "completedAt": "2026-04-08T09:14:00Z"
}
```

### Why this works well with these operators

* **Low message rate**: ~1,000 lots/day is well within each operator's design envelope for state store writes and reads.
* **Natural TTL alignment**: A 48-hour TTL covers the typical gap between filling and packaging. Expired lots that were never packaged are automatically cleaned up.
* **`onMissing` safety net**: If Pipeline B references a lot that hasn't been produced yet or whose TTL has expired, the `dss-enricher-key` `onMissing` configuration controls whether the message passes through with a warning (`skip`) or is dropped (`error`).
* **Dynamic key lookup**: Each packaging event references a different lot, so the DSS key is known only at runtime. The `dss-enricher-key` operator builds the key from message content, which built-in enrichment with static `datasets` keys cannot do.

## Limitations

### Write operator (`msg-to-dss-key`)

* `onMissing=skip` is the default behavior. Messages where the `keyPath` is not found are silently passed through with only a log warning.
* Each key stores a single JSON object. The operator does not produce multi-record NDJSON datasets.
* Dynamic key lookup at enrichment time (where the key name is determined from the incoming message) is not supported by built-in enrichment. The [`dss-enricher-key`](#read-and-enrich-side-dss-enricher-key) operator in this component performs this dynamic-key enrichment, matching the same `keyPath` and `keyPrefix` written here.
* Not designed for high-throughput telemetry. See [Capacity and Performance Considerations](#capacity-and-performance-considerations) for sizing guidance.

### Enrich operator (`dss-enricher-key`)

* Each operator invocation looks up exactly one key. Multi-key enrichment that correlates against an array of IDs requires a custom operator or multiple chained instances.
* Only top-level field extraction is supported in `fields`. Nested field selection requires `*` (all fields) with downstream post-processing.
* The operator does not subscribe to KEYNOTIFY. State changes are reflected only on the next `get` call, not reactively.
* Source fields always take precedence during root-level merge. Use `outputPath` to isolate enrichment data when override behavior is needed.

## References

* [Develop WASM Modules for AIO](https://learn.microsoft.com/azure/iot-operations/develop-edge-apps/howto-develop-wasm-modules?tabs=rust)
* [Use WASM with Data Flow Graphs](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/howto-dataflow-graph-wasm?tabs=portal)
* [WASM Module Host APIs](https://learn.microsoft.com/azure/iot-operations/develop-edge-apps/concepts-wasm-modules#host-apis)
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
