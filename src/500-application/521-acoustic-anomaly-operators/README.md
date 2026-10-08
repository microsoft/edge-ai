---
title: Acoustic Anomaly Operators
description: WASM data flow graph operators that featurize audio into log-mel rows for an autoencoder served through the MQTT predict adapter, and turn model scores into anomaly verdicts
author: Edge AI Team
ms.date: 2026-10-08
ms.topic: reference
estimated_reading_time: 11
keywords:
  - azure iot operations
  - data flow graphs
  - wasm
  - acoustic anomaly detection
  - log-mel features
  - foundry local
---

## Overview

This component provides two WASM map operators for Azure IoT Operations (AIO)
data flow graphs that detect acoustic anomalies with an autoencoder:

| Operator             | Role                                                                                               |
|----------------------|----------------------------------------------------------------------------------------------------|
| `featurize-acoustic` | Converts a mono audio window into 640-dimensional log-mel rows and wraps them as a predict request |
| `threshold-anomaly`  | Reads the model's score from the predict response and emits an anomaly verdict                     |

The model runs outside the graph. Two data flow graphs are bridged over MQTT by
the [MQTT predict adapter](../518-mqtt-predict-adapter/README.md), which calls a
predictive model endpoint such as a Foundry Local `/v1/predict` deployment. Any
autoencoder that accepts the feature rows and returns a reconstruction score
works.

```text
audio topic ──► [graph: acoustic-featurize] ──► predict/v1/acoustic-anomaly/model/{model}/request
                                                         │
                                                 MQTT predict adapter ──► model /v1/predict
                                                         │
verdict topic ◄── [graph: acoustic-threshold] ◄── predict/v1/acoustic-anomaly/model/{model}/response
```

Neither graph subscribes to a topic it publishes to.

## Features

`featurize-acoustic` follows the
[DCASE 2020 Task 2](https://dcase.community/challenge2020/task-unsupervised-detection-of-anomalous-sounds)
autoencoder baseline:

| Step        | Setting                                                                           |
|-------------|-----------------------------------------------------------------------------------|
| Spectrogram | Power STFT, `n_fft` 1024, hop 512, periodic Hann window, centered reflect padding |
| Mel bands   | 128 Slaney-normalized bands from 0 Hz to Nyquist                                  |
| Scaling     | `10 * log10(power + epsilon)`, with epsilon the float64 machine epsilon           |
| Rows        | 5 consecutive frames concatenated frame-major: 640 values per window              |

Reflect padding matches the baseline, which ran on librosa 0.6 with
`center=True` and `pad_mode='reflect'`. Newer librosa releases pad with zeros by
default, which changes the first and last windows of every clip, so train and
calibrate the model with `pad_mode="reflect"` as well.

A unit test compares the output with [librosa](https://librosa.org/) 0.11
(`pad_mode="reflect"`) on a deterministic signal within 0.05 dB.
`scripts/generate-librosa-reference.py` regenerates the fixture.

A clip of `n` samples yields `floor(n / 512) - 3` windows, so at least 2048
samples are needed. Only the first `max_batch_size` windows are computed and
forwarded; the rest are dropped and counted, so size clips to the model's batch
limit.

Each serialized row is about 7 KB, so the predict adapter's default
`MAX_REQUEST_BYTES` of 1 MiB fits about 140 rows. Requests larger than
`max_request_bytes` are rejected rather than truncated; lower `max_batch_size`
or raise both limits together.

## Messages

`featurize-acoustic` input, such as the acoustic readings from the
[sensor simulator](../517-sensor-simulator/README.md):

```json
{ "asset_id": "asset-01", "sensor_id": "sensor-01", "sample_rate": 16000, "samples": [0.01, -0.02] }
```

* `sample_rate` must be an integer from 8,000 to 192,000, and must equal
  `expected_sample_rate` when that parameter is set.
* `samples` must be finite numbers in `[-1, 1]`, from 2,048 up to `max_samples`.
* Other fields are ignored, except the `context_fields`, which are copied into
  the request `context` when they're strings up to 128 bytes or numbers. The
  serialized `context` must fit the predict adapter's 1 KiB limit, measured as
  the adapter serializes it, or the message is rejected.

The sensor simulator accepts a wider range than this operator: any positive
`ACOUSTIC_SAMPLE_RATE` up to 192,000 and `ACOUSTIC_SAMPLE_COUNT` from 1 to
65,536. Configure it with a rate of at least 8,000 Hz and at least 2,048
samples. Its default of 2,048 samples yields exactly one window, so the
threshold aggregation has a single score and `mean` and `max` are equivalent;
raise `ACOUSTIC_SAMPLE_COUNT` to score several windows per reading.

`featurize-acoustic` output, the predict adapter request:

```json
{ "inputs": [[-21.4, -23.0]], "context": { "asset_id": "asset-01", "sensor_id": "sensor-01" } }
```

`threshold-anomaly` reads the adapter response, takes the value at
`score_field` in the model `outputs`, aggregates per-window values with `mean`
or `max`, and publishes:

```json
{
  "schema_version": "1.0",
  "model_id": "acoustic-autoencoder",
  "status": "success",
  "anomaly": true,
  "score": 11.0,
  "threshold": 10.0,
  "aggregation": "mean",
  "windows": 2,
  "context": { "asset_id": "asset-01", "sensor_id": "sensor-01" }
}
```

The score value can be a number, a list of per-window numbers, or a list of
single-value rows. The operator never searches the outputs for other numbers.
A missing or malformed score produces `"status": "error"` with
`"error_code": "INVALID_RESULT"`, and an adapter error passes through with its
code, such as `BACKEND_TIMEOUT`, so failures stay visible downstream.

## Configuration

`featurize-acoustic` graph parameters:

| Parameter              | Default                        | Description                                                      |
|------------------------|--------------------------------|------------------------------------------------------------------|
| `max_batch_size`       | `32`                           | Most rows per request, 1 to 1024                                 |
| `max_samples`          | `960000`                       | Largest accepted `samples` array                                 |
| `max_request_bytes`    | `1048576`                      | Largest serialized request; keep at or below the adapter's limit |
| `expected_sample_rate` | Unset                          | Rejects messages at any other rate, 8,000 to 192,000 Hz when set |
| `context_fields`       | `asset_id,sensor_id,timestamp` | Up to 8 input fields copied into the request context             |

`threshold-anomaly` graph parameters:

| Parameter     | Default  | Description                                                   |
|---------------|----------|---------------------------------------------------------------|
| `threshold`   | Required | Scores greater than this value are anomalies                  |
| `score_field` | `score`  | Up to four dot-separated keys locating the score in `outputs` |
| `aggregation` | `mean`   | `mean` or `max` over per-window scores                        |

The threshold has no default. Calibrate it per model and per machine, for
example from the score distribution of known-healthy recordings processed with
the same reflect padding. The default `score_field` matches the predict
adapter's response example and its local mock model; set it to the key your
model returns.

## Prerequisites

* [Rust toolchain](https://rustup.rs/) with the `wasm32-wasip2` target
* Access to the `aio-sdks` Cargo registry configured in `.cargo/config.toml`
* [ORAS CLI](https://oras.land/docs/installation) for pushing to a container registry
* [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with container registry access
* `envsubst` (GNU gettext) for rendering graph definitions
* An Azure Container Registry (ACR) instance
* Optional: [`cargo-audit`](https://github.com/rustsec/rustsec/tree/main/cargo-audit) for the dependency audit in the build script

## Build

The component is excluded from the container build pipeline (`.nobuild`). The
build script runs clippy against the WASM target, the unit tests on the host,
an optional dependency audit, and the release build:

```bash
cd src/500-application/521-acoustic-anomaly-operators
./scripts/build-wasm.sh
```

Outputs are `operators/<name>/target/wasm32-wasip2/release/<name_with_underscores>.wasm`.

## Deploy

1. Push the modules and graph definitions to your Azure Container Registry.
   The script refuses to overwrite an existing tag unless `ALLOW_OVERWRITE=true`:

   ```bash
   ./scripts/push-to-acr.sh <acr-name>
   ```

   This publishes `featurize-acoustic:1.0.0`, `featurize-acoustic-graph:1.0.0`,
   `threshold-anomaly:1.0.0`, and `threshold-anomaly-graph:1.0.0`.

2. Deploy the [MQTT predict adapter](../518-mqtt-predict-adapter/README.md) with
   the model ID in `adapter.allowedModels`, and authorize its service account on
   the model's `ModelDeployment`.

3. Add both graphs to the `dataflow_graphs` variable in the
   [full-multi-node-cluster](../../../blueprints/full-multi-node-cluster/README.md)
   blueprint `terraform.tfvars`, and set
   `should_include_acr_registry_endpoint = true` so the blueprint creates the
   `acr-<resource_prefix>` registry endpoint the graphs reference. A complete
   example is in
   [dataflow-graphs-acoustic-anomaly.tfvars.example](../../../blueprints/full-multi-node-cluster/terraform/dataflow-graphs-acoustic-anomaly.tfvars.example).
   See also
   [Deploy WebAssembly modules and graph definitions](https://learn.microsoft.com/azure/iot-operations/develop-edge-apps/howto-deploy-wasm-graph-definitions).
   The destinations replace the CloudEvents `type` and `source` user
   properties, because each graph produces a new message type, and keep the
   incoming `id` and `traceparent` so the predict adapter can echo the
   `request_id` and propagate the trace:

   ```hcl
   dataflow_graphs = [
     {
       name = "acoustic-featurize"
       nodes = [
         {
           nodeType = "Source"
           name     = "audio-source"
           sourceSettings = {
             endpointRef = "default"
             dataSources = ["telemetry/v1/sensor-simulator/asset/+/acoustic"]
           }
         },
         {
           nodeType = "Graph"
           name     = "featurize"
           graphSettings = {
             registryEndpointRef = "acr-<resource_prefix>"
             artifact            = "featurize-acoustic-graph:1.0.0"
             configuration = [
               { key = "max_batch_size", value = "32" },
               { key = "context_fields", value = "asset_id,sensor_id,timestamp" }
             ]
           }
         },
         {
           nodeType = "Destination"
           name     = "predict-request"
           destinationSettings = {
             endpointRef     = "default"
             dataDestination = "predict/v1/acoustic-anomaly/model/acoustic-autoencoder/request"
             headers = [
               { actionType = "AddOrReplace", key = "type", value = "edge-ai.predict.request" },
               { actionType = "AddOrReplace", key = "source", value = "acoustic-featurize" }
             ]
           }
         }
       ]
       node_connections = [
         { from = { name = "audio-source" }, to = { name = "featurize" } },
         { from = { name = "featurize" }, to = { name = "predict-request" } }
       ]
     },
     {
       name = "acoustic-threshold"
       nodes = [
         {
           nodeType = "Source"
           name     = "predict-response"
           sourceSettings = {
             endpointRef = "default"
             dataSources = ["predict/v1/acoustic-anomaly/model/acoustic-autoencoder/response"]
           }
         },
         {
           nodeType = "Graph"
           name     = "threshold"
           graphSettings = {
             registryEndpointRef = "acr-<resource_prefix>"
             artifact            = "threshold-anomaly-graph:1.0.0"
             configuration = [
               { key = "threshold", value = "<calibrated-threshold>" },
               { key = "score_field", value = "score" },
               { key = "aggregation", value = "mean" }
             ]
           }
         },
         {
           nodeType = "Destination"
           name     = "verdicts"
           destinationSettings = {
             endpointRef     = "default"
             dataDestination = "anomaly/v1/acoustic-anomaly/model/acoustic-autoencoder/verdict"
             headers = [
               { actionType = "AddOrReplace", key = "type", value = "edge-ai.acoustic-anomaly.verdict" },
               { actionType = "AddOrReplace", key = "source", value = "acoustic-threshold" }
             ]
           }
         }
       ]
       node_connections = [
         { from = { name = "predict-response" }, to = { name = "threshold" } },
         { from = { name = "threshold" }, to = { name = "verdicts" } }
       ]
     }
   ]
   ```

4. Grant the data flow the broker permissions it needs on those topics in the
   BrokerAuthorization policy linked to the listener, and grant the predict
   adapter `Subscribe` on the request topic and `Publish` on the response topic.

## Testing

```bash
cd src/500-application/521-acoustic-anomaly-operators
HOST_TARGET="$(rustc -vV | sed -n 's/host: //p')"
cargo test --target "${HOST_TARGET}" --manifest-path operators/featurize-acoustic/Cargo.toml
cargo test --target "${HOST_TARGET}" --manifest-path operators/threshold-anomaly/Cargo.toml
```

Unit tests cover window framing, reflect padding, librosa parity, mel
filterbank properties, input validation, context and request size limits,
batch truncation, score aggregation, the predict adapter response shape, error
verdicts, and configuration validation.

## Monitoring

Each operator records counters labeled `module=<operator>`:
`featurize-acoustic` records `requests`, `errors`, and `dropped_windows`;
`threshold-anomaly` records `requests`, `anomalies`, `normal`, and `errors`.
Logs never include audio samples, feature values, or model outputs.
