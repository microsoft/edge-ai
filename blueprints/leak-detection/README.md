---
title: Leak Detection Blueprint
description: Purpose-built Azure IoT Operations deployment for leak detection in Oil & Gas and Energy environments using SSE camera connectors and EventHub dataflows
author: Edge AI Team
ms.date: 2026-02-19
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
estimated_reading_time: 10
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

Deployment follows four phases: build container images locally, deploy infrastructure with Terraform (which creates ACR), push images to the newly created ACR, and deploy the edge applications onto the Arc-connected cluster.

### End-to-End Deployment Workflow

1. **Build images locally** — compile and package the three edge application containers on your local machine
2. **Deploy infrastructure** — run Terraform to provision the VM, K3s cluster, Arc connection, IoT Operations, networking, ACR, and all supporting cloud resources
3. **Push images to ACR** — tag and push the locally built images to the ACR created in phase 2
4. **Deploy edge apps** — connect to the cluster via Arc proxy and deploy the application workloads with Kustomize and Helm

### Phase 1: Build Container Images Locally

Three application images are required:

| Image                    | Source Component              | Description                                    |
|--------------------------|-------------------------------|------------------------------------------------|
| `sse-server`             | `509-sse-connector`           | SSE camera connector for event ingestion       |
| `ai-edge-inference`      | `507-ai-inference`            | ONNX-based leak detection inference service    |
| `media-capture-service`  | `503-media-capture-service`   | FFmpeg/OpenCV media capture and storage        |

Images are built locally because `503-media-capture-service` compiles FFmpeg, OpenCV, and Rust from source (~30 minutes), which exceeds ACR Build task time limits.

Run `build-app-images-local.sh` from the blueprint scripts directory. Set `TF_IMAGE_VERSION` to tag the images (defaults to `latest`).

```bash
cd blueprints/leak-detection/scripts
export TF_IMAGE_VERSION="1.0.0"
./build-app-images-local.sh
```

This produces three local Docker images: `sse-server`, `ai-edge-inference`, and `media-capture-service`, each tagged with the specified version.

> **Note:** This phase has no cloud dependencies. You can build images while waiting for infrastructure to deploy, or build them beforehand.

### Phase 2: Deploy Infrastructure with Terraform

From the blueprint Terraform directory, initialize and apply the configuration. Key variables to set:

| Variable                             | Example Value | Purpose                                          |
|--------------------------------------|---------------|--------------------------------------------------|
| `resource_prefix`                    | `leakdet`     | Short alphanumeric prefix for all resource names |
| `environment`                        | `dev`         | Environment type (dev, test, prod)               |
| `location`                           | `eastus2`     | Azure region for deployment                      |
| `should_deploy_edge_applications`    | `true`        | Enables ACR and app deployment outputs           |
| `acr_public_network_access_enabled`  | `true`        | Allows image push/pull over public network       |

Terraform deploys the full stack: resource group, virtual network, NAT gateway, VM host, K3s cluster, Azure Arc connection, Key Vault, Storage Account, Schema Registry, Azure Container Registry, IoT Operations, device and asset definitions, EventHub dataflows, and observability.

```bash
cd blueprints/leak-detection/terraform
terraform init
terraform plan \
  -var-file="leak-detection-assets.tfvars.example" \
  -var="environment=dev" \
  -var="resource_prefix=leakdet" \
  -var="location=eastus2"
terraform apply \
  -var-file="leak-detection-assets.tfvars.example" \
  -var="environment=dev" \
  -var="resource_prefix=leakdet" \
  -var="location=eastus2"
```

> **Note:** If Key Vault or Storage Account is configured with private access, use `terraform apply -refresh=false` on subsequent applies to avoid refresh errors from network restrictions.

### Phase 3: Push Images to ACR

Now that Terraform has created the Azure Container Registry, push the locally built images. The ACR name is available from the Terraform output.

```bash
cd blueprints/leak-detection/terraform
export TF_ACR_NAME=$(terraform output -raw acr_name)
export TF_IMAGE_VERSION="1.0.0"
cd ../scripts
./build-app-images.sh
```

This script logs into the ACR, tags each local image with the ACR registry prefix, and pushes all three images.

> **Note:** The ACR must have `anonymousPull` enabled so the edge cluster can pull images without pull secrets. Alternatively, configure image pull secrets on the cluster.

### Phase 4: Deploy Edge Applications

After Terraform completes, deploy the application workloads to the Arc-connected cluster.

#### Step 1: Source init-scripts.sh

Source the IoT Operations init script to establish an Arc proxy tunnel and export required environment variables from Terraform output.

```bash
cd blueprints/leak-detection/terraform
source ../../../src/100-edge/110-iot-ops/scripts/init-scripts.sh
```

This script:

* Starts `az connectedk8s proxy` to create an HTTPS tunnel (port 9800) to the Arc-connected cluster
* Waits for the kubeconfig to become ready
* Creates the AIO namespace if it does not exist
* Exports `TF_*` environment variables from Terraform output for use by downstream scripts

#### Step 2: Set required environment variables

The `init-scripts.sh` script exports most variables automatically from Terraform output. Verify these are set:

| Variable                       | Description                                        |
|--------------------------------|----------------------------------------------------|
| `TF_CONNECTED_CLUSTER_NAME`    | Arc-connected cluster name                         |
| `TF_RESOURCE_GROUP_NAME`       | Azure resource group name                          |
| `TF_AIO_NAMESPACE`             | Kubernetes namespace for AIO (azure-iot-operations)|
| `TF_MODULE_PATH`               | Terraform module path                              |
| `TF_ACR_NAME`                  | Azure Container Registry name                      |
| `TF_IMAGE_VERSION`             | Image tag for deployments                          |
| `TF_APP_509_PATH`              | Path to 509-sse-connector source                   |
| `TF_APP_507_PATH`              | Path to 507-ai-inference source                    |
| `TF_APP_503_PATH`              | Path to 503-media-capture-service source           |
| `TF_STORAGE_ACCOUNT_ENDPOINT`  | Blob storage endpoint for ACSA EdgeSubvolume       |

#### Step 3: Run deploy-edge-apps.sh

Deploy all three applications to the cluster:

```bash
cd blueprints/leak-detection/scripts
./deploy-edge-apps.sh
```

The script executes the following sequence:

1. Deploys `509-sse-connector` via Kustomize (generates ACR image patches, applies manifests)
2. Deploys `507-ai-inference` via Kustomize
3. Creates an ACSA PersistentVolumeClaim (`pvc-acsa-cloud-backed`) with `cloud-backed-sc` StorageClass
4. Creates an ACSA EdgeSubvolume for media storage with managed identity authentication
5. Deploys `503-media-capture-service` via Helm with the ACSA PVC
6. Deploys the `model-downloader-job` to fetch the ONNX model for inference
7. Waits for all three deployment rollouts to complete

#### Step 4: Verify deployment

Confirm all three application pods are running:

```bash
kubectl get pods -n azure-iot-operations -l 'app in (sse-server,ai-edge-inference,media-capture-service)'
```

Expected output:

```text
NAME                                      READY   STATUS    RESTARTS   AGE
sse-server-6b8f9c4d5-x2k7m                1/1     Running   0          2m
ai-edge-inference-7c9d8e5f6-n3p4q          1/1     Running   0          2m
media-capture-service-8d0e9f6g7-r5s6t      1/1     Running   0          2m
```

## Troubleshooting

### ImagePullBackOff

The cluster cannot pull images from ACR. Verify that `anonymousPull` is enabled on the ACR, or configure image pull secrets on the cluster. Confirm the image tag matches what was pushed.

### CrashLoopBackOff on ai-edge-inference

The inference service requires the ONNX model to be present at `/models/default.onnx`. Verify the `model-downloader-job` completed successfully:

```bash
kubectl get jobs -n azure-iot-operations
kubectl logs job/model-downloader -n azure-iot-operations
```

### Arc Proxy Connection Drops

The `az connectedk8s proxy` tunnel can drop after periods of inactivity. Re-source the init script to re-establish connectivity:

```bash
cd blueprints/leak-detection/terraform
source ../../../src/100-edge/110-iot-ops/scripts/init-scripts.sh
```

### PVC Binding Failures

Verify the correct StorageClass exists on the cluster:

* `cloud-backed-sc` — required for ACSA-backed PVCs (media storage with cloud sync)
* `local-path` — used for local-only volumes

```bash
kubectl get storageclass
kubectl describe pvc pvc-acsa-cloud-backed -n azure-iot-operations
```
