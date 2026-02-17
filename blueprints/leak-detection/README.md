---
title: Leak Detection Blueprint
description: Purpose-built Azure IoT Operations deployment for leak detection in Oil & Gas and Energy environments using SSE camera connectors and EventHub dataflows
author: Edge AI Team
ms.date: 2025-06-07
ms.topic: reference
keywords:
  - azure iot operations
  - leak detection
  - sse connector
  - eventhub dataflows
  - edge computing
  - terraform
  - single node cluster
  - oil and gas
  - dlqc
estimated_reading_time: 3
---

## Leak Detection Blueprint

This blueprint deploys a single-node Azure IoT Operations cluster optimized for leak detection in Oil & Gas and Energy environments. It provisions the minimum set of cloud foundation, edge infrastructure, asset definitions, and EventHub dataflows required to stream leak detection events (HEARTBEAT, ALERT_DLQC, ALERT) from an SSE-connected analytics camera to the cloud.

Please follow general blueprint recommendations from blueprints [README.md](../README.md).

## Architecture

This blueprint deploys:

1. A Linux VM host in Azure
2. A K3s Kubernetes cluster on the VM
3. Azure Arc connection for the cluster
4. Cloud resources required by AIO (Key Vault, Storage, Schema Registry, etc.)
5. Azure IoT Operations components with SSE connector always enabled
6. Leak detection device and asset definitions via the Device Registry
7. EventHub dataflows for streaming leak alert events to the cloud
8. Observability stack (Grafana, Log Analytics, Azure Monitor)

The SSE connector ingests events from the on-premises analytics camera service. Three event types flow through the MQTT broker: HEARTBEAT for liveness, ALERT_DLQC for deep-learning quality-checked leak alerts, and ALERT for basic leak alerts. EventHub dataflows route these events to the cloud for downstream processing.

## Terraform Structure

This blueprint consists of the following key components:

* **Main Configuration** (`main.tf`): Orchestrates the deployment workflow and module dependencies
* **Variables** (`variables.tf`): Defines input parameters with descriptions and defaults
* **Outputs** (`outputs.tf`): Exposes important resource information for future reference
* **Versions** (`versions.tf`): Specifies provider versions and requirements
* **Example Assets** (`leak-detection-assets.tfvars.example`): Reference variable values for the leak detection camera device and asset

### Key Modules Used

| Module                    | Purpose                                  | Source Location                                          |
|---------------------------|------------------------------------------|----------------------------------------------------------|
| `cloud_resource_group`    | Creates resource groups                  | `../../../src/000-cloud/000-resource-group/terraform`    |
| `cloud_networking`        | Sets up virtual networking and NAT       | `../../../src/000-cloud/050-networking/terraform`        |
| `cloud_security_identity` | Handles identity and security resources  | `../../../src/000-cloud/010-security-identity/terraform` |
| `cloud_observability`     | Sets up monitoring infrastructure        | `../../../src/000-cloud/020-observability/terraform`     |
| `cloud_data`              | Creates data storage and schema registry | `../../../src/000-cloud/030-data/terraform`              |
| `cloud_messaging`         | Sets up EventHub and Event Grid          | `../../../src/000-cloud/040-messaging/terraform`         |
| `cloud_vm_host`           | Creates the VM host for the cluster      | `../../../src/000-cloud/051-vm-host/terraform`           |
| `cloud_acr`               | Deploys Azure Container Registry         | `../../../src/000-cloud/060-acr/terraform`               |
| `edge_cncf_cluster`       | Deploys K3s Kubernetes cluster with Arc  | `../../../src/100-edge/100-cncf-cluster/terraform`       |
| `edge_arc_extensions`     | Installs Arc extensions                  | `../../../src/100-edge/109-arc-extensions/terraform`     |
| `edge_iot_ops`            | Installs Azure IoT Operations            | `../../../src/100-edge/110-iot-ops/terraform`            |
| `edge_assets`             | Creates leak detection devices and assets| `../../../src/100-edge/111-assets/terraform`             |
| `edge_observability`      | Sets up edge monitoring                  | `../../../src/100-edge/120-observability/terraform`      |
| `edge_messaging`          | Deploys EventHub dataflows               | `../../../src/100-edge/130-messaging/terraform`          |

### Variable Reference

| Variable                                  | Description                               | Default  | Notes                                                      |
|-------------------------------------------|-------------------------------------------|----------|------------------------------------------------------------|
| `environment`                             | Environment type                          | Required | "dev", "test", "prod", etc.                                |
| `resource_prefix`                         | Prefix for resource naming                | Required | Short unique alphanumeric string (max 8 chars recommended) |
| `location`                                | Azure region location                     | Required | "eastus2", "westus3", etc.                                 |
| `instance`                                | Deployment instance number                | `"001"`  | For multiple deployments                                   |
| `should_get_custom_locations_oid`         | Auto-retrieve Custom Locations OID        | `true`   | Set to false when providing custom_locations_oid           |
| `custom_locations_oid`                    | Custom Locations SP Object ID             | `null`   | Required for Arc custom locations                          |
| `should_create_anonymous_broker_listener` | Enable anonymous MQTT listener            | `false`  | For dev/test only, not secure for production               |
| `namespaced_devices`                      | SSE camera device definitions             | `[]`     | See `leak-detection-assets.tfvars.example`                 |
| `namespaced_assets`                       | Leak detection asset definitions          | `[]`     | See `leak-detection-assets.tfvars.example`                 |
| `aio_features`                            | AIO feature configurations                | `null`   | Map of feature settings for Azure IoT Operations           |

For additional configuration options, review the variables in `variables.tf`.

### Key Differences from Full Single Node Cluster

This blueprint is a focused subset of the `full-single-node-cluster` blueprint with these key differences:

* **SSE connector always enabled** — `should_enable_akri_sse_connector` is hardcoded to `true`
* **EventHub dataflows enabled** — EventHub dataflows are always created for cloud ingestion
* **EventGrid dataflows disabled** — EventGrid dataflows are explicitly disabled
* **No AKS, AzureML, AI Foundry, PostgreSQL, Redis, or VPN** — Only the components needed for leak detection are included

## Asset Configuration

The `leak-detection-assets.tfvars.example` file provides a reference configuration for a single SSE-connected analytics camera with three event types:

| Event        | MQTT Topic                                         | QoS   | Purpose                            |
|--------------|-----------------------------------------------------|-------|-------------------------------------|
| `HEARTBEAT`  | `events/plant-alpha/leak-cam-01/camera/heartbeat`   | QoS0  | Camera liveness monitoring          |
| `ALERT_DLQC` | `alerts/plant-alpha/leak-cam-01/leak/dlqc`           | QoS1  | Deep-learning quality-checked alert |
| `ALERT`      | `alerts/plant-alpha/leak-cam-01/leak/basic`          | QoS1  | Basic leak detection alert          |

## Prerequisites

Ensure you have the following prerequisites:

* Sufficient quota for a VM in your target region
* At least 8 GB of RAM per VM, recommended 16 GB of RAM per VM
* Registered resource providers (see deployment instructions)
* Appropriate permissions to create resources

## Deployment

```bash
terraform init
terraform plan -var-file="leak-detection-assets.tfvars.example" -var="environment=dev" -var="resource_prefix=leakdet" -var="location=eastus2"
terraform apply -var-file="leak-detection-assets.tfvars.example" -var="environment=dev" -var="resource_prefix=leakdet" -var="location=eastus2"
```
