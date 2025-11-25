---
title: Robotics Blueprint
description: Complete robotics infrastructure solution with NVIDIA GPU support, KAI Scheduler, and optional Azure Machine Learning integration for GPU-accelerated compute and intelligent workload placement
author: Edge AI Team
ms.date: 11/03/2025
ms.topic: reference
keywords:
  - robotics
  - nvidia gpu
  - gpu operator
  - kai scheduler
  - azure machine learning
  - aks
  - kubernetes
  - terraform
  - infrastructure as code
  - gpu workloads
  - edge computing
estimated_reading_time: 10
---

Deploys robotics infrastructure with NVIDIA GPU support, KAI Scheduler, and optional Azure Machine Learning integration.

## Overview

The Robotics Blueprint provides a complete infrastructure solution for robotics workloads on Azure, featuring GPU-accelerated compute, intelligent scheduling, and optional integration with Azure Machine Learning. This blueprint leverages the [Robotics Module](../modules/robotics/terraform/) to orchestrate foundational resources optimized for robotics scenarios.

## Features

* **GPU Support**: NVIDIA GPU Operator for GPU resource management
* **Intelligent Scheduling**: KAI Scheduler for optimized workload placement
* **Robotics-Optimized Defaults**: Infrastructure creation flags favor robotics needs
* **Optional AzureML Integration**: Enable Azure ML workspace when needed
* **Flexible Chart Installation**: Choose robotics charts, AzureML charts, or both
* **Scalable Node Pools**: GPU node pool configuration with autoscaling

## Architecture

This blueprint consumes the **Robotics Module** with robotics-focused defaults:

* Chart installation defaults to robotics charts (NVIDIA GPU Operator, KAI Scheduler)
* Infrastructure creation enabled by default (networking, AKS, ACR, security)
* Optional observability and storage components available
* Optional AzureML integration for ML workloads

For complete module documentation including all configuration options, see the [Robotics Module README](../modules/robotics/terraform/README.md).

## Quick Start

```hcl
module "robotics" {
  source = "./blueprints/robotics/terraform"

  environment     = "dev"
  location        = "eastus2"
  resource_prefix = "robotics"
  instance        = "001"

  # GPU node pool configuration
  node_pools = {
    "gpu-a10" = {
      vm_size                     = "Standard_NV36ads_A10_v5"
      subnet_address_prefixes     = ["10.0.7.0/24"]
      pod_subnet_address_prefixes = ["10.0.8.0/24"]
      enable_auto_scaling         = true
      min_count                   = 1
      max_count                   = 4
      node_taints                 = ["nvidia.com/gpu=true:NoSchedule"]
    }
  }

  should_install_robotics_charts = true
}
```

## Variables

### Required Variables

* `environment` - Environment identifier: dev, test, or prod
* `location` - Azure region for all resources
* `resource_prefix` - Prefix for resource naming

### Key Optional Variables

* `instance` - Instance identifier (default: "001")
* `should_create_networking` - Create VNet and subnets (default: true)
* `should_create_aks_cluster` - Create AKS cluster (default: true)
* `should_create_acr` - Create Azure Container Registry (default: true)
* `should_install_robotics_charts` - Install NVIDIA GPU Operator, KAI Scheduler (default: true)
* `should_install_azureml_charts` - Install Volcano Scheduler (default: false)
* `node_pools` - Additional GPU node pools with configuration

For complete variable reference, see [variables.tf](terraform/variables.tf).

## Outputs

* `aks_cluster` - AKS cluster for robotics workloads
* `aks_oidc_issuer_url` - OIDC issuer URL for workload identity
* `acr_network_posture` - Container registry network posture
* `azureml_workspace` - Azure ML workspace (when enabled)
* `resource_group` - Resource group for robotics infrastructure
* `virtual_network` - Virtual network for robotics infrastructure

For complete output reference, see [outputs.tf](terraform/outputs.tf).

## Chart Installation

The blueprint installs robotics-specific charts by default:

* **NVIDIA GPU Operator**: GPU resource management and driver installation
* **KAI Scheduler**: Intelligent workload scheduling for robotics
* **GPU PodMonitor**: NVIDIA DCGM exporter metrics for Azure Monitor

Optionally enable AzureML charts:

```hcl
should_install_azureml_charts = true  # Adds Volcano Scheduler
```

### Manual Chart Installation

Install robotics charts:

```bash
cd blueprints/modules/robotics/terraform/scripts
./install-robotics-charts.sh
```

Install AzureML charts (optional):

```bash
cd blueprints/modules/robotics/terraform/scripts
./install-azureml-charts.sh
```

Validate GPU metrics:

```bash
./validate-gpu-metrics.sh
```

### Uninstalling Charts

Uninstall robotics charts:

```bash
cd blueprints/modules/robotics/terraform/scripts
./uninstall-robotics-charts.sh
```

Uninstall AzureML charts:

```bash
./uninstall-azureml-charts.sh
```

## GPU Metrics Monitoring

GPU metrics are collected from the NVIDIA DCGM exporter and published to Azure Managed Prometheus when robotics charts are installed.

### Available DCGM Metrics

| Metric                      | Description                                |
|-----------------------------|--------------------------------------------||
| `DCGM_FI_DEV_GPU_UTIL`      | GPU utilization percentage                 |
| `DCGM_FI_DEV_FB_USED`       | Frame buffer memory used (MB)              |
| `DCGM_FI_DEV_FB_FREE`       | Frame buffer memory free (MB)              |
| `DCGM_FI_DEV_GPU_TEMP`      | GPU temperature in °C                      |
| `DCGM_FI_DEV_POWER_USAGE`   | GPU power draw in watts                    |
| `DCGM_FI_DEV_SM_CLOCK`      | Streaming multiprocessor clock speed (MHz) |
| `DCGM_FI_DEV_MEM_CLOCK`     | Memory clock speed (MHz)                   |
| `DCGM_FI_DEV_PCIE_TX_BYTES` | PCIe transmit throughput (bytes)           |
| `DCGM_FI_DEV_PCIE_RX_BYTES` | PCIe receive throughput (bytes)            |
| `DCGM_FI_DEV_XID_ERRORS`    | GPU XID error count                        |

### Viewing GPU Metrics

#### Azure Portal Prometheus Explorer

1. Open your Azure Monitor workspace.
1. Navigate to **Metrics > Prometheus explorer**.
1. Run PromQL queries such as:

   ```promql
   DCGM_FI_DEV_GPU_UTIL
   DCGM_FI_DEV_FB_USED
   DCGM_FI_DEV_GPU_TEMP
   ```

#### Azure Managed Grafana

1. Download the NVIDIA DCGM dashboard:

   ```bash
   curl -o dcgm-exporter-dashboard.json \
     https://raw.githubusercontent.com/NVIDIA/dcgm-exporter/main/grafana/dcgm-exporter-dashboard.json
   ```

1. In Azure Managed Grafana, go to **Dashboards > Import**, upload the JSON, and select your Azure Monitor workspace as the data source.

### Troubleshooting GPU Metrics

1. Confirm DCGM exporter pods are healthy:

   ```bash
   kubectl get pods -n gpu-operator | grep dcgm
   ```

1. Inspect the PodMonitor resource:

   ```bash
   kubectl get podmonitor -n kube-system nvidia-dcgm-exporter
   kubectl describe podmonitor -n kube-system nvidia-dcgm-exporter
   ```

1. Validate metrics endpoint:

   ```bash
   kubectl port-forward -n gpu-operator <dcgm-pod-name> 9400:9400
   curl http://localhost:9400/metrics | grep DCGM
   ```

## Azure ML Integration

Enable Azure ML integration for ML workloads alongside robotics:

```hcl
should_integrate_aks_cluster = true
azureml_workspace_name       = "mlw-robotics-dev-001"
```

## Troubleshooting

### GPU Not Available

Verify GPU operator installation:

```bash
kubectl get pods -n gpu-operator
```

Check GPU resources on nodes:

```bash
kubectl get nodes -o json | jq '.items[].status.capacity'
```

### Chart Installation Failed

Check Helm releases:

```bash
helm list -A
```

Verify GPU Operator status:

```bash
helm status gpu-operator -n gpu-operator
```

Verify KAI Scheduler status:

```bash
helm status kai-scheduler -n kai-scheduler
```

### Node Pool Not Created

Verify node pool configuration:

```bash
az aks nodepool list --cluster-name <cluster-name> --resource-group <resource-group>
```

### GPU Workload Not Scheduling

Check node taints and pod tolerations:

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
kubectl describe pod <pod-name> | grep -A 5 Tolerations
```

## Sample GPU Workload

Deploy a robotics workload with GPU support and proper tolerations:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: robotics-gpu-workload
  namespace: default
spec:
  tolerations:
    - key: "nvidia.com/gpu"
      operator: "Exists"
      effect: "NoSchedule"
  containers:
    - name: robotics-container
      image: nvcr.io/nvidia/isaac-sim:latest
      resources:
        limits:
          nvidia.com/gpu: 1
        requests:
          nvidia.com/gpu: 1
      env:
        - name: NVIDIA_VISIBLE_DEVICES
          value: "all"
        - name: NVIDIA_DRIVER_CAPABILITIES
          value: "compute,utility"
```

## Related Resources

* [Robotics Module Documentation](../modules/robotics/terraform/README.md)
* [AzureML Blueprint](../azureml/) - For AzureML-focused deployments
* [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/)
* [KAI Scheduler](https://github.com/Azure/kaito)
* [NVIDIA Isaac Sim](https://developer.nvidia.com/isaac-sim)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
