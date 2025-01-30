<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure IoT Operations Dataflow sample

Provisions the ARM based data flow endpoint and data flow, requires Asset

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | 2.1.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | 2.1.0 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.data_flow](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) | resource |
| [azapi_resource.data_flow_endpoint_to_event_hub](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) | resource |
| [azapi_resource.data_flow_profile](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/data-sources/resource) | data source |
| [azapi_resource.instance](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/data-sources/resource) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_instance\_name | The name of the Azure IoT Operations instance | `string` | n/a | yes |
| aio\_uami\_client\_id | Client ID of the User Assigned Managed Identity for the Azure IoT Operations instance | `string` | n/a | yes |
| aio\_uami\_tenant\_id | Tenant ID of the User Assigned Managed Identity for the Azure IoT Operations instance | `string` | n/a | yes |
| asset\_name | The name of the Event Hub namespace | `string` | n/a | yes |
| custom\_location\_id | The id of the custom location to deploy Azure IoT Operations to | `string` | n/a | yes |
| event\_hub | Values for the existing Event Hub namespace and Event Hub | ```object({ namespace_name = string event_hub_name = string })``` | n/a | yes |
| resource\_group\_id | The id of the pre-existing resource group in which to create resources | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
