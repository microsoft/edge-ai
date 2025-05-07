# Minimum Single Node Cluster Blueprint

## Overview

This blueprint provides a minimal deployment of Azure IoT Operations (AIO) on a single-node, Arc-enabled Kubernetes cluster. It is designed to use the minimum required resources while still providing a functional edge deployment with Azure IoT Operations.
Please follow general blueprint recommendations from blueprints [README.md](../README.md).

## Architecture

This blueprint deploys:

1. A Linux VM host in Azure (minimum size)
2. A K3s Kubernetes cluster on the VM
3. Azure Arc connection for the cluster
4. Minimal cloud resources required by AIO (Key Vault, Storage, etc.)
5. Core Azure IoT Operations components

The resulting architecture provides a functional edge-to-cloud solution with the minimal resource footprint.

### What's Excluded

To minimize resource usage, the following components are excluded:

1. **Cloud Resources:**
   - Cloud Observability (monitoring resources)
   - Cloud Messaging (Event Grid, Event Hubs, Service Bus)
   - AKS & ACR (cloud-side Kubernetes and container registry)

2. **Edge Resources:**
   - Edge Observability (monitoring on the edge)
   - Edge Messaging (advanced messaging features)

3. **Optional Features:**
   - Processor and Simulation OPC operators
   - Advanced security features
   - Diagnostic settings
   - High availability features

## Terraform Structure

This blueprint consists of the following key components:

- **Main Configuration** (`main.tf`): Orchestrates the deployment workflow and module dependencies
- **Variables** (`variables.tf`): Defines input parameters with descriptions and defaults
- **Outputs** (`outputs.tf`): Exposes important resource information for future reference
- **Versions** (`versions.tf`): Specifies provider versions and requirements

### Key Modules Used in Terraform

| Module                    | Purpose                                 | Source Location                                          |
|---------------------------|-----------------------------------------|----------------------------------------------------------|
| `cloud_resource_group`    | Creates resource groups                 | `../../../src/000-cloud/000-resource-group/terraform`    |
| `cloud_security_identity` | Handles identity and security resources | `../../../src/000-cloud/010-security-identity/terraform` |
| `cloud_data`              | Creates data storage resources          | `../../../src/000-cloud/030-data/terraform`              |
| `cloud_vm_host`           | Creates the VM host for the cluster     | `../../../src/000-cloud/050-vm-host/terraform`           |
| `edge_cncf_cluster`       | Deploys K3s Kubernetes cluster          | `../../../src/100-edge/100-cncf-cluster/terraform`       |
| `edge_iot_ops`            | Installs Azure IoT Operations           | `../../../src/100-edge/110-iot-ops/terraform`            |

### Variable Reference in Terraform

Beyond the basic required variables, this blueprint supports these key configurations:

| Variable                                  | Description                        | Default  | Notes                                                      |
|-------------------------------------------|------------------------------------|----------|------------------------------------------------------------|
| `environment`                             | Environment type                   | Required | "dev", "test", "prod", etc.                                |
| `resource_prefix`                         | Prefix for resource naming         | Required | Short unique alphanumeric string (max 8 chars recommended) |
| `location`                                | Azure region location              | Required | "eastus2", "westus3", etc.                                 |
| `instance`                                | Deployment instance number         | `"001"`  | For multiple deployments                                   |
| `should_get_custom_locations_oid`         | Auto-retrieve Custom Locations OID | `true`   | Set to false when providing custom_locations_oid           |
| `custom_locations_oid`                    | Custom Locations SP Object ID      | `null`   | Required for Arc custom locations                          |
| `should_create_anonymous_broker_listener` | Enable anonymous MQTT listener     | `false`  | For dev/test only, not secure for production               |

For additional configuration options, review the variables in `variables.tf`.

## Prerequisites

**IMPORTANT:** We highly suggest using [this project's integrated dev container](../../../.devcontainer/README.md) to get started quickly with Windows-based systems and also works well with nix-compatible environments.

Refer to the Environment Setup section in the [Root README](../../../README.md#getting-started-and-prerequisites-setup) for detailed instructions on setting up your environment.

Ensure you have the following prerequisites:

- Sufficient quota for a VM in your target region
- At least 8 GB of RAM per VM, recommended 16 GB of RAM per VM
- Registered resource providers (see deployment instructions)
- Appropriate permissions to create resources

## Deploy Blueprint

Follow detailed deployment instructions from the blueprints README.md, [Detailed Deployment Workflow](../README.md#detailed-deployment-workflow)

## Scaling Up

This blueprint deploys a minimal configuration. If you need additional capabilities, consider:

1. For observability features, deploy the `edge_observability` module
2. For messaging features, deploy the `edge_messaging` module
3. For additional operators, modify the `edge_iot_ops` module variables
