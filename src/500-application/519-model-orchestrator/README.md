---
title: Model Orchestrator
description: Fans each request out to multiple models through the MQTT predict adapter, interprets results with typed adapters, and publishes one aggregate decision with explicit partial and timeout semantics
author: Edge AI Team
ms.date: 2026-10-08
ms.topic: reference
estimated_reading_time: 8
keywords:
  - azure iot operations
  - mqtt
  - model ensemble
  - orchestration
  - anomaly detection
  - foundry local
---

## Overview

The model orchestrator evaluates one input against an ensemble of models in
parallel and publishes a single decision. It sends each request to every
configured model through the
[MQTT predict adapter](../518-mqtt-predict-adapter/README.md), interprets each
response with a typed result adapter, and aggregates the outcomes with explicit
partial and timeout semantics.

The orchestrator follows the
[custom workload messaging contract](../../../docs/solution-technology-paper-library/aio-messaging-design.md#custom-workload-messaging-contracts)
for versioned topics, CloudEvents attributes, workload identity, and
payload-safe logging.

```text
client ──► orchestrate/v1/{client}/ensemble/{ensemble-id}/request
                     │
              model orchestrator ──► predict/v1/{orchestrator}/model/{model-a}/request ──► predict adapter
                     │             ──► predict/v1/{orchestrator}/model/{model-b}/request ──► predict adapter
                     │ ◄── predict/v1/{orchestrator}/model/+/response
client ◄── orchestrate/v1/{client}/ensemble/{ensemble-id}/response
```

## Topics

| Direction          | Topic                                                     |
|--------------------|-----------------------------------------------------------|
| Request            | `orchestrate/v1/{client}/ensemble/{ensemble-id}/request`  |
| Response           | `orchestrate/v1/{client}/ensemble/{ensemble-id}/response` |
| To predict adapter | `predict/v1/{predict-client}/model/{model-id}/request`    |
| From adapter       | `predict/v1/{predict-client}/model/+/response`            |

* Each release serves one ensemble, identified by `ENSEMBLE_ID`.
* `{predict-client}` is `PREDICT_CLIENT`, which the Helm chart sets to the
  release's full name so each release receives only its own model responses.
  Each model request carries a per-request MQTTv5 Correlation Data value that
  the predict adapter echoes, so responses are matched without parsing
  payloads.
* The last segments of predict topics are `PREDICT_REQUEST_KIND` and
  `PREDICT_RESPONSE_KIND`, which must match the adapter's `REQUEST_KIND` and
  `RESPONSE_KIND`.
* The orchestration and predict domains must differ, so the orchestrator never
  subscribes to its own output.
* Retained messages are ignored and counted as `retained`.

## Request

The request body is forwarded unchanged to every model, so it uses the
[predict adapter request forms](../518-mqtt-predict-adapter/README.md#request):
a numeric tensor in `inputs`, or Base64 `data` with a `content_type`. The
orchestrator applies the adapter's rules before fanning out, so a request the
adapter would reject gets one `rejected` response instead of one failure per
model: tensors must be rectangular, up to four dimensions, and contain only
finite numbers.

The optional `context` object, up to 1 KiB, is returned unchanged on the
aggregate and on rejections. A `context` that isn't an object or is too large
gets a single `rejected` response with `INVALID_PAYLOAD`.

```json
{ "inputs": [[0.12, 0.34, 0.56]], "context": { "asset_id": "asset-01" } }
```

Optional MQTTv5 properties on the request:

| Property                    | Use                                                                      |
|-----------------------------|--------------------------------------------------------------------------|
| User property `id`          | Returned as `request_id`; repeats while the first is pending are dropped |
| User property `traceparent` | Propagated to model requests and the response                            |
| Correlation Data            | Echoed on the response, up to 256 bytes                                  |

A repeat of a pending request, with the same client and `id`, gets no response
of its own and is counted as `duplicate_request`. The pending request's single
response answers both, so a client that retries with the same `id` and
Correlation Data never receives two answers for one correlation value.

## Typed Result Adapters

Each model declares how to read its outputs. The orchestrator never searches a
response for arbitrary numbers; a response that doesn't match its adapter is
`rejected` with `INVALID_RESULT`.

| Kind    | Fields                                                     | Anomaly when                                     |
|---------|------------------------------------------------------------|--------------------------------------------------|
| `score` | `field`, `threshold`                                       | The finite number at `field` exceeds `threshold` |
| `label` | `field`, `anomaly_labels`, optional `score_field` (0 to 1) | The string at `field` is in `anomaly_labels`     |

Field paths are up to four dot-separated keys, such as `prediction.label`.

```json
[
  { "id": "vibration-anomaly", "result": { "kind": "score", "field": "score", "threshold": 0.5 } },
  {
    "id": "acoustic-classifier",
    "result": {
      "kind": "label",
      "field": "prediction.label",
      "anomaly_labels": ["fault"],
      "score_field": "prediction.confidence"
    }
  }
]
```

## Response

```json
{
  "schema_version": "1.0",
  "ensemble_id": "default",
  "request_id": "req-2",
  "status": "partial",
  "decision": "anomaly",
  "retryable": true,
  "counts": { "succeeded": 1, "failed": 0, "timed_out": 1, "rejected": 0 },
  "duration_ms": 4031,
  "max_score": 0.8,
  "models": [
    { "model_id": "vibration-anomaly", "status": "succeeded", "anomaly": true, "score": 0.8, "latency_ms": 5 },
    { "model_id": "slow-model", "status": "timed_out", "error_code": "TIMEOUT" }
  ],
  "context": { "asset_id": "asset-01" }
}
```

Each model ends in exactly one state:

| Model status | Meaning                                                            |
|--------------|--------------------------------------------------------------------|
| `succeeded`  | The adapter interpreted the output                                 |
| `failed`     | The predict adapter returned an error; its code is in `error_code` |
| `rejected`   | The response didn't match the contract or its typed adapter        |
| `timed_out`  | No response before `TIMEOUT_SECONDS`, or the orchestrator stopped  |

The aggregate `status` is `complete` when every model succeeded, `partial` when
some did, and `failed` when none did. A failed or timed-out model never erases
another model's successful result. The `decision` is `anomaly` when any
succeeded model flags one, `normal` only when every model succeeded without an
anomaly, and `unknown` otherwise. `retryable` is `true` when at least one
model didn't succeed for a reason that may clear on a later request: it timed
out, or the adapter returned a retryable error such as `BUSY` or
`BACKEND_TIMEOUT`.

Each request gets exactly one response. Model responses that arrive after the
aggregate is published are counted as `late`, and repeated responses for the
same model are counted as `duplicate`; neither changes a published result.

Requests that can't be processed get a `rejected` response with an error code:
`INVALID_JSON`, `INVALID_PAYLOAD`, `PAYLOAD_TOO_LARGE`, or `BUSY` (retryable,
when `MAX_PENDING` requests are in progress).

On SIGTERM or SIGINT, the orchestrator unsubscribes from requests and publishes
every pending aggregate at once, reporting unanswered models as `timed_out`
with `error_code` `SHUTDOWN`.

## Flow Control and Deadlines

The predict adapter answers `BUSY` instead of queuing when its
`MAX_CONCURRENCY` model calls are in flight. The orchestrator avoids
overrunning it:

* At most `MAX_INFLIGHT_MODEL_CALLS` predict requests are outstanding across
  all pending requests. Further model calls wait in arrival order until a slot
  frees, and calls still waiting at the deadline are reported as `timed_out`.
* A `BUSY` answer is retried after a jittered delay that starts between 50 and
  100 ms and doubles up to 1 second, while the deadline allows. When no time
  remains, the model is reported as `failed` with `BUSY`.
* Each predict request carries an MQTTv5 Message Expiry Interval set to the
  time left before the deadline, rounded up to whole seconds. The adapter drops
  requests that expire before it reads them and stops calling the model when
  the interval runs out, so abandoned calls don't hold adapter capacity.

Size the two components together:

* Keep `MAX_INFLIGHT_MODEL_CALLS` at or below the adapter's `MAX_CONCURRENCY`,
  less any capacity other clients of the same adapter use.
* Keep the adapter's `BACKEND_TIMEOUT_SECONDS` × `BACKEND_ATTEMPTS` below
  `TIMEOUT_SECONDS`, so a model call fails with a code before the orchestrator
  gives up on it.

## Configuration

| Variable                   | Default              | Description                                         |
|----------------------------|----------------------|-----------------------------------------------------|
| `MODELS`                   | Required             | JSON list of models and their typed result adapters |
| `ENSEMBLE_ID`              | `default`            | Ensemble topic segment and CloudEvents `subject`    |
| `TIMEOUT_SECONDS`          | `10`                 | Deadline per request, up to 600                     |
| `MAX_PENDING`              | `100`                | Requests in progress before new ones get `BUSY`     |
| `MAX_INFLIGHT_MODEL_CALLS` | `4`                  | Outstanding predict requests, 1 to 64               |
| `MAX_REQUEST_BYTES`        | `1048576`            | Largest accepted request, up to 16 MiB              |
| `TOPIC_DOMAIN`             | `orchestrate`        | First segment of orchestration topics               |
| `PREDICT_DOMAIN`           | `predict`            | First segment of predict adapter topics             |
| `PREDICT_CLIENT`           | `model-orchestrator` | Client segment on predict adapter topics            |
| `PREDICT_REQUEST_KIND`     | `request`            | Last segment of predict request topics              |
| `PREDICT_RESPONSE_KIND`    | `response`           | Last segment of predict response topics             |
| `EVENT_SOURCE`             | `model-orchestrator` | CloudEvents `source`                                |

The broker connection uses the same variables as the AIO SDKs:
`AIO_BROKER_HOSTNAME`, `AIO_BROKER_TCP_PORT`, `AIO_MQTT_USE_TLS`,
`AIO_TLS_CA_FILE`, `AIO_SAT_FILE` (set it empty to skip SAT), and
`AIO_MQTT_CLIENT_ID`. Invalid configuration stops the orchestrator with exit
code 2. `AIO_SAT_FILE` requires `AIO_MQTT_USE_TLS`, so the token is never sent
in plain text; set it empty for an unauthenticated local broker.

## Authentication and Authorization

The orchestrator authenticates to the broker with a Kubernetes service account
token through MQTTv5 enhanced authentication, with method `K8S-SAT`, re-reading
the token on every connection attempt.

The chart sets the service account annotation `aio-broker-auth/workload` and
`PREDICT_CLIENT` to the release's full name. For a release named
`ensemble-default`, that's `ensemble-default-model-orchestrator`. Add a rule per
release to the BrokerAuthorization policy already linked to the listener port,
managed through the Azure portal, Bicep, or `az iot ops broker authz apply`, as
described in
[Configure MQTT broker authorization](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/howto-configure-authorization):

```yaml
rules:
  - principals:
      attributes:
        - workload: ensemble-default-model-orchestrator
    brokerResources:
      - method: Connect
        clientIds:
          - "model-orchestrator-*"
      - method: Subscribe
        topics:
          - "orchestrate/v1/+/ensemble/default/request"
          - "predict/v1/ensemble-default-model-orchestrator/model/+/response"
      - method: Publish
        topics:
          - "orchestrate/v1/+/ensemble/default/response"
          - "predict/v1/ensemble-default-model-orchestrator/model/+/request"
```

Every model in `MODELS` must also be in the predict adapter's `ALLOWED_MODELS`.

## Logging

Logs never contain request or model payloads. The orchestrator logs each
aggregate status and decision, rejection codes, and these counters every 60
seconds and at shutdown: `received`, `complete`, `partial`, `failed`,
`rejected`, `late`, `duplicate`, `duplicate_request`, `retained`,
`busy_retries`, `unhandled`, `publish_failed`, and `connects`. `unhandled`
counts messages that raised an unexpected error; only the error type is
logged, and the orchestrator keeps running.

## Build

Build from this component directory. No public image is published, so push the
image to a registry you own:

```bash
cd src/500-application/519-model-orchestrator
docker build -f services/model-orchestrator/Dockerfile -t model-orchestrator:0.1.0 .
```

## Deploy

Define the ensemble in a values file, such as `ensemble.yaml`:

```yaml
orchestrator:
  models:
    - id: vibration-anomaly
      result: { kind: score, field: score, threshold: 0.5 }
```

```bash
helm install ensemble-default \
  src/500-application/519-model-orchestrator/charts/model-orchestrator \
  --namespace azure-iot-operations \
  --set image.repository=<your-registry>/model-orchestrator \
  -f ensemble.yaml
```

The chart creates a dedicated service account that doesn't mount an API token,
projects the `aio-internal` broker token, sets a unique per-pod
`AIO_MQTT_CLIENT_ID` through the Downward API, and runs one replica with the
`Recreate` strategy, because pending fan-out state is held in memory. Unless
overridden, `orchestrator.predictClient` and the `aio-broker-auth/workload`
annotation default to the release's full name. Rendering fails when
`orchestrator.models` is empty.

## Local Development

`docker-compose.yml` runs the orchestrator with a local Mosquitto broker, the
[MQTT predict adapter](../518-mqtt-predict-adapter/README.md), and the
adapter's mock `/v1/predict` model, which returns the mean of the input as
`score`, optionally after `MOCK_LATENCY_SECONDS`. The default ensemble has two
models with thresholds 0.5 and 0.7. Copy `.env.example` to `.env` to change the
ensemble or the adapter limits:

```bash
cd src/500-application/519-model-orchestrator
cp .env.example .env
docker compose up --build -d
docker compose exec mosquitto-broker mosquitto_sub -V 5 -t 'orchestrate/v1/local/ensemble/default/response' &
docker compose exec mosquitto-broker mosquitto_pub -V 5 \
  -t orchestrate/v1/local/ensemble/default/request -m '{"inputs": [0.6, 0.6]}'
```

## Testing

```bash
cd src/500-application/519-model-orchestrator/services/model-orchestrator
pip install --require-hashes -r requirements.txt
pip install pytest
python3 -m pytest
```

Unit tests cover configuration validation, typed result adapters, aggregation
and decision rules, request validation and context, in-flight limits and
queuing, `BUSY` retries, Message Expiry, timeouts, shutdown, late, duplicate,
retained, and deeply nested messages, and request rejection.
