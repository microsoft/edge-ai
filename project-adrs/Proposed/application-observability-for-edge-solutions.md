# Application Observability for Edge-Deployed Solutions

Date: **2025-03-26**

## Status

- [ ] Draft
- [ ] Proposed
- [x] Accepted
- [ ] Deprecated

## Context

In modern distributed systems, observability is crucial for maintaining the health, performance, and reliability of edge-deployed solutions. This document outlines design choices for implementing observability at the edge, addressing the following business objectives:

- **Proactive Issue Detection and Easier Root Cause Analysis**: The observability platform will enable the identification and resolution of potential issues before they impact users.
  By quickly pinpointing the root cause of problems, downtime can be minimized. This ensures that service level objectives (SLOs)
  and service level indicators (SLIs) are consistently met for edge-deployed solutions.
- **Informed Decision-Making**: By leveraging metrics, logs, and traces collected from edge devices, stakeholders can make data-driven decisions regarding system improvements and resource allocation.
- **Improved Operational Efficiency**: Centralize monitoring for all HCI clusters and applications in a single unified platform to enhance operational efficiency.
- **Integration of Deployment Components**: Seamlessly integrate deployment components such as GitOps and CI/CD with the central observability platform.
- **Compatibility with Key Technologies**: Ensure the proposed solution is compatible with Stack HCI, Kubernetes, GitOps-based fleet management, and aligned with Microsoft's observability tech stack strategy.
- **Optimal Data Flow from Edge to Cloud**: As edge might be bandwidth constrained, optimize the flow of the telemetry from edge to observability platform.
- **Offline Capabilities**: The observability platform should be resilient to network outages. It must have the capability to automatically resume data collection and transmission once network connectivity is restored, ensuring no critical data is lost during downtime.

## Decision drivers

- **Proactive Issue Detection and Easier Root Cause Analysis**
- **Informed Decision-Making**
- **Improved Operational Efficiency**
- **Integration of Deployment Components**
- **Compatibility with Key Technologies**
- **Optimal Data Flow from Edge to Cloud**
- **Offline Capabilities**

## Considered options

- **Azure Monitor Container Insights**: A first-party solution from Microsoft that collects telemetry from edge containers systems and delivers to portfolio of services inside Azure Monitor depending on the type of signal.
- **OpenTelemetry Collector**: A vendor-agnostic open-source component designed to collect, process, and export telemetry data.
- **Azure Monitor Edge Pipeline (preview)**: A first-party solution from Microsoft for building data ingestion pipelines. Very similar to OpenTelemetry Collector. This product is NOT considered due to its preview status.

## Decision Conclusion

Based on the criteria, OpenTelemetry is recommended as the preferred technology. OpenTelemetry provides the capability to queue messages in memory or on a file system to handle network interruptions between the edge and Azure, ensuring reliable telemetry transport. Furthermore, OpenTelemetry offers flexibility in filtering metrics, logs, and traces, optimizing data transmission by selectively sending specific telemetry types and thereby reducing outbound network traffic from the edge. Lastly, it
should be noted that Microsoft recommends using the OpenTelemetry Collector as a data processing pipeline and is committed to using OpenTelemetry going forwards.

## Consequences

The use of OpenTelemetry will require the team to gain expertise in its administration and optimization. Additionally, existing systems and applications will need to be integrated with OpenTelemetry.

### Background

### Pillars of Observability

The purpose of an observability system is to collect, process, and export signals. These signals typically encompass three main components:

- **Metrics**: Quantitative data that measures various aspects of a system's performance and health, such as CPU usage, memory consumption, request rates, and error rates.
- **Logs**: Detailed, timestamped records of events and actions that occur within a system, providing context and insights into the behavior and state of applications and infrastructure.
- **Traces**: End-to-end records of requests or transactions as they propagate through different services and components in a distributed system, helping to identify performance bottlenecks and dependencies.

For more information on these pillars and differences between metrics, traces, and logs, please refer to [Observability - Engineering Fundamentals Playbook](https://microsoft.github.io/code-with-engineering-playbook/observability/).

---

## Edge Observability Design

In an edge system, the ability to send telemetry to the cloud for analysis requires 1. instrumented systems and 2. an agent that facilitates gathering and transmitting telemetry data to the cloud.

![Anatomy Observable System](./images/Anatomy_Observable_System.png)

[Azure Monitor](https://learn.microsoft.com/azure/azure-monitor/overview) is the umbrella term for a range of products that provide instrumentation, transportation, storage, alerting, and analysis capabilities.

![Azure Monitor](./images/Azure_Monitor_System.png)

- Credits

[Azure Monitor Overview](https://learn.microsoft.com/azure/azure-monitor/overview)

---

## Data Sources

For sending telemetry back to cloud, the following options were evaluated:

1. [Azure Monitor Container Insights](https://learn.microsoft.com/azure/azure-arc/kubernetes/extensions-release#azure-monitor-container-insights) – A first-party solution from Microsoft that collects telemetry from edge containers systems and delivers to portfolio of services inside Azure Monitor depending on the type of signal.
2. [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/) – A vendor-agnostic open-source component designed to collect, process, and export telemetry data.
3. [Azure Monitor Edge Pipeline (preview)](https://learn.microsoft.com/azure/azure-monitor/essentials/edge-pipeline-configure?tabs=Portal) – A first-party solution from Microsoft for building data ingestion pipelines. Very similar to OpenTelemetry Collector. This product is NOT considered due to its preview status.

| **Data Source**                       | **Ease of Deployment**                                      | **Supported Environments**       | **Data Collection**                                                                                      | **Storage**                                                                                  |
|---------------------------------------|-------------------------------------------------------------|----------------------------------|----------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| Azure Monitor Container Insights      | Easy. Enabled as an extension.                              | Supported in Azure only          | Automatically of predefined resources. [Collection rules can be configured as needed.]                   | Azure Monitor                                                                                |
| OpenTelemetry Collector               | Medium. Deployed using GitOps-based workflow. Requires YAML | Multi-cloud, on-premise, hybrid. | More flexibility. Manual or automatic instrumentation. [Vast array of open-source collectors available.] | Multiple backends including Application Insights, New Relic, ElasticSearch, Prometheus, etc. |
| Azure Monitor Edge Pipeline (preview) | Not considered due to its preview status.                   | -                                | -                                                                                                        | -                                                                                            |

---

## Data Platform

A data platform is used for aggregating, analyzing, and visualizing telemetry data to gain insights into system performance, health, and operational efficiency.

| **Platform**             | **Description**                                                  | **Metrics** | **Logs** | **Traces** |
|--------------------------|------------------------------------------------------------------|-------------|----------|------------|
| Azure Monitor Metrics    | Time-series database optimized for analyzing time-stamped data.  | Yes         | No       | No         |
| Azure Managed Prometheus | A PromQL interface on top of Azure Monitor Metrics.              | Yes         | No       | No         |
| Log Analytics            | Provides a powerful analysis engine and rich query language KQL. | Yes         | Yes      | No         |
| Application Insights     | Helps developers with correlation.                               | Yes         | Yes      | Yes        |

## Visualization

### Overview of Visualization Platforms

| **Description**                                 | **Workbooks**                                                                         | **Dashboard**             | **Grafana**                                                                                                                                                                          | **Power BI**                             |
|-------------------------------------------------|---------------------------------------------------------------------------------------|---------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------|
| Existing dashboards                             | Yes                                                                                   | -                         | Yes                                                                                                                                                                                  | Yes                                      |
| Sharing dashboards                              | Yes                                                                                   | No                        | Yes                                                                                                                                                                                  | Yes                                      |
| Existing dashboards and data source integration | Out-of-the-box and public GitHub templates and reports. Limited to Azure Monitor.     | Limited to Azure Monitor. | Can connect to various data sources including relational and timeseries databases. Grafana has popular plugins and dashboard templates for application performance monitoring (APM). | Integrate data from multiple data source |
| Prometheus support                              | No but integration with Azure Monitor Metrics enabled it to query Prometheus metrics. | -                         | Yes                                                                                                                                                                                  | -                                        |
| Realtime                                        | Yes                                                                                   | No                        | Yes                                                                                                                                                                                  | No                                       |

A detailed comparison can be found here: [Azure Monitor best practices - Analysis and visualizations - Azure Monitor](https://learn.microsoft.com/azure/azure-monitor/best-practices-analysis). You can use Metrics Explorer to interactively work with metric data and create metric alerts. You need minimal training to use Metrics Explorer, but you must be familiar with the metrics you want to analyze.

---

## Proposed Development Plan

### Architecture

![Detailed Architecture](./images/Observability_detailed_architecture.png)

1. An OpenTelemetry Collector instance will be deployed per environment supporting software development lifecycle (SDLC). This enables the development, testing, and deployment in a controlled and systematic manner.
2. Azure Monitor Agent (AMA) will be configured to pull telemetry from OpenTelemetry Collector’s Prometheus. AMA is used as an agent in the middle to push telemetry to Azure Managed Prometheus. Presently AMA supports only Azure RBAC for authorization. AMA helps to connect OpenTelemetry with Prometheus with the help of Service Principal.
   - This necessitates coordination between AIO telemetry collection pipeline as AIO also configures AMA agent to pull telemetry.
3. A Kubernetes service will be deployed to enable OTLP instrumented workloads to send telemetry to service at `<service-name>.<namespace>.svc.cluster.local:4317`.
4. Control Tower will publish a custom metric showing the most recent successful telemetry push to Blob storage. This means that no additional configuration will be needed to connect Azure Managed Grafana to Azure Table Storage.

---

## OpenTelemetry Collector Pipeline

In [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/), receivers are components that collect telemetry data from various sources, processors are responsible for transforming, filtering, and enriching the collected data, and exporters send the processed telemetry data to designated backends or storage systems.

![Open Telemetry Collector1](./images/otel_collector1.png)

Credits: [OpenTelemetry Collector Documentation](https://opentelemetry.io/docs/collector/)

![Open Telemetry Collector2](./images/otel_collector2.png)

### Pipeline: Receivers

| **Receiver**                                                                                                                           | **Description**                                                       |
|----------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------|
| [OTLP Receiver](https://github.com/open-telemetry/opentelemetry-collector/blob/main/receiver/otlpreceiver/README.md)                   | Receives data via gRPC or HTTP using OTLP format.                     |
| [Kubelet Stats Receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/kubeletstatsreceiver)    | Node, pod, container, and volume metrics.                             |
| [Kubernetes Cluster Receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/k8sclusterreceiver) | Collects cluster-level metrics and entity events.                     |
| [RabbitMQ Receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/rabbitmqreceiver)             | Receive telemetry information from edge gateway’s RabbitMQ component. |

---

### Pipeline: Processors

| **Processor**                                                                                                             | **Description**                          |
|---------------------------------------------------------------------------------------------------------------------------|------------------------------------------|
| [Batch Processor](https://github.com/open-telemetry/opentelemetry-collector/blob/main/processor/batchprocessor/README.md) | Batching helps better compress the data. |

---

### Pipeline: Exporters

| **Exporter**                                                                                                                        | **Description**                                          |
|-------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------|
| [Azure Monitor Exporter](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/azuremonitorexporter) | Sends logs, traces, and metrics to Application Insights. |
| [Prometheus Exporter](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/prometheusexporter)      | Exports data in Prometheus format.                       |

---

## Helpers

| **Helper**                                                                                                               | **Description**                                                      |
|--------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------|
| [Exporter Helper](https://github.com/open-telemetry/opentelemetry-collector/blob/main/exporter/exporterhelper/README.md) | Retry capabilities with ability to persist metrics and logs to disk. |

---

## Extensions

| **Extension**                                                                                                             | **Description**                         |
|---------------------------------------------------------------------------------------------------------------------------|-----------------------------------------|
| [File Storage](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/storage/filestorage) | Persist state to the local file system. |

---

## Estimating Storage Requirements

As noted earlier, Exporter Helper will be deployed to queue messages to disk in case of failures. Configurations must consider both short-term network disruptions and long-term outages. The following calculations walkthrough estimating queue size and figuring out appropriate values for timeouts and backoff.

### Estimating storage

Metrics

One of the chattiest receivers we deploy is the Kubelet Stats Receiver, which broadcasts a payload every 20 seconds. The payload size is proportional to the number of workloads and currently includes 64 metrics in numeric (integers and floats) and string formats. If we estimate that each field on average takes 10 bytes (about 10 characters in utf-8, 4 bytes for float, 8 bytes long, etc.), then we have ![Obs Equation3](./images/Obs_Equation3.png) We can round it up to 1 KB for simplicity.

Then for 1 hour, data transmitted is
![Obs Equation2](./images/Obs_Equation2.png)

We round up to a whole number meaning we need to store 5 MB of data/day/workload.

### Logs & Traces

Logs and traces are a function of the rate and size of log statements. Let’s estimate this to be 1 GB/day.
![Obs Equation4](./images/Obs_equation4.png)

## Configuration

Based on the rate of production, storage requirements, and maximum tolerable data loss, we propose the following configurations:

- Max outage = 1 day
- PVC storage minimum = 10 GB/day
- retry_on_failure
  - initial_interval = 30
  - max_interval = 60
  - max_elapsed_time = 86400 (1 day)
- sending_queue
  - num_consumers = 10
  - queue_size = 3000 (Calculated as 86400/30 = 2880 rounded up to thousands)

### Deployment and Deployment Artifacts

The open-source contributor version of OpenTelemetry Collector will be deployed using a GitOps-based workflow. The contributor version is deployed because it includes the exporters (Azure Monitor) and helpers (File Storage) required for our solution.

Furthermore, while the OpenTelemetry Collector does come with an official Helm Chart, it may not meet some of the requirements when it comes to configuration. This may necessitate an extension to the existing chart or writing a custom deployment manifest.

Deployments must ensure:

1. PersistentVolumeClaim is attached to each deployed instance for caching to local disk.
2. Service per deployed instance of Collector to ensure reachability via HTTP/gRPC.

## Merging Azure IoT Operations Configuration

![Merging Azure IoT Operations Configuration](./images/IoT_Operations_Configuration.png)

The Azure Monitor Agent (AMA) will be configured to pull telemetry from OpenTelemetry Collector’s Prometheus. Azure IoT Operations also configures AMA to pull telemetry from the Prometheus server running inside of AIO. This presents a conflict in configuration.

A unified `ama-metrics-prometheus-config` configuration will be created. This configuration will merge the AIO configuration with additional configurations to scrape telemetry from `<service-name>.<namespace>.svc.cluster.local:8889/metrics` for each deployed OpenTelemetry Collector instance.

### Security

It should be noted that opentelemetry-collector-contrib image is hosted externally and available via both Docker Hub and GitHub Container Registry.

### Data Retention

#### Metrics

By default, platform and custom metrics are stored for 93 days. Prometheus metrics are stored for 18 months, but a PromQL query can only span a maximum of 32 days. Based on the nature of this solution, we recommend continuing with the default retention policy for metrics.

#### Logs and Traces

By default, Log Analytics workspaces have a data retention period of 30 days. This retention policy is configurable. Based on the nature of the solution and customer feedback, a retention period of 93 days will be configured for this solution.

### Alerting

Azure Monitor Alerts helps to detect and notify users when certain alerting rules are met. Alerting rules can be configured on data sources that include Azure Monitor Metrics, Log Analytics, and Prometheus.

For this engagement, the following type of alerts will be implemented:

![Alert Workflow](./images/Alerting_System.png)

| **Alert Type**    | **Data Sources**                    | **Type**      | **Comments**                                                                                                                                                               |
|-------------------|-------------------------------------|---------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Metric alerts     | Azure Monitor, Application Insights | Metrics, Logs | Metrics can be platform metrics, custom metrics, logs from Azure Monitor or Application Insights. Metric alerts can also apply multiple conditions and dynamic thresholds. |
| Log search alerts | Log Analytics Workspace             | Logs          | Query Log Analytics to evaluate resource logs at a predefined frequency.                                                                                                   |
| Prometheus alerts | Azure Monitor Managed Prometheus    | Metrics       | Alert rules are based on the PromQL open-source query language.                                                                                                            |

### Alert Criteria

Alert Query

```kql
traces
| where message contains "*********************Consumers done...."
| summarize
    RunningSince = arg_min(timestamp, ''),
    LastRun = arg_max(timestamp, ''),
    Count = count()
by
    Location = tostring(customDimensions['location']),
    severityLevel,
    Environment = tostring(customDimensions['environment'])
| project
    Location,
    RunningSince,
    LastRun,
    Count,
    severityLevel,
    TimeSinceLastRun = now() - LastRun,
    Health = iff(datetime_part("minute", todatetime(now() - LastRun)) < 19 and datetime_part("hour", todatetime(now() - LastRun)) == 0, 'Healthy', 'Error'),
    Environment
| where Health contains "Error" and Environment contains "prod"
```

Besides using the alert query to identify the alerts, the following scenarios must be covered.

1. Application fatal issues
2. SQL Server connectivity issues
3. Blob Storage connectivity issue
4. Unable to find tables in SQL Server
5. Partial or Incorrect SQL results

### The following alerting mechanisms will be implemented

### Service Identification

Each instrumented workload will be identified by its `service.name`. It will be a string composed of:

- `plant_id-environment-application_name`

Because multiple versions of an application may be deployed, each application will be further delineated by `service.version`.

Both properties will be available to applications via environment variables:

- `OTEL_SERVICE_NAME`
- `OTEL_RESOURCE_ATTRIBUTES="service.version=<VERSION>"`

### Instrumentation in Workloads

Applications that implement OTLP instrumentation must retrieve the following environment variables:

- `OTEL_SERVICE_NAME`
- `OTEL_RESOURCE_ATTRIBUTES`
- `OTEL_EXPORTER_OTLP_ENDPOINT`
- `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`
- `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT`
- `OTEL_EXPORTER_OTLP_LOGS_ENDPOINT`
- `OTEL_EXPORTER_OTLP_INSECURE=true` (secure without certificate validation)

The following changes will be implemented:

1. Platform configurations will be updated to expose these values per cluster.
2. Applications will be able to read these values using the following code:

```yaml
spec:
  containers:
  - name: {{ .Values.app.name }}
    image: {{ .Values.image }}
    env:
      - name: OTEL_EXPORTER_OTLP_ENDPOINT
        valueFrom:
          configMapKeyRef:
            name: platform-config
            key: OTEL_EXPORTER_OTLP_ENDPOINT
```

## Control Tower

Control Tower currently uses a checkpoint system implemented in Azure Table Storage. This system records the timestamp of the last successful file upload, allowing the application to track and determine the most recent upload event. By doing so, it ensures continuity and prevents redundant uploads.

### Publishing a custom metric

In lieu of querying Azure Table Storage, we propose publishing a custom metric finished_execution. This has two advantages:

1. In the existing IoT Edge module-based solution, cloud synchronization is handled by IoT Edge. However, there may be inaccuracies since a checkpoint record is written to Azure Table Storage before the synchronization occurs.
2. No need to provision read permissions between Blob Storage and Grafana.

This metric can be published by Control Tower application code or RClone sidecar that is responsible for data synchronization.

### Application publishes metric (chosen path)

The code changes to application will look like:

```python
from opentelemetry import metrics

meter = metrics.get_meter(__name__)

counter = meter.create_counter(
    name="last_successful_uploaded_timestamp",
    unit="1",
    description="The last successfully file uploaded timestamp",
)

counter.add(1)
```

It is recommended to use a [counter](https://opentelemetry.io/docs/specs/otel/metrics/data-model/): a value of 1 or more indicates a recorded checkpoint, while a value of 0 or the absence of a value indicates a failure. If the application publishes the metric, there will still be inaccuracies between the checkpointed record and the synchronization of files to the cloud discussed previously. Due to this, this approach is NOT recommended.

### RClone publishes metric (alternative path)

```bash
#!/usr/bin/env bash

# Import functions
. opentelemetry-shell/library/otel_metrics.sh

# Main
otel_metrics_push_gauge "ko.wal.ski/brain/memory/used_bytes" \
  "By" \
  $RANDOM \
  int
```

## Service-level Indicators

| **Metric**                        | **Description**                                             |
|-----------------------------------|-------------------------------------------------------------|
| .sql_connection_created           | 1 = true, 0 = false. Able to establish a connection to SQL. |
| total_files_created_count         | Count of files to be created.                               |
| total_files_created_size_in_bytes | The total size of files created in bytes.                   |
| elapsed_time                      | Time it took to run the entire job.                         |
| num_sql_queries_with_data         | Number of SQL queries that returned data.                   |
| finished_execution                | Publish 1 to indicate a successful run.                     |

## Dashboard

A Grafana dashboard will be created to provide fleet-wide visibility into Control Tower operations. This dashboard will mirror the functionality of an existing dashboard in Azure Workbooks. To aid in reducing number of tiles and enhance usability, additional filtering options will be introduced. These options will include filters for at least plant location and environment (e.g., dev, stage, prod). A more detailed dashboard will be built to enable correlation of logs and metrics per deployed instance.

## Capacity Requirements

### CPU & Memory

[Scaling](https://opentelemetry.io/docs/collector/scaling/) the OpenTelemetry Collector depends on the telemetry production rate, consumption rate, and queue size. Previously, we suggested a queue size of 3000 and a data production rate of 5 MB per day per workload being written to disk. This indicates that we may not require much memory. Therefore, we empirically propose the following which fits with our requested CPU and memory specifications documented in Resource Utilization & Capacity Estimates.

| **Application**         | **Multiplicity** | **Min CPU** | **Min Memory** | **Max CPU** | **Max Memory** | **Comments**                          |
|-------------------------|------------------|-------------|----------------|-------------|----------------|---------------------------------------|
| OpenTelemetry Collector | Per environment  | 500m        | 1024Mi         | 2000m       | 2048Mi         |                                       |
| Azure Monitoring Agent  | Per cluster      | 405m        | 1100Mi         | 14100m      | 29700Mi        | Already captured in capacity requests |
| **Total**               |                  | 905m        | 2124Mi         | 16100m      | 31748Mi        |                                       |

---
