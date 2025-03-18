# Full Single Cluster Blueprint

## Overview

This blueprint provides a complete end-to-end deployment of Azure IoT Operations (AIO) on a single-node, Arc-enabled Kubernetes cluster. It deploys all necessary components from VM creation to AIO installation, resulting in a fully functional edge computing environment that integrates with Azure cloud services.
Please follow general blueprint recommendations from blueprints [README.md](../README.md).

## Architecture

This blueprint deploys:

1. A Linux VM host in Azure
2. A K3s Kubernetes cluster on the VM
3. Azure Arc connection for the cluster
4. Cloud resources required by AIO (Key Vault, Storage, etc.)
5. Azure IoT Operations components (MQTT Broker, Data Processor, etc.)
6. Optional messaging and observability components

The resulting architecture provides a unified edge-to-cloud solution with secure communication, data processing capabilities, and comprehensive monitoring.

## Terraform Structure

This blueprint consists of the following key components:

- **Main Configuration** (`main.tf`): Orchestrates the deployment workflow and module dependencies
- **Variables** (`variables.tf`): Defines input parameters with descriptions and defaults
- **Outputs** (`outputs.tf`): Exposes important resource information for future reference
- **Locals** (`locals.tf`): Contains local variable calculations and transformations
- **Providers** (`providers.tf`): Configures the required Terraform providers

### Key Modules Used

| Module                       | Purpose                              | Source Location                                 |
|------------------------------|--------------------------------------|-------------------------------------------------|
| `vm_host`                    | Creates the VM host for the cluster  | `../../../src/010-vm-host/terraform`            |
| `cncf_cluster_install`       | Deploys K3s Kubernetes cluster       | `../../../src/020-cncf-cluster/terraform`       |
| `iot_ops_cloud_requirements` | Sets up cloud prerequisites for AIO  | `../../../src/030-iot-ops-cloud-reqs/terraform` |
| `iot_ops_install`            | Installs Azure IoT Operations        | `../../../src/040-iot-ops/terraform`            |
| `messaging`                  | Deploys messaging components         | `../../../src/050-messaging/terraform`          |
| `observability`              | Sets up monitoring and observability | `../../../src/070-observability/terraform`      |
| `iot_ops_utilities`          | Installs AIO utility components      | `../../../src/080-iot-ops-utility/terraform`    |
| `onboard_requirements`       | Handles onboarding prerequisites     | `../../../src/005-onboard-reqs/terraform`       |

## Variable Reference

Beyond the basic required variables, this blueprint supports advanced customization:

| Variable            | Description                | Default           | Notes                            |
|---------------------|----------------------------|-------------------|----------------------------------|
| `vm_size`           | VM size for the K3s node   | `Standard_D4s_v3` | Increase for production loads    |
| `k8s_version`       | Kubernetes version         | `1.26.0`          | Tested with 1.25.x-1.27.x        |
| `enable_monitoring` | Deploy monitoring stack    | `true`            | Includes Prometheus/Grafana      |
| `environment`       | Environment type           | Required          | "dev", "test", "prod", etc.      |
| `resource_prefix`   | Prefix for resource naming | Required          | Short unique alphanumeric string |
| `location`          | Azure region location      | Required          | "eastus2", "westus3", etc.       |
| `instance`          | Deployment instance number | `"001"`           | For multiple deployments         |

For additional configuration options, review the variables in `variables.tf`.

## Prerequisites

- Azure subscription with Owner or Contributor access
- Azure CLI installed (version 2.30.0 or later)
- Terraform installed (version 1.9.8 or later)
- Git installed

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
```

### 2. Initialize Terraform

```sh
# Set Azure subscription context
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Initialize Terraform
terraform init
```

### 3. Deploy Resources

```sh
# Apply the Terraform configuration
terraform apply
```

### 4. Access Deployed Resources

After successful deployment:

1. **Access the Kubernetes cluster** (in one prompt):

   ```sh
   az connectedk8s proxy -n <cluster-name> -g <resource-group>
   ```

2. **View AIO resources** (in a separate prompt):

   ```sh
   kubectl get pods -n azure-iot-operations
   ```

3. **Check cluster node status**:

   ```sh
   kubectl get nodes -o wide
   ```

## Post-Deployment Tasks

### Connecting Additional Edge Devices

Use the generated connection string output to connect edge devices:

```sh
terraform output edge_device_connection_string
```

### Monitoring the Deployment

View deployed resources and their status:

```sh
terraform output -json | jq
```

## Cleanup

When finished with your deployment:

```sh
terraform destroy -var-file=terraform.tfvars
```

## Deployment Troubleshooting

Deployment duration is expected to be reasonable, although actual completion times may vary.
Make sure that you don't see the following message for more than ~10 minutes, messages that persist too long indicate a stuck deployment operation:

```text
module.iot_ops_install.module.apply_scripts_post_init[0].terraform_data.apply_scripts: Still creating... [2h17m9s elapsed]
```

After 1-2 hours, it may fail with an error message like this:

```text
│   24:   provisioner "local-exec" {
│
│ Error running command 'source ../../../src/040-iot-ops/terraform/modules/apply-scripts/../../../scripts/init-scripts.sh &&
│ ../../../src/040-iot-ops/terraform/modules/apply-scripts/../../../scripts/apply-otel-collector.sh': exit status 1. Output: Starting 'az
│ connectedk8s proxy'
│ Proxy PID: 79335, PGID: 79335
```

This particular error occurs because the Arc cluster is in an inappropriate state.
In this case, you can perform the following steps to recover and rerun `terraform apply` after that:

- List terraform resources with the command `terraform state list` and remove specific resources using `terraform state rm <resource-id>`
- Manually remove the resource group with all its included resources

The following messages are considered normal during deployment:

```text
module.cncf_cluster_install.azurerm_virtual_machine_extension.linux_setup[0]: Still creating... [7m6s elapsed]
module.iot_ops_install.module.iot_ops_instance.azurerm_arc_kubernetes_cluster_extension.iot_operations: Still creating... [3m20s elapsed]
module.iot_ops_install.module.iot_ops_instance.azapi_resource.instance: Still creating... [2m10s elapsed]
```
