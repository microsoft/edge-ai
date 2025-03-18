# Full Multi-node Cluster Blueprint

## Overview

This blueprint provides a complete end-to-end deployment of Azure IoT Operations (AIO) on a multi-node, Arc-enabled Kubernetes cluster. It deploys all necessary components from VM creation to AIO installation, resulting in a production-grade edge computing environment with high availability that integrates with Azure cloud services.
Please follow general blueprint recommendations from blueprints [README.md](../README.md).

## Architecture

This blueprint deploys:

1. Multiple Linux VM hosts in Azure (default: 3 nodes)
2. A K3s Kubernetes cluster with one server node and multiple worker nodes
3. Azure Arc connection for the cluster
4. Cloud resources required by AIO (Key Vault, Storage, etc.)
5. Azure IoT Operations components (MQTT Broker, Data Processor, etc.)
6. Optional messaging and observability components

The resulting architecture provides a resilient, high-availability edge-to-cloud solution with secure communication, data processing capabilities, and comprehensive monitoring suitable for production environments.

## Terraform Structure

This blueprint consists of the following key components:

- **Main Configuration** (`main.tf`): Orchestrates the deployment workflow and module dependencies
- **Variables** (`variables.tf`): Defines input parameters with descriptions and defaults
- **Outputs** (`outputs.tf`): Exposes important resource information for future reference
- **Locals** (`locals.tf`): Contains local variable calculations and transformations
- **Providers** (`providers.tf`): Configures the required Terraform providers

### Key Modules Used

| Module                       | Purpose                                   | Source Location                                 |
|------------------------------|-------------------------------------------|-------------------------------------------------|
| `vm_host`                    | Creates multiple VM hosts for the cluster | `../../../src/010-vm-host/terraform`            |
| `cncf_cluster_install`       | Deploys multi-node K3s Kubernetes cluster | `../../../src/020-cncf-cluster/terraform`       |
| `iot_ops_cloud_requirements` | Sets up cloud prerequisites for AIO       | `../../../src/030-iot-ops-cloud-reqs/terraform` |
| `iot_ops_install`            | Installs Azure IoT Operations             | `../../../src/040-iot-ops/terraform`            |
| `messaging`                  | Deploys messaging components              | `../../../src/050-messaging/terraform`          |
| `observability`              | Sets up monitoring and observability      | `../../../src/070-observability/terraform`      |
| `iot_ops_utilities`          | Installs AIO utility components           | `../../../src/080-iot-ops-utility/terraform`    |
| `onboard_requirements`       | Handles onboarding prerequisites          | `../../../src/005-onboard-reqs/terraform`       |

## Variable Reference

Beyond the basic required variables, this blueprint supports advanced customization:

| Variable             | Description                        | Default  | Notes                                    |
|----------------------|------------------------------------|----------|------------------------------------------|
| `host_machine_count` | Number of VM hosts for the cluster | `3`      | First host is server, others are workers |
| `environment`        | Environment type                   | Required | "dev", "test", "prod", etc.              |
| `resource_prefix`    | Prefix for resource naming         | Required | Short unique alphanumeric string         |
| `location`           | Azure region location              | Required | "eastus2", "westus3", etc.               |
| `instance`           | Deployment instance number         | `"001"`  | For multiple deployments                 |

For additional configuration options, review the variables in `variables.tf`.

## Prerequisites

- Azure subscription with Owner or Contributor access
- Azure CLI installed (version 2.30.0 or later)
- Terraform installed (version 1.9.8 or later)
- Git installed
- Sufficient quota for multiple VMs in your target region

## Deployment Instructions

### 1. Prepare Configuration

Create a `terraform.tfvars` file with the following required variables:

```hcl
# Required variables
environment     = "dev"                 # Environment type (dev, test, prod)
resource_prefix = "myprefix"            # Short unique prefix for resource naming
location        = "eastus2"             # Azure region location

# Optional (recommended) variables
instance        = "001"                 # Deployment instance number
host_machine_count = 3                  # Number of VMs for the cluster (minimum 3 recommended for HA)
```

### 2. Initialize Terraform

```bash
# Set Azure subscription context
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Initialize Terraform
terraform init
```

### 3. Deploy Resources

```bash
# Apply the Terraform configuration
terraform apply
```

### 4. Access Deployed Resources

After successful deployment:

1. **Access the Kubernetes cluster** (in one prompt):

   ```bash
   az connectedk8s proxy -n <cluster-name> -g <resource-group>
   ```

2. **View AIO resources** (in a separate prompt):

   ```bash
   kubectl get pods -n azure-iot-operations
   ```

3. **Check cluster nodes status**:

   ```bash
   kubectl get nodes -o wide
   ```

## Post-Deployment Tasks

### Verifying High Availability Setup

Check that your workloads are properly distributed across nodes:

```bash
kubectl get pods -A -o wide
```

### Connecting Additional Edge Devices

Use the generated connection string output to connect edge devices:

```bash
terraform output edge_device_connection_string
```

### Monitoring the Deployment

View deployed resources and their status:

```bash
terraform output -json | jq
```

## Cleanup

When finished with your deployment:

```bash
terraform destroy -var-file=terraform.tfvars
```

## Deployment Troubleshooting

Deployment duration for multi-node clusters will be longer than single-node deployments. Be patient during the provisioning process.

### Common Issues

- **Node joining failures**: If worker nodes fail to join the cluster, verify networking connectivity between VMs
- **Terraform timeouts**: Multi-node deployments may require increased timeouts for resource creation
- **Arc-enabled Kubernetes issues**: Similar to single-node deployments, Arc connection issues may occur

The following messages are considered normal during deployment:

```txt
module.vm_host.azurerm_linux_virtual_machine.main[*]: Creating...
module.cncf_cluster_install.null_resource.k3s_setup: Still creating... [7m6s elapsed]
module.iot_ops_install.module.iot_ops_instance.azurerm_arc_kubernetes_cluster_extension.iot_operations: Still creating... [3m20s elapsed]
```

For recovery from failed deployments, you may:

- List terraform resources with the command `terraform state list` and remove specific resources using `terraform state rm <resource-id>`
- Manually remove the resource group with all its included resources
