---
title: Sensor Simulator
description: Synthetic vibration, acoustic, and temperature MQTT publisher for Azure IoT Operations with versioned topics, CloudEvents attributes, and an anomaly toggle
author: Edge AI Team
ms.date: 2026-10-08
ms.topic: reference
estimated_reading_time: 10
keywords:
  - azure iot operations
  - mqtt
  - sensor simulator
  - synthetic data
  - cloudevents
  - anomaly injection
---

## Overview

The sensor simulator publishes synthetic vibration, acoustic, and temperature
readings for one asset to the Azure IoT Operations (AIO) MQTT broker. Use it to
exercise data flows, dashboards, and anomaly-detection workloads without
physical sensors. An anomaly toggle shifts every signal from a healthy band to
a faulty band, and every reading carries the synthetic ground truth so
downstream results can be scored.

The simulator follows the
[custom workload messaging contract](../../../docs/solution-technology-paper-library/aio-messaging-design.md#custom-workload-messaging-contracts)
for versioned topics, CloudEvents attributes, workload identity, and
payload-safe logging.

## Topics

Readings are published to one versioned topic per modality:

```text
{topicDomain}/v1/{producer}/{resourceKind}/{assetId}/{modality}
```

With the defaults, the vibration topic is
`telemetry/v1/sensor-simulator/asset/asset-01/vibration`.

* `assetId`, `sensorId`, `producer`, `resourceKind`, and both domains must be
  1-64 lowercase letters, digits, `.`, `_`, or `-`. Use opaque identifiers
  rather than site names, asset tags, or locations.
* Readings are published at QoS 1 by default, without the retain flag. QoS 2
  isn't accepted because the AIO MQTT broker doesn't support it.
* When `CONTROL_ENABLED` is `true`, the simulator subscribes to
  `{controlDomain}/v1/{producer}/{resourceKind}/{assetId}/anomaly`. The control
  domain must differ from the telemetry domain, so the simulator never
  subscribes to its own output.

## Messages

Each reading carries these MQTTv5 user properties, plus the MQTTv5 Content
Type `application/json`:

| Attribute         | Value                                                      |
|-------------------|------------------------------------------------------------|
| `specversion`     | `1.0`                                                      |
| `type`            | `edge-ai.sensor.vibration`, `.acoustic`, or `.temperature` |
| `source`          | `EVENT_SOURCE`, `sensor-simulator` by default              |
| `id`              | Random UUID per reading                                    |
| `time`            | Generation time, RFC 3339 UTC                              |
| `subject`         | `ASSET_ID`                                                 |
| `datacontenttype` | `application/json`                                         |
| `dataschema`      | `DATA_SCHEMA`, sent only when set                          |

Scalar readings (vibration in `mm/s`, temperature in `degC`):

```json
{
  "schema_version": "1.0",
  "asset_id": "asset-01",
  "sensor_id": "sensor-01",
  "modality": "vibration",
  "health_state": "healthy",
  "timestamp": "2026-01-02T03:04:05.678Z",
  "value": 10.7342,
  "unit": "mm/s"
}
```

Acoustic readings replace `value` and `unit` with `sample_rate` and a
`samples` window of `ACOUSTIC_SAMPLE_COUNT` floats: a 220 Hz tone with noise,
plus a 3200 Hz component while the anomaly is injected.

`health_state` is the synthetic ground truth, `healthy` or `faulty`. Consumers
should accept unknown fields so later minor versions stay compatible.

### Payload Schema

[`resources/schemas/sensor-reading-v1.schema.json`](./resources/schemas/sensor-reading-v1.schema.json)
is the JSON Schema (draft 2020-12) for v1 payloads, with conforming examples in
[`resources/schemas/examples`](./resources/schemas/examples/). Every field is
required for its variant:

| Field            | Variant  | Type and range                                                     |
|------------------|----------|--------------------------------------------------------------------|
| `schema_version` | All      | String `1.<minor>`                                                 |
| `asset_id`       | All      | Opaque identifier, equal to the asset topic segment                |
| `sensor_id`      | All      | Opaque identifier                                                  |
| `modality`       | All      | `vibration`, `acoustic`, or `temperature`                          |
| `health_state`   | All      | `healthy` or `faulty`                                              |
| `timestamp`      | All      | RFC 3339 UTC with milliseconds, such as `2026-01-02T03:04:05.678Z` |
| `value`          | Scalar   | Number                                                             |
| `unit`           | Scalar   | `mm/s` for vibration, `degC` for temperature                       |
| `sample_rate`    | Acoustic | Integer from 8,000 to 192,000 Hz                                   |
| `samples`        | Acoustic | 2,048 to 65,536 numbers, each from -1 to 1                         |

Additional properties are allowed, and there are no optional v1 fields yet. To
advertise the schema, host it at a URI you control and set `DATA_SCHEMA` so
each message carries the CloudEvents `dataschema` attribute.

### Delivery Guarantees

The simulator, as producer, guarantees:

* **Size bounds:** scalar payloads stay under 300 bytes. Acoustic payloads are
  about 20 KB at the default 2,048 samples and about 615 KB at the maximum of
  65,536 samples. Make sure broker and data flow message size limits allow the
  window size you configure.
* **QoS:** QoS 1 by default, which gives at-least-once delivery while the
  client is connected. QoS 0 gives at-most-once delivery. No readings are
  generated while disconnected, so gaps aren't backfilled.
* **No retain:** readings are never retained, so a new subscriber only sees
  readings published after it subscribes.
* **Unique IDs:** every reading has a new CloudEvents `id`. A QoS 1 redelivery
  repeats the same `id`, so consumers must deduplicate on `id` rather than on
  payload content or `timestamp`.

## Anomaly Control

`INJECT_ANOMALY` sets the initial state. With `CONTROL_ENABLED` set to `true`,
publish this payload to the control topic to change it at runtime:

```json
{ "inject_anomaly": true }
```

Payloads larger than 1 KiB, with extra fields, or with a non-boolean value are
ignored and counted as `control_rejected`. Control is disabled by default.
Authorize `Subscribe` on the control topic for the simulator, and `Publish` on
it only for the principals that should toggle anomalies.

## Configuration

| Variable                   | Default                          | Description                                            |
|----------------------------|----------------------------------|--------------------------------------------------------|
| `ASSET_ID`                 | `asset-01`                       | Asset topic segment and CloudEvents `subject`          |
| `SENSOR_ID`                | `sensor-01`                      | Opaque sensor identifier, same rules as `ASSET_ID`     |
| `MODALITIES`               | `vibration,acoustic,temperature` | Comma-separated modalities to publish                  |
| `PUBLISH_INTERVAL_SECONDS` | `2`                              | Seconds between publish cycles, up to 3600             |
| `SIMULATOR_SEED`           |                                  | Integer seed for repeatable signals                    |
| `INJECT_ANOMALY`           | `false`                          | Initial anomaly state                                  |
| `CONTROL_ENABLED`          | `false`                          | Subscribe to the anomaly control topic                 |
| `MQTT_QOS`                 | `1`                              | Publish QoS, `0` or `1`                                |
| `TOPIC_DOMAIN`             | `telemetry`                      | First segment of telemetry topics                      |
| `CONTROL_DOMAIN`           | `control`                        | First segment of the control topic                     |
| `PRODUCER`                 | `sensor-simulator`               | Producer topic segment                                 |
| `RESOURCE_KIND`            | `asset`                          | Resource kind topic segment                            |
| `EVENT_SOURCE`             | `sensor-simulator`               | CloudEvents `source`, a URI reference up to 128 chars  |
| `DATA_SCHEMA`              |                                  | Absolute URI sent as CloudEvents `dataschema`          |
| `HEALTHY_BAND_CENTER`      | `10.8`                           | Healthy vibration mean                                 |
| `FAULTY_BAND_CENTER`       | `11.6`                           | Faulty vibration mean, greater than the healthy mean   |
| `BAND_JITTER`              | `0.15`                           | Vibration standard deviation                           |
| `TEMPERATURE_HEALTHY_C`    | `62.0`                           | Healthy temperature mean                               |
| `TEMPERATURE_FAULTY_C`     | `71.0`                           | Faulty temperature mean, greater than the healthy mean |
| `TEMPERATURE_JITTER_C`     | `0.8`                            | Temperature standard deviation                         |
| `ACOUSTIC_SAMPLE_RATE`     | `16000`                          | Acoustic sample rate, 8000 to 192000 Hz                |
| `ACOUSTIC_SAMPLE_COUNT`    | `2048`                           | Samples per acoustic window, 2048 to 65536             |

`ACOUSTIC_SAMPLE_COUNT` can't go below 2,048 because acoustic consumers such as
the 521 acoustic anomaly operators need at least 2,048 samples to produce a
feature window. The bound applies even when `MODALITIES` omits `acoustic`.

The broker connection uses the same variables as the AIO SDKs:

| Variable              | Default                           | Description                                        |
|-----------------------|-----------------------------------|----------------------------------------------------|
| `AIO_BROKER_HOSTNAME` | `aio-broker.azure-iot-operations` | Broker host                                        |
| `AIO_BROKER_TCP_PORT` | `18883`                           | Broker port                                        |
| `AIO_MQTT_USE_TLS`    | `true`                            | Connect over TLS                                   |
| `AIO_TLS_CA_FILE`     | `/var/run/certs/ca.crt`           | CA bundle; set it empty for the system trust store |
| `AIO_SAT_FILE`        | `/var/run/secrets/tokens/mq-sat`  | Service account token; set it empty to skip SAT    |
| `AIO_MQTT_CLIENT_ID`  | `sensor-simulator`                | MQTT client ID                                     |

A service account token is only sent over TLS. Setting `AIO_MQTT_USE_TLS` to
`false` requires an empty `AIO_SAT_FILE`; otherwise the simulator refuses to
start.

Invalid configuration stops the simulator with exit code 2. It logs one line
per problem, naming the environment variable but never echoing its value. A
missing or unparseable CA bundle also exits with code 2.

## Authentication and Authorization

The simulator authenticates with a Kubernetes service account token through
MQTTv5 enhanced authentication, with method `K8S-SAT`, as described in
[Configure MQTT broker authentication](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/howto-configure-authentication).
It reads the token file on every connection attempt, so a reconnect uses the
current projected token. Connection failures are retried with exponential
backoff from 1 second up to 30 seconds, and the delay resets after a
successful connection.

The broker
[closes the connection when a SAT expires](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/howto-configure-authentication#clients-disconnect-after-credentials-expire).
MQTTv5 clients can avoid that by sending a fresh token in an AUTH packet, but
paho-mqtt 2.1 can't send AUTH packets. Expect one forced reconnect per token
lifetime instead, set by the chart's `volumes.mqSat.expirationSeconds`
(24 hours by default). Readings due during the reconnect are skipped, not
buffered.

Add a rule for the simulator to the BrokerAuthorization policy already linked
to the listener port it uses, managed through the Azure portal, Bicep, or
`az iot ops broker authz apply`, as described in
[Configure MQTT broker authorization](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/howto-configure-authorization).
A least-privilege rule for the default chart values looks like this:

```yaml
rules:
  - principals:
      attributes:
        - workload: sensor-simulator
    brokerResources:
      - method: Connect
        clientIds:
          - "sensor-simulator-*"
      - method: Publish
        topics:
          - "telemetry/v1/sensor-simulator/asset/+/+"
```

Add `Subscribe` on `control/v1/sensor-simulator/asset/+/anomaly` only when
control is enabled.

## Logging

Logs never contain reading values or control payloads, and configuration errors
never echo the rejected value. The simulator logs connection changes, control
outcomes, broker reason codes for rejected publishes and subscriptions, and
these counters every 60 seconds and at shutdown:

| Counter            | Meaning                                                           |
|--------------------|-------------------------------------------------------------------|
| `publish_enqueued` | Readings handed to the MQTT client, also counted in `by_modality` |
| `publish_failed`   | Readings the client refused to enqueue, for example while offline |
| `publish_acked`    | QoS 1 readings the broker acknowledged with a success reason code |
| `publish_rejected` | QoS 1 readings the broker acknowledged with a failure reason code |
| `control_applied`  | Valid control messages applied                                    |
| `control_rejected` | Invalid control messages ignored                                  |
| `connects`         | Successful broker connections                                     |
| `by_modality`      | `publish_enqueued` split by modality                              |

At QoS 0 the broker sends no acknowledgment, so paho counts every enqueued
reading as acknowledged once it's written to the socket. A gap between
`publish_enqueued` and `publish_acked` plus `publish_rejected` at QoS 1 means
readings are still in flight or were lost with a connection.

## Build

Build from this component directory. No public image is published, so push the
image to a registry you own:

```bash
cd src/500-application/517-sensor-simulator
docker build -f services/sensor-simulator/Dockerfile -t sensor-simulator:0.1.0 .
```

## Deploy

The [Helm chart](./charts/sensor-simulator/) deploys one simulator per asset:

```bash
helm install asset-01-simulator \
  src/500-application/517-sensor-simulator/charts/sensor-simulator \
  --namespace azure-iot-operations \
  --set image.repository=<your-registry>/sensor-simulator \
  --set simulator.assetId=asset-01
```

The chart:

* Creates a dedicated service account that doesn't mount an API token, and
  projects a service account token with the `aio-internal` audience for broker
  authentication over TLS.
* Sets `AIO_MQTT_CLIENT_ID` to `<clientIdPrefix>-<pod name>` through the
  Downward API, so every pod connects with a unique client ID.
* Runs one replica with the `Recreate` strategy, a read-only root file system,
  and no exposed ports.
* Annotates the service account with `aio-broker-auth/workload:
  sensor-simulator`, which the broker exposes as an authorization attribute.
* Validates values against `values.schema.json`, so out-of-range settings such
  as `simulator.acousticSampleCount=1024` or a non-integer `simulator.seed`
  fail at install time instead of at pod startup.

## Local Development

`docker-compose.yml` runs the simulator against a local Mosquitto broker
without TLS or SAT. The broker allows anonymous clients, so it only listens on
`127.0.0.1:11883` on the host. Copy `.env.example` to `.env` to change the
simulated asset:

```bash
cd src/500-application/517-sensor-simulator
cp .env.example .env
docker compose up --build -d
docker compose exec mosquitto-broker mosquitto_sub -V 5 -t 'telemetry/#' -v
```

Toggle the anomaly through the control topic, which `.env.example` enables:

```bash
docker compose exec mosquitto-broker mosquitto_pub -V 5 \
  -t control/v1/sensor-simulator/asset/asset-01/anomaly -m '{"inject_anomaly": true}'
```

## Testing

```bash
cd src/500-application/517-sensor-simulator/services/sensor-simulator
pip install --require-hashes -r requirements.txt -r requirements-test.txt
python3 -m pytest
```

Unit tests cover configuration validation, topic construction, seeded signal
generation, CloudEvents and SAT properties, and control-payload validation. A
fake MQTT client exercises token rereads on reconnect, backoff, broker reason
code handling, and control callbacks. Contract tests validate the example
fixtures and generated readings against the JSON Schema.
