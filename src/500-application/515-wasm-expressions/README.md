---
title: WASM Expressions Operator Library
description: Extensible WASM map operator library closing dataflow expression gaps, starting with a deterministic UTC datetime operator
author: Edge AI Team
ms.date: 2026-06-10
ms.topic: reference
keywords:
  - wasm
  - datetime
  - expressions
  - azure-iot-operations
  - dataflow
estimated_reading_time: 8
---

## WASM Expressions Operator Library

Extensible WASM map operator library that fills expression gaps in Azure IoT Operations dataflow graphs. Each operator is a self-contained crate under `operators/`, built and published as its own OCI artifact. The first operator, `datetime`, provides deterministic UTC timestamp parsing, formatting, reformatting, duration math, and part extraction.

```text
input -> [datetime] -> output
```

## Architecture

Each operator implements a single `#[map_operator]` using the [Azure IoT Operations WASM SDK](https://learn.microsoft.com/azure/iot-operations/develop-edge-apps/howto-develop-wasm-modules?tabs=rust). A map operator returns the full message so the graph continues, and new fields are written into the JSON payload by JSON Pointer.

The `datetime` operator is mode driven. A single `mode` configuration key selects the function (`parse`, `format`, `reformat`, `duration`, or `parts`) for each graph node. Chain multiple `datetime` nodes to derive several fields.

The operator follows a two-phase lifecycle:

* Init phase: reads the configuration keys from `ModuleConfiguration.properties`, validates them, and stores the result in a `OnceLock` for write-once, read-many access. Returns `false` to halt the dataflow when validation fails, giving fast failure at deployment time.
* Process phase: parses the JSON payload, applies the selected mode, writes the result at the configured `outputPath`, and returns the message with all existing fields preserved.

Error handling is passthrough first. When input is missing or malformed, the operator logs a warning and returns the message unchanged, so one bad message never drops the flow. Set `onMissing` to `error` to drop the message instead.

The operator is deterministic and UTC only. It never calls a wall clock such as `Utc::now()`, and no `now` mode is shipped. When a node needs an ingestion time, set `inputSource` to `messageTimestamp` to read the host-stamped hybrid logical clock (HLC) wall-clock time. This keeps results reproducible and removes any WASI clock capability requirement.

## Folder Structure

```text
515-wasm-expressions/
├── .cargo/
│   └── config.toml                 # WASM target and AIO SDK registry
├── .nobuild                        # Excludes component from Docker build pipeline
├── README.md                       # This file
├── operators/
│   └── datetime/
│       ├── Cargo.toml              # Package definition (cdylib)
│       └── src/
│           └── lib.rs              # Mode-driven map operator implementation
├── resources/
│   └── graphs/
│       └── graph-datetime.yaml     # WASM graph definition (OCI artifact)
└── scripts/
    ├── build-wasm.sh               # Build operator WASM modules
    └── push-to-acr.sh              # Push modules and graphs to ACR
```

## Prerequisites

* [Rust toolchain](https://rustup.rs/) with the `wasm32-wasip2` target
* [ORAS CLI](https://oras.land/docs/installation) for pushing to a container registry
* [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with container registry access
* An Azure Container Registry (ACR) instance

## Deployment

### Step 1: Install WASM Target

```bash
rustup target add wasm32-wasip2
```

### Step 2: Build the Module

Run the build script from the application root:

```bash
./scripts/build-wasm.sh
```

The compiled WASM module is output to `operators/datetime/target/wasm32-wasip2/release/datetime.wasm`.

### Step 3: Push to Azure Container Registry

Push the compiled module and graph definition to your Azure Container Registry using the provided script. Pass your ACR name as an argument (without the `.azurecr.io` suffix). The script tags the artifacts with the version from `Cargo.toml` and pushes to ACR.

```bash
./scripts/push-to-acr.sh <acr_name>
```

This pushes:

* `<acr_name>.azurecr.io/datetime:<version>` : WASM module
* `<acr_name>.azurecr.io/datetime-graph:<version>` : Graph definition

Once the artifacts are available in ACR, the dataflow graph resolves and begins processing.

## Configuration

One operator runs one `mode` per graph node. All values are strings, matching the dataflow configuration contract.

| Config key    | Modes that use it                        | Purpose                                                                     |
|---------------|------------------------------------------|-----------------------------------------------------------------------------|
| `mode`        | all                                      | `parse` \| `format` \| `reformat` \| `duration` \| `parts`                  |
| `inputSource` | parse, format, reformat, parts, duration | `payload` (default, uses `inputPath`) \| `messageTimestamp` (host HLC)      |
| `inputPath`   | parse, format, reformat, parts, duration | JSON Pointer (RFC 6901) to the source field when `inputSource` is `payload` |
| `inputPath2`  | duration                                 | JSON Pointer to the second timestamp for the duration diff                  |
| `outputPath`  | all                                      | JSON Pointer where the result is written                                    |
| `inputFormat` | reformat, parse (optional)               | strftime parse layout when the input is not RFC 3339                        |
| `format`      | format, reformat                         | strftime output layout, e.g. `%Y-%m-%dT%H:%M:%S%.3fZ` or `%Y-%m-%d %H:%M`   |
| `unit`        | duration                                 | `ms` \| `seconds` \| `minutes` \| `hours` (default `ms`)                    |
| `epochUnit`   | parse, format                            | `ms` \| `seconds`, epoch granularity in and out (default `ms`)              |
| `parts`       | parts                                    | comma list: `year,month,day,hour,minute,second,weekday,ordinal`             |
| `onMissing`   | all                                      | `skip` (default, passthrough with warning) \| `error` (drops the message)   |

### Mode Semantics

* `parse`: RFC 3339 string at `inputPath` (or the host HLC timestamp when `inputSource` is `messageTimestamp`) to an epoch number (`epochUnit`) at `outputPath`. Feeds downstream built-in numeric expressions.
* `format`: epoch number at `inputPath` (or the host HLC timestamp when `inputSource` is `messageTimestamp`) to a formatted UTC string (`format`) at `outputPath`.
* `reformat`: timestamp string at `inputPath` (RFC 3339 or `inputFormat`) to a restyled string (`format`) at `outputPath`.
* `duration`: two timestamps (`inputPath`, `inputPath2`, either may be the host HLC timestamp via `inputSource`) to a numeric diff in `unit` at `outputPath`. Computes datediff and age since ingestion without a wall clock.
* `parts`: timestamp string at `inputPath` to an object of the requested `parts` at `outputPath`.

## Example: Lot Age Enrichment

This example extends the food manufacturing lot traceability use case from
[514-wasm-msg-to-dss](../514-wasm-msg-to-dss/README.md#example-food-manufacturing-lot-traceability).
In that use case Pipeline A writes lot metadata (including `completedAt`) to the
distributed state store, and Pipeline B enriches each packaging event with the
stored lot fields. The enriched packaging event therefore carries both the
event's `startedAt` and the lot's `completedAt`, which is everything the
`datetime` operator needs to compute how old a lot is when packaging begins.

Chain the `datetime` operator after Pipeline B to derive the lot age. Two
`duration` nodes read the same pair of timestamps and write one field each, so
the message gains both `lotAgeMinutes` and `lotAgeHours` while every original
field passes through unchanged. The operator parses the RFC 3339 strings
directly, so no manual epoch conversion is required. When a downstream built-in
numeric expression needs the raw epoch instead, add a `parse` node to emit
`completedAt` as `completedEpochMs` and compute the difference with built-in math.

The enriched message arriving from Pipeline B:

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

The first node computes the lot age in minutes:

| Config key   | Value            |
|--------------|------------------|
| `mode`       | `duration`       |
| `inputPath`  | `/startedAt`     |
| `inputPath2` | `/completedAt`   |
| `outputPath` | `/lotAgeMinutes` |
| `unit`       | `minutes`        |

The second node reuses the same timestamps with `unit = hours` and writes `/lotAgeHours`. Because `duration` computes `startedAt - completedAt`, both results are positive for a lot completed before packaging starts.

The message returned to the destination topic, with the two derived fields appended:

```json
{
  "lotId": "LOT-2026-04-08-0042",
  "packagingLineId": "packaging-line-B",
  "containerId": "CNT-7891",
  "startedAt": "2026-04-08T14:22:00Z",
  "productType": "apple-sauce-500ml",
  "fillWeight": 502.3,
  "qualityGrade": "A",
  "completedAt": "2026-04-08T09:14:00Z",
  "lotAgeMinutes": 308,
  "lotAgeHours": 5
}
```

A ready-to-apply dataflow graph that wires this pipeline is in [dataflow-graphs-datetime.tfvars.example](../../../blueprints/full-single-node-cluster/terraform/dataflow-graphs-datetime.tfvars.example).

## Updating the Version

To release a new version of the module:

1. Increment the version in [operators/datetime/Cargo.toml](operators/datetime/Cargo.toml):

   ```toml
   [package]
   version = "2.0.0"
   ```

2. Update the graph artifact reference in your `terraform.tfvars` to match the new version:

   ```hcl
   artifact = "datetime-graph:2.0.0"
   ```

3. Rebuild and push the updated artifacts:

   ```bash
   ./scripts/build-wasm.sh
   ./scripts/push-to-acr.sh <acr_name>
   ```
