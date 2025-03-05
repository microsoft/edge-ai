# Full Single Cluster Blueprint

## Overview

This blueprint provides a complete end-to-end deployment of Azure IoT Operations (AIO) on a single-node, Arc-enabled Kubernetes cluster. It deploys all necessary components from VM creation to AIO installation, resulting in a fully functional edge computing environment that integrates with Azure cloud services.
Please follow general blueprint recommendations from blueprints [README.md](../../README.md), two levels above.

## Architecture

This blueprint deploys:

1. A Linux VM host in Azure
2. A K3s Kubernetes cluster on the VM
3. Azure Arc connection for the cluster
4. Cloud resources required by AIO (Key Vault, Storage, etc.)
5. Azure IoT Operations components (MQTT Broker, Data Processor, etc.)
6. Optional messaging and observability components

The resulting architecture provides a unified edge-to-cloud solution with secure communication, data processing capabilities, and comprehensive monitoring.

## Prerequisites

- Azure subscription with Owner or Contributor access
- Azure CLI installed (version 2.30.0 or later)
- Terraform installed (version 1.0.0 or later)
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

For advanced customization options, review the variables in `variables.tf`.

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

## Deployment troubleshooting

Deployment duration is expected to be reasonable, although actual completion times may vary.
Make sure that you don't see the following message for more than ~10 minutes, messages that persist too long indicate a stuck deployment operation:

   ```txt
   module.iot_ops_install.module.apply_scripts_post_init[0].terraform_data.apply_scripts: Still creating... [2h17m9s elapsed]
   ```

After 1-2 hours, it may fail with an error message like this:

   ```txt
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

   ```txt
   module.cncf_cluster_install.azurerm_virtual_machine_extension.linux_setup[0]: Still creating... [7m6s elapsed]
   module.iot_ops_install.module.iot_ops_instance.azurerm_arc_kubernetes_cluster_extension.iot_operations: Still creating... [3m20s elapsed]
   module.iot_ops_install.module.iot_ops_instance.azapi_resource.instance: Still creating... [2m10s elapsed]
   ```
