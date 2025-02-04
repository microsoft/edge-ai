<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Event Grid

Create a new Event Grid namespace and namespace topic and assign the AIO instance UAMI the EventGrid TopicSpaces Publisher role.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | n/a |
| azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.event_grid_namespace_topic_space](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_eventgrid_namespace.aio_eg_ns](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventgrid_namespace) | resource |
| [azurerm_role_assignment.data_sender](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_uami\_principal\_id | Principal ID of the User Assigned Managed Identity for the Azure IoT Operations instance | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_group\_name | Name of the pre-existing resource group in which to create resources | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| capacity | Specifies the Capacity / Throughput Units for a Standard SKU namespace. Valid values range from 1 - 40. | `number` | `1` | no |
| event\_grid\_max\_client\_sessions\_per\_auth\_name | Specifies the maximum number of client sessions per authentication name. Valid values are from 3 to 100. This parameter should be greater than the number of dataflows | `number` | `8` | no |
| topic\_name | Topic template name to create in the Event Grid namespace | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| event\_grid | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
