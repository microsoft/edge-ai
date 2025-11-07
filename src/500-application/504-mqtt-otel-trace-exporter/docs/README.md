# MQTT to OpenTelemetry Trace Exporter

The MQTT to OpenTelemetry Trace Exporter bridges Azure IoT Operations MQTT topics to OpenTelemetry traces. This document provides configuration guidance and deployment examples for running the exporter with the accompanying Helm chart.

## Prerequisites

- Kubernetes 1.25+ cluster with access to your Azure IoT Operations MQTT broker
- Helm 3.12 or later
- `kubectl` configured for the target cluster
- An OpenTelemetry Collector endpoint or Azure Monitor ingestion endpoint
- Security Access Token (SAT) secret or x509 client certificates provisioned in the cluster

## Helm Configuration Overview

The chart exposes configuration through values that map directly to the exporter environment variables. Key sections include:

- `image`: Container repository, tag, and pull policy
- `satAuth`: SAT token secret mounting (enabled by default)
- `x509Auth`: Optional client certificate mounting
- `config`: Core exporter settings including telemetry and MQTT options

Refer to the `values.yaml` file for defaults and additional options.

## Telemetry Sampling and Batching

Telemetry tuning settings in `config.telemetry` map directly to the OpenTelemetry SDK environment variables. Adjust these values to control load on the collector and downstream systems:

- `samplingRatio` → `OTEL_TRACES_SAMPLER=traceidratio` with `OTEL_TRACES_SAMPLER_ARG`: Set to `1.0` for always-on sampling. Reduce the ratio (for example, `0.25`) to lower the volume of emitted spans while retaining representative traces.
- `maxExportBatchSize` → `OTEL_BSP_MAX_EXPORT_BATCH_SIZE`: Controls the number of spans exported in a single batch. Increase for higher throughput; decrease for steadier load on the collector.
- `maxQueueSize` → `OTEL_BSP_MAX_QUEUE_SIZE`: Limits the number of spans buffered in memory. Size this high enough to tolerate spikes but low enough to avoid memory pressure on small nodes.
- `scheduledDelayMillis` → `OTEL_BSP_SCHEDULE_DELAY`: Sets the cadence for flushing spans. Use shorter intervals for low-latency pipelines and longer intervals when batching is preferred.
- `exportTimeoutMillis` → `OTEL_BSP_EXPORT_TIMEOUT`: Adjust when the exporter should abandon an export attempt. Tune to align with collector SLAs and network latency expectations.

These knobs can be set either directly in `values.yaml` (under `config.telemetry`) or by overriding the corresponding environment variables in `config.extraEnv`.

## Scaling MQTT Clients

The exporter scales horizontally by running multiple replicas that participate in the same MQTT shared subscription group.

- Set `replicaCount` to the number of exporter pods required to meet throughput targets. The deployment template automatically enables a horizontal fan-out when `config.mqtt.sharedSubscriptionGroup` is defined.
- `config.mqtt.receiveMax` controls in-flight QoS1 message handling per connection. Increase it to boost throughput per client; ensure the broker cluster is sized accordingly.
- `config.mqtt.retryMinBackoffSecs` and `config.mqtt.retryMaxBackoffSecs` govern reconnect backoff. Adjust them to balance fast recovery with protection against thundering-herd reconnects.
- For bursty workloads, consider enabling Kubernetes Horizontal Pod Autoscaler (HPA) against CPU or custom metrics; the exporter does not enforce replica limits beyond the Helm values.

When scaling out, keep SAT or x509 secrets synchronized across replicas and confirm that the broker allows the chosen shared subscription semantics for the configured topic filters.

## OpenTelemetry Collector and Application Insights

Set `config.telemetry.collectorEndpoint` to the OTLP gRPC endpoint for your OpenTelemetry Collector. When forwarding traces to Application Insights:

1. Configure the collector with an Azure Monitor exporter and provide the Application Insights connection string or instrumentation key in the collector configuration.
2. Ensure network policies allow the exporter to reach the collector endpoint.
3. The exporter does not read Azure Monitor credentials directly; it forwards spans to the collector for ingestion.

## Authentication Scenarios

### SAT Tokens (Default)

- Enable SAT support by setting `satAuth.enabled=true`.
- Reference the Kubernetes secret containing keys `sat.token` and (optionally) `ca.crt` using `satAuth.secretName`.
- Set `satAuth.create=true` only for development scenarios where you supply token material directly in values.

### x509 Client Certificates

- Enable client certificates by setting `x509Auth.enabled=true` and referencing the TLS secret via `x509Auth.secretName`.
- Secrets should contain keys `tls.crt`, `tls.key`, and optionally `ca.crt`.
- When both SAT and x509 are enabled, verify the CA bundles align.

## Deployment Steps

1. Save the configuration values to a file (for example, `values.vm.yaml`).
1. Deploy or upgrade the release:

```bash
helm upgrade --install mqtt-otel-trace-exporter \
  /absolute/path/to/src/500-application/504-mqtt-otel-trace-exporter/charts/mqtt-otel-trace-exporter \
  --namespace aio-observability \
  --create-namespace \
  --values values.vm.yaml
```

1. Verify the deployment:

```bash
kubectl get pods -n aio-observability -l app.kubernetes.io/name=mqtt-otel-trace-exporter
kubectl logs deployment/mqtt-otel-trace-exporter -n aio-observability -c mqtt-otel-trace-exporter
```

Spans should appear in your configured collector backend with attributes such as `messaging.destination` and `correlation.id`.

## Troubleshooting

- **No spans exported**: Ensure the collector endpoint is reachable and correctly set.
- **Authentication errors**: Confirm SAT or x509 secrets are mounted with expected key names and paths.
- **Redelivery loop**: Check downstream processing latency and MQTT backoff settings.

## Application Insights Integration

Forward spans to Azure Application Insights by routing them through an OpenTelemetry Collector.

1. Deploy a collector that accepts OTLP traffic over gRPC.
1. Configure the collector with the Azure Monitor exporter and provide your Application Insights connection string.
1. Point the exporter at the collector endpoint by updating `config.telemetry.collectorEndpoint` in your Helm values.

### Sample Collector Configuration

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317

exporters:
  azuremonitor:
    connection_string: "InstrumentationKey=<your-instrumentation-key>;IngestionEndpoint=https://<region>.in.applicationinsights.azure.com/"

service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [azuremonitor]
```

### Helm Values Example

```yaml
config:
  telemetry:
    collectorEndpoint: "http://otel-collector.otel.svc.cluster.local:4317"
```

## Helm Values Template

Use the following template to bootstrap a `values.vm.yaml` file for your deployment. Adjust the fields to match your environment.

```yaml
replicaCount: 1

image:
  repository: ghcr.io/microsoft/edge-ai/mqtt-otel-trace-exporter
  pullPolicy: IfNotPresent
  tag: "1.0.0"

serviceAccount:
  create: true
  annotations: {}
  name: ""

satAuth:
  enabled: true
  secretName: mqtt-sat-token
  tokenKey: sat.token
  caCertKey: ca.crt
  mountPath: /var/secrets/mqtt
  create: false

x509Auth:
  enabled: false
  secretName: ""
  certKey: tls.crt
  keyKey: tls.key
  caCertKey: ca.crt
  mountPath: /var/secrets/mqtt-x509
  create: false
  secret:
    cert: ""
    key: ""
    caCert: ""

config:
  logLevel: info
  telemetry:
    collectorEndpoint: "http://otel-collector:4317"
    serviceName: mqtt-otel-trace-exporter
    serviceNamespace: edge-ai
    samplingRatio: 1.0
    maxExportBatchSize: 512
    maxQueueSize: 2048
    scheduledDelayMillis: 5000
    exportTimeoutMillis: 30000
  mqtt:
    brokerHost: mqtt-broker
    brokerPort: 1883
    clientId: ""
    topicFilters:
      - telemetry/#
    sharedSubscriptionGroup: edge-ai
    sessionExpirySecs: 86400
    receiveMax: 128
    keepAliveSecs: 30
    retryMinBackoffSecs: 5
    retryMaxBackoffSecs: 60
    useTls: true
  correlation:
    fieldName: correlationId
    allowGenerated: true

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

affinity: {}
nodeSelector: {}
tolerations: []
extraEnv: []
extraVolumeMounts: []
extraVolumes: []
```

## Additional Resources

- <https://learn.microsoft.com/azure/iot-operations/overview-mqtt>
- <https://opentelemetry.io/docs/collector/>
- <https://github.com/Azure/iot-operations-sdks>
