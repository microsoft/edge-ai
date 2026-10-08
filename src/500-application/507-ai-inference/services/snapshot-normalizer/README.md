# Snapshot Normalizer

MQTT adapter that turns binary JPEG snapshots into `image_snapshot` v1
requests for the component 507 inference service.

The adapter subscribes to a snapshot topic, such as the topic a media connector
`snapshot-to-mqtt` stream publishes to, and republishes each accepted JPEG as a
JSON request built by
[`snapshot-normalizer-core`](../snapshot-normalizer-core/README.md). It follows
the [custom workload messaging contract](../../../../../docs/solution-technology-paper-library/aio-messaging-design.md#custom-workload-messaging-contracts)
for topics, CloudEvents attributes, deduplication, and payload-safe logging.

## Message Flow

```text
INPUT_TOPIC (binary JPEG)
  -> classify and size-check the payload
  -> skip producer IDs already published within the window
  -> build image_snapshot v1 request
  -> publish QoS 1 to OUTPUT_TOPIC with CloudEvents user properties
  -> acknowledge the input
```

### Topics

The default output topic is versioned and stays inside the inference service's
default `edge-ai/+/+/+/camera/snapshots` subscription:

```text
edge-ai/v1/snapshot-normalizer/{camera-id}/camera/snapshots
```

* `CAMERA_ID` must be 1-64 lowercase letters, digits, `.`, `_`, or `-`, because
  it becomes a topic segment. Use an opaque identifier rather than a site,
  asset tag, or location.
* The adapter refuses to start when `OUTPUT_TOPIC` matches the `INPUT_TOPIC`
  filter, including through wildcards, so it can't republish its own output.
* Requests are published at QoS 1 without the retain flag.

### CloudEvents Attributes

Each request carries these MQTTv5 user properties:

| Attribute         | Value                                                                   |
|-------------------|-------------------------------------------------------------------------|
| `specversion`     | `1.0`                                                                   |
| `type`            | `image_snapshot`                                                        |
| `source`          | `EVENT_SOURCE`, `snapshot-normalizer` by default                        |
| `id`              | UUID; name-based when the input carried a producer `id`                 |
| `time`            | Producer `time` when it's valid RFC 3339, otherwise the processing time |
| `subject`         | `CAMERA_ID`                                                             |
| `datacontenttype` | `application/json`, also set as the MQTTv5 Content Type                 |
| `dataschema`      | `DATA_SCHEMA`, omitted when unset                                       |
| `traceparent`     | Propagated from the input when it's a valid W3C version `00` value      |

The request's `correlation_id` field carries the same value as `id`. The
`time` attribute sets the request's `timestamp` field in epoch seconds. Set
`DATA_SCHEMA` only to a reference that matches any data flow source schema that
consumes the output topic, because a conflicting `dataschema` makes the data
flow drop the message.

### Deduplication

Deduplication is keyed on the producer-supplied CloudEvents `id` user property,
scoped to the source topic and the optional `source` property. Content is
never used as a key, so periodic snapshots of a static scene are all published.

* Messages without an `id`, or with an `id` longer than 256 bytes, aren't
  deduplicated and are counted as `unkeyed`.
* A key is retained for `DEDUP_WINDOW_SECONDS` or until `DEDUP_CAPACITY` newer
  keys evict it, whichever comes first.
* A key is recorded only after the broker acknowledges the request, so a
  redelivered input whose publish failed isn't suppressed.
* State is held in memory per pod. The Helm chart runs a single replica with
  the `Recreate` strategy for that reason.

### Delivery

The adapter acknowledges each input after handling ends. A request that fails
to publish is retried `PUBLISH_ATTEMPTS` times with exponential backoff
starting at 500 ms. A request the broker rejects with a failure reason isn't
retried. Failed requests are logged, counted as `publish_failed`, and the input
is still acknowledged, because MQTT acknowledgements are delivered in receive
order and an unacknowledged input would block every later one.

### Logging

Logs never contain payload bytes, Base64 data, or producer identifiers.
Rejections log the reason and payload length. Counters are logged every
`COUNTERS_INTERVAL_SECONDS` and at shutdown: `received`, `accepted`,
`published`, `duplicate`, `unkeyed`, `rejected_empty`, `rejected_not_jpeg`,
`rejected_oversize`, and `publish_failed`.

## Configuration

| Variable                    | Required | Default                                                       | Description                                 |
|-----------------------------|----------|---------------------------------------------------------------|---------------------------------------------|
| `CAMERA_ID`                 | Yes      |                                                               | Opaque camera identifier and topic segment  |
| `DEVICE_NAME`               | Yes      |                                                               | Opaque device identifier for the request    |
| `INPUT_TOPIC`               | Yes      |                                                               | Topic filter carrying binary JPEG snapshots |
| `OUTPUT_TOPIC`              | No       | `edge-ai/v1/snapshot-normalizer/{CAMERA_ID}/camera/snapshots` | Concrete output topic                       |
| `EVENT_SOURCE`              | No       | `snapshot-normalizer`                                         | CloudEvents `source`, a URI reference       |
| `DATA_SCHEMA`               | No       |                                                               | CloudEvents `dataschema`, an absolute URI   |
| `MAX_JPEG_BYTES`            | No       | `4194304`                                                     | Largest accepted JPEG                       |
| `MAX_ENVELOPE_BYTES`        | No       | `8388608`                                                     | Largest accepted serialized request         |
| `DEDUP_CAPACITY`            | No       | `1024`                                                        | Most producer keys retained                 |
| `DEDUP_WINDOW_SECONDS`      | No       | `300`                                                         | Longest time a producer key is retained     |
| `PUBLISH_ATTEMPTS`          | No       | `3`                                                           | Publish attempts per request                |
| `COUNTERS_INTERVAL_SECONDS` | No       | `60`                                                          | Interval between counter log lines          |
| `RUST_LOG`                  | No       | `info`                                                        | Log filter                                  |

Numeric values must be positive integers. Keep `MAX_ENVELOPE_BYTES` below the
broker's maximum packet size, leaving room for the topic and user properties.
The [memory profile](https://learn.microsoft.com/azure/iot-operations/reference/mqtt-support#broker-limits)
bounds that size: 4 MB for Tiny, 16 MB for Low, and 64 MB for Medium, the
default. The broker disconnects a client that sends a larger packet, so lower
both maxima on a Tiny profile, for example to 2 MiB and 3 MiB. The broker connection uses the
Azure IoT Operations SDK variables, including `AIO_BROKER_HOSTNAME`,
`AIO_BROKER_TCP_PORT`, `AIO_MQTT_CLIENT_ID`, `AIO_MQTT_USE_TLS`,
`AIO_TLS_CA_FILE`, and `AIO_SAT_FILE`.

## Build

The image depends on `snapshot-normalizer-core` by path, so build from the
`services` directory:

```bash
cd src/500-application/507-ai-inference/services
docker build -f snapshot-normalizer/Dockerfile -t snapshot-normalizer:0.1.0 .
```

Push the image to a registry you own. No public image is published.

## Deploy

The [Helm chart](../../charts/snapshot-normalizer/) deploys one adapter per
camera input topic:

```bash
helm install camera-01-normalizer \
  src/500-application/507-ai-inference/charts/snapshot-normalizer \
  --namespace azure-iot-operations \
  --set image.repository=<your-registry>/snapshot-normalizer \
  --set normalizer.cameraId=camera-01 \
  --set normalizer.deviceName=camera-device-01 \
  --set normalizer.inputTopic=<snapshot-topic>
```

The chart:

* Creates a dedicated service account that doesn't mount an API token, and
  projects a service account token with the `aio-internal` audience for broker
  authentication over TLS.
* Sets `AIO_MQTT_CLIENT_ID` to `<clientIdPrefix>-<pod name>` through the
  Downward API, so every pod connects with a unique client ID.
* Runs one replica with the `Recreate` strategy, a read-only root file system,
  and no exposed ports or probes.
* Annotates the service account with `aio-broker-auth/workload:
  snapshot-normalizer`, which the broker exposes as an authorization attribute.

### Authorization

Bind a BrokerAuthorization resource to the listener port the adapter uses, as
described in [Configure MQTT broker authorization](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/howto-configure-authorization).
A least-privilege rule for the default chart values looks like this:

```yaml
rules:
  - principals:
      attributes:
        - workload: snapshot-normalizer
    brokerResources:
      - method: Connect
        clientIds:
          - "snapshot-normalizer-*"
      - method: Subscribe
        topics:
          - "<snapshot-topic>"
      - method: Publish
        topics:
          - "edge-ai/v1/snapshot-normalizer/+/camera/snapshots"
```

## Testing

```bash
cd src/500-application/507-ai-inference/services/snapshot-normalizer
cargo test
cargo clippy --all-targets -- -D warnings
```

Unit tests cover configuration validation, rejection reasons, CloudEvents
attributes, capture-time and trace propagation, and the deduplication window.

## License

MIT. See the repository [LICENSE](../../../../../LICENSE).
