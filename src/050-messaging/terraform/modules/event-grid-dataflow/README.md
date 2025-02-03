<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure IoT Operations Dataflow Event Grid sample

Provisions the ARM based data flow endpoint and data flow for Event Grid, requires Asset

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | 2.2.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | 2.2.0 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.dataflow_endpoint_to_event_grid](https://registry.terraform.io/providers/Azure/azapi/2.2.0/docs/resources/resource) | resource |
| [azapi_resource.dataflow_to_event_grid](https://registry.terraform.io/providers/Azure/azapi/2.2.0/docs/resources/resource) | resource |
| [azapi_resource.dataflow_profile](https://registry.terraform.io/providers/Azure/azapi/2.2.0/docs/data-sources/resource) | data source |
| [azapi_resource.instance](https://registry.terraform.io/providers/Azure/azapi/2.2.0/docs/data-sources/resource) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_instance\_name | The name of the Azure IoT Operations instance | `string` | n/a | yes |
| aio\_uami\_client\_id | Client ID of the User Assigned Managed Identity for the Azure IoT Operations instance | `string` | n/a | yes |
| aio\_uami\_tenant\_id | Tenant ID of the User Assigned Managed Identity for the Azure IoT Operations instance | `string` | n/a | yes |
| asset\_name | The name of the Event Hub namespace | `string` | n/a | yes |
| custom\_location\_id | The id of the custom location to deploy Azure IoT Operations to | `string` | n/a | yes |
| event\_grid | Values for the existing Event Grid | ```object({ topic_name = string endpoint = string })``` | n/a | yes |
| resource\_group\_id | The id of the pre-existing resource group in which to create resources | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
