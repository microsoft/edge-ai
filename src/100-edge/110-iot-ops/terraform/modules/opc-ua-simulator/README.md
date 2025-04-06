<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure IoT Operations OPC UA Simulator

Deploy and configure the OPC UA Simulator

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | n/a |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.asset](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.asset_endpoint](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| aio\_apply\_scripts\_pre\_instance | ../apply-scripts | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| connected\_cluster\_name | The name of the connected cluster to deploy Azure IoT Operations to | `string` | n/a | yes |
| custom\_location\_id | The resource ID of the Custom Location. | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_group | Name and ID of the pre-existing resource group in which to create resources | ```object({ id = string name = string })``` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| asset\_name | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
