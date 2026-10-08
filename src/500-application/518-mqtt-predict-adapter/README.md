---
title: MQTT Predict Adapter
description: Bridges MQTT predict requests on the Azure IoT Operations broker to HTTP predictive model endpoints such as Foundry Local, with versioned topics, CloudEvents attributes, and service account token authentication
author: Edge AI Team
ms.date: 2026-10-08
ms.topic: reference
estimated_reading_time: 9
keywords:
  - azure iot operations
  - mqtt
  - foundry local
  - predictive inference
  - onnx
  - request response
---

## Overview

The MQTT predict adapter lets MQTT-native workloads, such as data flow graphs,
simulators, and orchestrators, call predictive models that expose an HTTP
`/v1/predict` endpoint. It subscribes to versioned request topics on the Azure
IoT Operations (AIO) MQTT broker, calls the model, and publishes the result to
the requesting client's response topic.

The default endpoint template targets
[Foundry Local on Azure Local](https://learn.microsoft.com/azure/azure-sovereign-clouds/private/foundry-local/overview)
predictive model deployments, which is in preview. Any endpoint that accepts and
returns the same `items` payload works.

The adapter follows the
[custom workload messaging contract](../../../docs/solution-technology-paper-library/aio-messaging-design.md#custom-workload-messaging-contracts)
for versioned topics, CloudEvents attributes, workload identity, and
payload-safe logging.

```text
client ──► predict/v1/{client}/model/{model-id}/request
                         │
                  predict adapter ──► POST {endpoint}/v1/predict
                         │
client ◄── predict/v1/{client}/model/{model-id}/response
```

## Topics

| Direction | Topic                                           |
|-----------|-------------------------------------------------|
| Request   | `predict/v1/{client}/model/{model-id}/request`  |
| Response  | `predict/v1/{client}/model/{model-id}/response` |

* `{client}` names the requesting workload. Responses return to the same
  client segment, so broker authorization can limit each client to its own
  responses.
* `{model-id}` must be in `ALLOWED_MODELS`. Requests for other models get an
  `UNKNOWN_MODEL` response and never reach a backend.
* The adapter subscribes only to `.../request` and publishes only to
  `.../response`, so it never receives its own output. Topics that don't match
  the grammar are ignored.
* Requests and responses use QoS 1 without the retain flag. Retained request
  messages are ignored and counted as `retained`, so a stale request never
  triggers a model call when the adapter reconnects.
* The response topic is always derived from the request topic. An MQTTv5
  Response Topic property on the request is ignored.

## Request

Send a JSON object with exactly one of these forms:

| Form   | Fields                                   | Sent to the model as                                         |
|--------|------------------------------------------|--------------------------------------------------------------|
| Tensor | `inputs`: numbers, up to four dimensions | `application/json` item; a flat list is wrapped into one row |
| Binary | `data` (standard Base64), `content_type` | Item with the given content type, such as `image/jpeg`       |

```json
{ "inputs": [[0.12, 0.34, 0.56]], "context": { "asset_id": "asset-01" } }
```

Tensors must be rectangular, with every row the same length, and contain only
finite numbers. `NaN`, `Infinity`, and numbers that overflow are rejected with
`INVALID_JSON`, as is JSON nested too deeply to decode.

The optional `context` object, up to 1 KiB, is returned unchanged on the
response and never sent to the model. Use it to carry identifiers that a
downstream consumer needs, such as the asset a reading came from.

The adapter wraps each request in the Foundry Local `/v1/predict` `items`
envelope, but the data a model expects inside an item depends on that model's
input schema. The request and response shapes have been validated only against
the mock model in `resources/mock_predict.py`, so confirm the tensor layout and
output format against your model before relying on them.

Optional MQTTv5 properties on the request:

| Property                    | Use                                                             |
|-----------------------------|-----------------------------------------------------------------|
| User property `id`          | Returned as `request_id`, up to 256 characters                  |
| User property `traceparent` | Propagated to the response when it's a valid W3C value          |
| Correlation Data            | Echoed on the response, up to 256 bytes                         |
| Message Expiry Interval     | Deadline for the request; see [Request Expiry](#request-expiry) |

## Response

```json
{
  "schema_version": "1.0",
  "model_id": "sensor-anomaly",
  "request_id": "req-1",
  "status": "success",
  "latency_ms": 12,
  "outputs": { "score": 0.93 },
  "context": { "asset_id": "asset-01" }
}
```

`outputs` is the decoded model result. JSON results are returned as JSON;
other content types are returned as `{"content_type": ..., "data": <Base64>}`.
Each response carries CloudEvents user properties: `specversion`, `type`
(`edge-ai.predict.response`), `source`, `id`, `time`, `subject` (the model ID),
and `datacontenttype`, plus the MQTTv5 Content Type `application/json`.

On failure, `status` is `error` and `error` holds a stable code. Error messages
never include request payloads or backend response bodies.

| Code                       | Retryable | Meaning                                                    |
|----------------------------|-----------|------------------------------------------------------------|
| `UNKNOWN_MODEL`            | No        | Model isn't in `ALLOWED_MODELS`                            |
| `INVALID_JSON`             | No        | Request isn't JSON                                         |
| `INVALID_PAYLOAD`          | No        | Request doesn't match either form                          |
| `PAYLOAD_TOO_LARGE`        | No        | Request exceeds `MAX_REQUEST_BYTES`                        |
| `BUSY`                     | Yes       | `MAX_CONCURRENCY` requests are in flight, or shutting down |
| `BACKEND_UNAUTHORIZED`     | No        | Model endpoint returned 401 or 403                         |
| `MODEL_UNAVAILABLE`        | No        | Model endpoint returned 404                                |
| `BACKEND_REJECTED`         | No        | Model endpoint returned another 4xx status                 |
| `BACKEND_UNAVAILABLE`      | Yes       | Connection failure, 429, 502, 503, or 504 after retries    |
| `BACKEND_ERROR`            | Yes       | Model endpoint returned another 5xx status after retries   |
| `BACKEND_TIMEOUT`          | Yes       | No response within `BACKEND_TIMEOUT_SECONDS` after retries |
| `BACKEND_INVALID_RESPONSE` | No        | Response had no decodable `items[0]` object                |
| `OUTPUT_TOO_LARGE`         | No        | Response body exceeds `MAX_RESPONSE_BYTES`                 |
| `INTERNAL_ERROR`           | Yes       | Unexpected adapter failure                                 |

Transient backend failures are retried `BACKEND_ATTEMPTS` times with
exponential backoff starting at 500 ms. `BACKEND_TIMEOUT_SECONDS` is the whole
deadline for one attempt, including reading the response body; connecting,
sending, and waiting for a pooled connection are each also limited to 5
seconds.

On SIGTERM or SIGINT, the adapter unsubscribes, answers requests that are
already queued with `BUSY`, and publishes in-flight results for up to the
longest a request can take: `BACKEND_TIMEOUT_SECONDS` × `BACKEND_ATTEMPTS`
plus backoff. Requests are acknowledged when they're received, so a request
still in flight after that gets no response; clients should time out and retry.

## Request Expiry

When a request carries an MQTTv5 Message Expiry Interval, the adapter treats
the remaining interval, as decremented by the broker, as the requester's
deadline:

* A request whose interval has already reached zero is dropped without a model
  call or a response, because the requester has stopped waiting. It's counted
  as `expired`.
* Backend attempts and retry backoff never run past the deadline.
* A result that's ready only after the deadline isn't published, and is
  counted as `expired`.

Without the property, requests have no deadline beyond the backend limits.

Size the backend limits against the requester's timeout so the adapter gives up
first: keep `BACKEND_TIMEOUT_SECONDS` × `BACKEND_ATTEMPTS` below the
requester's timeout, such as the model orchestrator's `TIMEOUT_SECONDS`.

## Configuration

| Variable                  | Default                                                                       | Description                                            |
|---------------------------|-------------------------------------------------------------------------------|--------------------------------------------------------|
| `ALLOWED_MODELS`          | Required                                                                      | Comma-separated model IDs, each a lowercase DNS label  |
| `MODEL_ENDPOINT_TEMPLATE` | `https://{model_id}.foundry-local-operator.svc.cluster.local:5000/v1/predict` | Endpoint URL; `{model_id}` appears exactly once        |
| `BACKEND_AUTH_FILE`       | `/var/run/secrets/foundry-local/token`                                        | Bearer token file, re-read per request; empty disables |
| `BACKEND_CA_FILE`         |                                                                               | CA bundle for the endpoint's TLS certificate           |
| `BACKEND_TIMEOUT_SECONDS` | `30`                                                                          | Per-attempt deadline, up to 300                        |
| `BACKEND_ATTEMPTS`        | `2`                                                                           | Attempts per request, 1 to 5                           |
| `MAX_REQUEST_BYTES`       | `1048576`                                                                     | Largest accepted request, up to 16 MiB                 |
| `MAX_RESPONSE_BYTES`      | `4194304`                                                                     | Largest model endpoint response body, up to 64 MiB     |
| `MAX_CONCURRENCY`         | `4`                                                                           | Concurrent model calls, 1 to 64                        |
| `TOPIC_DOMAIN`            | `predict`                                                                     | First topic segment                                    |
| `REQUEST_KIND`            | `request`                                                                     | Last segment of request topics                         |
| `RESPONSE_KIND`           | `response`                                                                    | Last segment of response topics                        |
| `EVENT_SOURCE`            | `predict-adapter`                                                             | CloudEvents `source` on responses                      |

The broker connection uses the same variables as the AIO SDKs:
`AIO_BROKER_HOSTNAME`, `AIO_BROKER_TCP_PORT`, `AIO_MQTT_USE_TLS`,
`AIO_TLS_CA_FILE`, `AIO_SAT_FILE` (set it empty to skip SAT), and
`AIO_MQTT_CLIENT_ID`. Invalid configuration stops the adapter with exit code 2.
Tokens are never sent over plain text: `BACKEND_AUTH_FILE` requires an
`https://` endpoint template, and `AIO_SAT_FILE` requires `AIO_MQTT_USE_TLS`.
Set the file variable empty to use an unauthenticated plain-text connection,
as the local compose stack does.

## Authentication and Authorization

The adapter uses two Kubernetes service account tokens:

* **Broker:** a projected token with the `aio-internal` audience, sent through
  MQTTv5 enhanced authentication with method `K8S-SAT`, as described in
  [Configure MQTT broker authentication](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/howto-configure-authentication).
  It's re-read on every connection attempt.
* **Model endpoint:** a projected token with the `foundry-local` audience,
  sent as a bearer token and re-read for every request. No API keys are copied
  between namespaces.

Authorize the adapter's service account on each Foundry Local
`ModelDeployment` it serves. The chart names the service account after the
release, so `helm install predict-adapter` creates `predict-adapter`. Follow
the steps in
[Configure Kubernetes service account token authentication for Foundry Local](https://learn.microsoft.com/azure/azure-sovereign-clouds/private/foundry-local/how-to-configure-service-account-token-authentication):

```yaml
spec:
  authenticationMethods:
    - method: serviceAccountToken
      enabled: true
      roles:
        - role: GeneralInferenceUser
          authorizedSubjects:
            - serviceAccountName: predict-adapter
              serviceAccountNamespace: azure-iot-operations
```

Add broker rules to the BrokerAuthorization policy already linked to the
listener port, managed through the Azure portal, Bicep, or
`az iot ops broker authz apply`, as described in
[Configure MQTT broker authorization](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/howto-configure-authorization):

```yaml
rules:
  - principals:
      attributes:
        - workload: predict-adapter
    brokerResources:
      - method: Connect
        clientIds:
          - "predict-adapter-*"
      - method: Subscribe
        topics:
          - "predict/v1/+/model/+/request"
      - method: Publish
        topics:
          - "predict/v1/+/model/+/response"
```

Grant each client `Publish` on `predict/v1/<client>/model/+/request` and
`Subscribe` on `predict/v1/<client>/model/+/response` for its own client
segment only.

## Logging

Logs never contain request or response payloads. The adapter logs connection
changes, rejection and failure codes, and these counters every 60 seconds and
at shutdown: `received`, `succeeded`, `failed`, `rejected`, `busy`, `expired`,
`retained`, `unhandled`, `publish_failed`, `connects`, and `by_error`.
`unhandled` counts messages that raised an unexpected error; only the error
type is logged, and the adapter keeps running.

## Build

Build from this component directory. No public image is published, so push the
image to a registry you own:

```bash
cd src/500-application/518-mqtt-predict-adapter
docker build -f services/predict-adapter/Dockerfile -t predict-adapter:0.1.0 .
```

## Deploy

```bash
helm install predict-adapter \
  src/500-application/518-mqtt-predict-adapter/charts/predict-adapter \
  --namespace azure-iot-operations \
  --set image.repository=<your-registry>/predict-adapter \
  --set "adapter.allowedModels={sensor-anomaly}"
```

The chart:

* Creates a dedicated service account that doesn't mount an API token.
* Projects the `aio-internal` broker token and, unless `backend.sat.enabled` is
  `false`, the `foundry-local` model endpoint token.
* Mounts an optional CA bundle from `backend.caConfigMap` for the model
  endpoint's TLS certificate.
* Sets `AIO_MQTT_CLIENT_ID` to `<clientIdPrefix>-<pod name>` through the
  Downward API, and runs one replica with the `Recreate` strategy, because a
  non-shared subscription would answer each request once per replica.
* Sets `terminationGracePeriodSeconds` to `backendTimeoutSeconds` ×
  `backendAttempts` plus 20 seconds, so in-flight results are published before
  the pod stops.
* Runs with a read-only root file system and no exposed ports.
* Fails to render when `adapter.modelEndpointTemplate` isn't `https://` while
  `backend.sat.enabled` is `true`, so the token is never sent in plain text.

## Local Development

`docker-compose.yml` runs the adapter with a local Mosquitto broker and a mock
`/v1/predict` model (`resources/mock_predict.py`) that returns the mean of the
input tensor, optionally after `MOCK_LATENCY_SECONDS`. Copy `.env.example` to
`.env` to point the adapter at another endpoint:

```bash
cd src/500-application/518-mqtt-predict-adapter
cp .env.example .env
docker compose up --build -d
docker compose exec mosquitto-broker mosquitto_sub -V 5 -t 'predict/v1/local/model/+/response' &
docker compose exec mosquitto-broker mosquitto_pub -V 5 \
  -t predict/v1/local/model/sensor-anomaly/request -m '{"inputs": [0.2, 0.4]}'
```

## Testing

```bash
cd src/500-application/518-mqtt-predict-adapter/services/predict-adapter
pip install --require-hashes -r requirements.txt
pip install pytest
python3 -m pytest
```

Unit tests cover configuration validation, topic parsing, request validation,
`items` encoding and decoding, backend error mapping and retries, response size
and deadline limits, token rotation, response properties, request expiry,
retained and deeply nested requests, and concurrency limits.
