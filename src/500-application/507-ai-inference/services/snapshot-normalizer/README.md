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
INPUT_TOPIC (binary JPEG, retained messages skipped)
  -> classify and size-check the payload
  -> skip producer IDs already published within the window
  -> build image_snapshot v1 request
  -> publish QoS 1 to OUTPUT_TOPIC with CloudEvents user properties
  -> acknowledge the input
```

### Topics

The default output topic follows the
`{domain}/{version}/{producer}/{resource-kind}/{resource-id}/{message-kind}`
grammar of the custom workload messaging contract, pinned to `v1`:

```text
edge-ai/v1/snapshot-normalizer/camera/{camera-id}/snapshots
```

The inference service receives it through its pinned
`edge-ai/v1/+/camera/+/snapshots` input filter, which is the service's
built-in default alongside the legacy `edge-ai/+/+/camera/snapshots` filter and
is set in the component manifests and docker-compose file. The inference
service rejects requests whose `schema_version` major isn't `1`.

* `CAMERA_ID` must be 1-64 lowercase letters, digits, `.`, `_`, or `-`, because
  it becomes a topic segment. Use an opaque identifier rather than a site,
  asset tag, or location.
* The adapter refuses to start when `OUTPUT_TOPIC` matches the `INPUT_TOPIC`
  filter, including through wildcards, so it can't republish its own output.
  An `INPUT_TOPIC` such as `edge-ai/v1/+/camera/+/snapshots` is refused for
  that reason.
* Requests are published at QoS 1 without the retain flag.

### CloudEvents Attributes

Each request carries these MQTTv5 user properties:

| Attribute         | Value                                                                   |
|-------------------|-------------------------------------------------------------------------|
| `specversion`     | `1.0`                                                                   |
| `type`            | `image_snapshot`                                                        |
| `source`          | `EVENT_SOURCE`, `snapshot-normalizer` by default                        |
| `id`              | Random UUIDv4 generated for each request                                |
| `time`            | Producer `time` when it's valid RFC 3339, otherwise the processing time |
| `subject`         | `CAMERA_ID`                                                             |
| `datacontenttype` | `application/json`, also set as the MQTTv5 Content Type                 |
| `dataschema`      | `DATA_SCHEMA`, omitted when unset                                       |
| `traceparent`     | Propagated from the input when it's a valid W3C version `00` value      |

The request's `correlation_id` field carries the same value as `id`. Neither
is derived from producer identifiers, topics, or content, and both stay the
same across the publish retries of one request. The
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
* A key is recorded only after the broker acknowledges the request, so an
  input whose publish failed is never marked as published.
* State is held in memory per pod and is lost on restart. The Helm chart runs
  a single-replica StatefulSet for that reason.

### Delivery

Delivery is at least once. The adapter acknowledges each input after handling
ends. A request that fails to publish is attempted up to `PUBLISH_ATTEMPTS`
times, at most 10, with exponential backoff starting at 500 ms and capped at
30 s. A request the broker rejects with a failure reason isn't retried. Failed
requests are logged, counted as `publish_failed`, and dropped: the input is
still acknowledged, so the broker doesn't redeliver it, because MQTT
acknowledgements are delivered in receive order and an unacknowledged input
would block every later one.

The broker redelivers an input only when the adapter stops before
acknowledging it. Deduplication suppresses that redelivery when the same pod
already published the input within the window. After a restart the in-memory
keys are gone, so a redelivered input can be published twice with a new `id`.
Consumers that need exactly-once handling must deduplicate on their own key.

* The subscription uses retain handling "do not send", so a retained snapshot
  isn't replayed as a new request on every subscribe.
* The adapter fails at startup, and the pod restarts, when the broker rejects
  the subscription in its SUBACK, for example with `NotAuthorized`.
* The connection advertises a receive maximum of 8, so the broker holds at most
  eight unacknowledged inputs for the adapter, and a maximum packet size of
  `MAX_JPEG_BYTES` plus 64 KiB. The broker drops a larger input instead of
  delivering it, so such inputs aren't counted as `rejected_oversize`.

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
| `OUTPUT_TOPIC`              | No       | `edge-ai/v1/snapshot-normalizer/camera/{CAMERA_ID}/snapshots` | Concrete output topic                       |
| `EVENT_SOURCE`              | No       | `snapshot-normalizer`                                         | CloudEvents `source`, a URI reference       |
| `DATA_SCHEMA`               | No       |                                                               | CloudEvents `dataschema`, an absolute URI   |
| `MAX_JPEG_BYTES`            | No       | `4194304`                                                     | Largest accepted JPEG                       |
| `MAX_ENVELOPE_BYTES`        | No       | `8388608`                                                     | Largest accepted serialized request         |
| `DEDUP_CAPACITY`            | No       | `1024`                                                        | Most producer keys retained                 |
| `DEDUP_WINDOW_SECONDS`      | No       | `300`                                                         | Longest time a producer key is retained     |
| `PUBLISH_ATTEMPTS`          | No       | `3`                                                           | Publish attempts per request, 1-10          |
| `COUNTERS_INTERVAL_SECONDS` | No       | `60`                                                          | Interval between counter log lines          |
| `RUST_LOG`                  | No       | `info`                                                        | Log filter                                  |

Numeric values must be positive integers. Keep `MAX_ENVELOPE_BYTES` below the
broker's maximum packet size, leaving room for the topic and user properties.
The [memory profile](https://learn.microsoft.com/azure/iot-operations/reference/mqtt-support#broker-limits)
bounds that size: 4 MB for Tiny, 16 MB for Low, and 64 MB for Medium, the
default. The broker disconnects a client that sends a larger packet, so lower
both maxima on a Tiny profile, for example to 2 MiB and 3 MiB. The broker connection uses the
Azure IoT Operations SDK variables, including `AIO_BROKER_HOSTNAME`,
`AIO_BROKER_TCP_PORT`, `AIO_MQTT_CLIENT_ID`, `AIO_MQTT_SESSION_EXPIRY`,
`AIO_MQTT_USE_TLS`, `AIO_TLS_CA_FILE`, and `AIO_SAT_FILE`.

For local runs, `docker-compose.yaml` loads
[`.env.template`](.env.template) and then an optional `.env` in this directory.
Copy the template to `.env` to change values; `.env` is ignored by git.

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
* Runs a single-replica StatefulSet, so the pod name is always
  `<release fullname>-0` and no two copies run at once, with a read-only root
  file system and no exposed ports or probes.
* Sets `AIO_MQTT_CLIENT_ID` to `<clientIdPrefix>-<pod name>` through the
  Downward API, a client ID that is unique per release and stable across
  restarts, so the broker resumes the persistent session and its queued QoS 1
  inputs.
* Sets `AIO_MQTT_SESSION_EXPIRY` from `mqtt.sessionExpirySeconds`, 3600 by
  default, which bounds how long the broker keeps an orphaned session.
* Annotates the service account with `aio-broker-auth/workload:
  snapshot-normalizer`, which the broker exposes as an authorization attribute.

### Authorization

The chart doesn't create a BrokerAuthorization resource. Each listener port
links a single allow-only policy through its `authorizationRef`, so a separate
per-workload policy would either take no effect or, once linked, deny every
other client on that port. Creating broker resources from Kubernetes manifests
is also supported only for debugging and testing.

Instead, add a rule for the adapter to the BrokerAuthorization policy already
linked to the listener port it uses, and manage that policy through the Azure
portal, Bicep, or `az iot ops broker authz apply`, as described in
[Configure MQTT broker authorization](https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/howto-configure-authorization).
`az iot ops broker authz apply` replaces the policy with the configuration file
it's given, so include the policy's existing rules in that file. The policy
applies only when the port also links a BrokerAuthentication resource.

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
          - "edge-ai/v1/snapshot-normalizer/camera/+/snapshots"
```

The `workload` attribute comes from the chart's `aio-broker-auth/workload`
service account annotation. Verify the rule with a negative check: publishing
to a topic outside the rule should fail with a not-authorized reason.

## Testing

```bash
cd src/500-application/507-ai-inference/services/snapshot-normalizer
cargo test
cargo clippy --all-targets -- -D warnings
```

Unit tests cover configuration validation, rejection reasons, CloudEvents
attributes, random event IDs, capture-time and trace propagation, the
deduplication window, SUBACK handling, retain handling, and the capped retry
backoff.

## License

MIT. See the repository [LICENSE](../../../../../LICENSE).
