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
* `{predict-client}` defaults to `model-orchestrator`. Each model request
  carries a per-request MQTTv5 Correlation Data value that the predict adapter
  echoes, so responses are matched without parsing payloads.
* The orchestration and predict domains must differ, so the orchestrator never
  subscribes to its own output.

## Request

The request body is forwarded unchanged to every model, so it uses the
[predict adapter request forms](../518-mqtt-predict-adapter/README.md#request):
a numeric tensor in `inputs`, or Base64 `data` with a `content_type`.

Optional MQTTv5 properties on the request:

| Property                    | Use                                                                               |
|-----------------------------|-----------------------------------------------------------------------------------|
| User property `id`          | Returned as `request_id`; a second pending request with the same `id` is rejected |
| User property `traceparent` | Propagated to model requests and the response                                     |
| Correlation Data            | Echoed on the response, up to 256 bytes                                           |

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
  "counts": { "succeeded": 1, "failed": 0, "timed_out": 1, "rejected": 0 },
  "duration_ms": 4031,
  "max_score": 0.8,
  "models": [
    { "model_id": "vibration-anomaly", "status": "succeeded", "anomaly": true, "score": 0.8, "latency_ms": 5 },
    { "model_id": "slow-model", "status": "timed_out", "error_code": "TIMEOUT" }
  ]
}
```

Each model ends in exactly one state:

| Model status | Meaning                                                            |
|--------------|--------------------------------------------------------------------|
| `succeeded`  | The adapter interpreted the output                                 |
| `failed`     | The predict adapter returned an error; its code is in `error_code` |
| `rejected`   | The response didn't match the contract or its typed adapter        |
| `timed_out`  | No response before `TIMEOUT_SECONDS`                               |

The aggregate `status` is `complete` when every model succeeded, `partial` when
some did, and `failed` when none did. A failed or timed-out model never erases
another model's successful result. The `decision` is `anomaly` when any
succeeded model flags one, `normal` only when every model succeeded without an
anomaly, and `unknown` otherwise.

Each request gets exactly one response. Model responses that arrive after the
aggregate is published are counted as `late`, and repeated responses for the
same model are counted as `duplicate`; neither changes a published result.

Requests that can't be processed get a `rejected` response with an error code:
`INVALID_JSON`, `INVALID_PAYLOAD`, `PAYLOAD_TOO_LARGE`, `DUPLICATE_REQUEST`, or
`BUSY` (retryable, when `MAX_PENDING` requests are in progress).

## Configuration

| Variable            | Default              | Description                                         |
|---------------------|----------------------|-----------------------------------------------------|
| `MODELS`            | Required             | JSON list of models and their typed result adapters |
| `ENSEMBLE_ID`       | `default`            | Ensemble topic segment and CloudEvents `subject`    |
| `TIMEOUT_SECONDS`   | `10`                 | Deadline per request, up to 600                     |
| `MAX_PENDING`       | `100`                | Requests in progress before new ones get `BUSY`     |
| `MAX_REQUEST_BYTES` | `1048576`            | Largest accepted request, up to 16 MiB              |
| `TOPIC_DOMAIN`      | `orchestrate`        | First segment of orchestration topics               |
| `PREDICT_DOMAIN`    | `predict`            | First segment of predict adapter topics             |
| `PREDICT_CLIENT`    | `model-orchestrator` | Client segment on predict adapter topics            |
| `EVENT_SOURCE`      | `model-orchestrator` | CloudEvents `source`                                |

The broker connection uses the same variables as the AIO SDKs:
`AIO_BROKER_HOSTNAME`, `AIO_BROKER_TCP_PORT`, `AIO_MQTT_USE_TLS`,
`AIO_TLS_CA_FILE`, `AIO_SAT_FILE` (set it empty to skip SAT), and
`AIO_MQTT_CLIENT_ID`. Invalid configuration stops the orchestrator with exit
code 2.

## Authentication and Authorization

The orchestrator authenticates to the broker with a Kubernetes service account
token through MQTTv5 enhanced authentication, with method `K8S-SAT`, re-reading
the token on every connection attempt.

Add a rule to the BrokerAuthorization policy already linked to the listener
port, managed through the Azure portal, Bicep, or `az iot ops broker authz apply`,
as described in
[Configure MQTT broker authorization](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/howto-configure-authorization):

```yaml
rules:
  - principals:
      attributes:
        - workload: model-orchestrator
    brokerResources:
      - method: Connect
        clientIds:
          - "model-orchestrator-*"
      - method: Subscribe
        topics:
          - "orchestrate/v1/+/ensemble/default/request"
          - "predict/v1/model-orchestrator/model/+/response"
      - method: Publish
        topics:
          - "orchestrate/v1/+/ensemble/default/response"
          - "predict/v1/model-orchestrator/model/+/request"
```

Every model in `MODELS` must also be in the predict adapter's `ALLOWED_MODELS`.

## Logging

Logs never contain request or model payloads. The orchestrator logs each
aggregate status and decision, rejection codes, and these counters every 60
seconds and at shutdown: `received`, `complete`, `partial`, `failed`,
`rejected`, `late`, `duplicate`, `publish_failed`, and `connects`.

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
`Recreate` strategy, because pending fan-out state is held in memory. Rendering
fails when `orchestrator.models` is empty.

## Testing

```bash
cd src/500-application/519-model-orchestrator/services/model-orchestrator
pip install --require-hashes -r requirements.txt
pip install pytest
python3 -m pytest
```

Unit tests cover configuration validation, typed result adapters, aggregation
and decision rules, timeouts, late and duplicate responses, and request
rejection.
