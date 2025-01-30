<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Messaging

Sets up messaging infrastructure and includes deploying a sample
Azure IoT Operations Dataflow to send and receive data from edge to cloud.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.1.0 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | >= 2.1.0 |
| azurerm | >= 4.8.0 |
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azapi_resource.custom_locations](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) | data source |
| [azurerm_resource_group.aio_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_user_assigned_identity.aio_uami](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/user_assigned_identity) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| event\_hubs | ./modules/event-hubs | n/a |
| sample\_event\_hub\_dataflow | ./modules/event-hub-dataflow | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| aio\_uami\_name | The name of the User Assigned Managed Identity for the Azure IoT Operations instance | `string` | `null` | no |
| asset\_name | The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud. | `string` | `"oven"` | no |
| connected\_cluster\_name | The name of the Azure Arc connected cluster resource for Azure IoT Operations. (Otherwise, '{var.resource\_prefix}-arc') | `string` | `null` | no |
| custom\_locations\_name | The name of the Custom Locations resource used by Azure IoT Operations. (Otherwise, '{var.connected\_cluster\_name}-cl') | `string` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| iot\_ops\_instance\_name | The name of the Azure IoT Operations Instance resource. (Otherwise, '{var.connected\_cluster\_name}-ops-instance') | `string` | `null` | no |
| resource\_group\_name | The name for the resource group. (Otherwise, 'rg-{var.resource\_prefix}-{var.environment}-{var.instance}') | `string` | `null` | no |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
