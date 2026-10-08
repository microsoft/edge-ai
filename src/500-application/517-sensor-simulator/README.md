---
title: Sensor Simulator
description: Synthetic vibration, acoustic, and temperature MQTT publisher for Azure IoT Operations with versioned topics, CloudEvents attributes, and an anomaly toggle
author: Edge AI Team
ms.date: 2026-10-08
ms.topic: reference
estimated_reading_time: 7
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

* `assetId`, `producer`, `resourceKind`, and both domains must be 1-64
  lowercase letters, digits, `.`, `_`, or `-`. Use opaque identifiers rather
  than site names, asset tags, or locations.
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
| `SENSOR_ID`                | `sensor-01`                      | Opaque sensor identifier in each reading               |
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
| `EVENT_SOURCE`             | `sensor-simulator`               | CloudEvents `source`                                   |
| `HEALTHY_BAND_CENTER`      | `10.8`                           | Healthy vibration mean                                 |
| `FAULTY_BAND_CENTER`       | `11.6`                           | Faulty vibration mean, greater than the healthy mean   |
| `BAND_JITTER`              | `0.15`                           | Vibration standard deviation                           |
| `TEMPERATURE_HEALTHY_C`    | `62.0`                           | Healthy temperature mean                               |
| `TEMPERATURE_FAULTY_C`     | `71.0`                           | Faulty temperature mean, greater than the healthy mean |
| `TEMPERATURE_JITTER_C`     | `0.8`                            | Temperature standard deviation                         |
| `ACOUSTIC_SAMPLE_RATE`     | `16000`                          | Acoustic sample rate in Hz                             |
| `ACOUSTIC_SAMPLE_COUNT`    | `2048`                           | Samples per acoustic window, up to 65536               |

The broker connection uses the same variables as the AIO SDKs:

| Variable              | Default                           | Description                                     |
|-----------------------|-----------------------------------|-------------------------------------------------|
| `AIO_BROKER_HOSTNAME` | `aio-broker.azure-iot-operations` | Broker host                                     |
| `AIO_BROKER_TCP_PORT` | `18883`                           | Broker port                                     |
| `AIO_MQTT_USE_TLS`    | `true`                            | Connect over TLS                                |
| `AIO_TLS_CA_FILE`     | `/var/run/certs/ca.crt`           | CA bundle used to verify the broker             |
| `AIO_SAT_FILE`        | `/var/run/secrets/tokens/mq-sat`  | Service account token; set it empty to skip SAT |
| `AIO_MQTT_CLIENT_ID`  | `sensor-simulator`                | MQTT client ID                                  |

Invalid configuration stops the simulator with exit code 2 and names the
offending variable.

## Authentication and Authorization

The simulator authenticates with a Kubernetes service account token through
MQTTv5 enhanced authentication, with method `K8S-SAT`, as described in
[Configure MQTT broker authentication](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/howto-configure-authentication).
It reads the token file on every connection attempt, so a reconnect uses the
current projected token. Connection failures are retried with exponential
backoff up to 30 seconds.

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

Logs never contain reading values or control payloads. The simulator logs
connection changes, control outcomes, and these counters every 60 seconds and
at shutdown: `published`, `publish_failed`, `control_applied`,
`control_rejected`, `connects`, and `by_modality`.

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

## Local Development

Run against a local MQTTv5 broker without TLS or SAT:

```bash
cd src/500-application/517-sensor-simulator/services/sensor-simulator
pip install --require-hashes -r requirements.txt
AIO_BROKER_HOSTNAME=localhost AIO_BROKER_TCP_PORT=1883 AIO_MQTT_USE_TLS=false \
  AIO_SAT_FILE= SIMULATOR_SEED=1 python3 app.py
```

## Testing

```bash
cd src/500-application/517-sensor-simulator/services/sensor-simulator
pip install --require-hashes -r requirements.txt
pip install pytest
python3 -m pytest
```

Unit tests cover configuration validation, topic construction, seeded signal
generation, CloudEvents and SAT properties, and control-payload validation.
