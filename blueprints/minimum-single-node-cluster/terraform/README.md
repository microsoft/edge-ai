<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Terraform IaC - Minimum Single Node Cluster

## Overview

This blueprint provides the minimal set of resources required to deploy Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster. It includes only the essential components and minimizes resource usage.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.23.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| cloud\_resource\_group | ../../../src/000-cloud/000-resource-group/terraform | n/a |
| cloud\_security\_identity | ../../../src/000-cloud/010-security-identity/terraform | n/a |
| cloud\_data | ../../../src/000-cloud/030-data/terraform | n/a |
| cloud\_vm\_host | ../../../src/000-cloud/050-vm-host/terraform | n/a |
| edge\_cncf\_cluster | ../../../src/100-edge/100-cncf-cluster/terraform | n/a |
| edge\_iot\_ops | ../../../src/100-edge/110-iot-ops/terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| custom\_locations\_oid | The object id of the Custom Locations Entra ID application for your tenant. If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions. ```sh az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv``` | `string` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| should\_create\_anonymous\_broker\_listener | Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments) | `string` | `false` | no |
| should\_get\_custom\_locations\_oid | Whether to get Custom Locations Object ID using Terraform's azuread provider. (Otherwise, provided by 'custom\_locations\_oid' or `az connectedk8s enable-features` for custom-locations on cluster setup if not provided.) | `bool` | `true` | no |

## Resource Optimizations

This blueprint minimizes resource usage compared to the full single node cluster blueprint:

1. **Storage**: Uses Standard tier storage with LRS (Locally Redundant Storage) replication
2. **Virtual Machine**: Uses a Standard_D4s_v3 VM size, which is the minimum recommended for running Azure IoT Operations
3. **Single Node**: Deploys only a single VM host node
4. **Optional Components**: Disables the OPC UA simulator and other non-essential components

## Deployment

To deploy this blueprint, you need to:

1. Create a `terraform.tfvars` file with the required variables
2. Run `terraform init` to initialize the terraform modules
3. Run `terraform plan` to preview the resources that will be created
4. Run `terraform apply` to deploy the resources

Example `terraform.tfvars` file:

```hcl
# Required variables
environment     = "dev"
resource_prefix = "minimumedge"
location        = "eastus2"
instance        = "001"

# Optional settings
should_create_anonymous_broker_listener = true
should_get_custom_locations_oid         = true
```

## Notes

This blueprint is designed for development and testing purposes. For production deployments, consider using the full-single-node-cluster blueprint with appropriate resource sizing and redundancy options.
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
