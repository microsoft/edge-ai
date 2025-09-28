<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure IoT Operations Dataflow sample

Provisions the ARM based data flow endpoint and data flow, requires Asset

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | >= 2.3.0 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.dataflow_endpoint_to_eventhub](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.dataflow_to_eventhub](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_dataflow\_profile | The AIO dataflow profile | ```object({ id = string })``` | n/a | yes |
| aio\_instance | The Azure IoT Operations instance | ```object({ id = string })``` | n/a | yes |
| aio\_uami\_client\_id | Client ID of the User Assigned Managed Identity for the Azure IoT Operations instance | `string` | n/a | yes |
| aio\_uami\_tenant\_id | Tenant ID of the User Assigned Managed Identity for the Azure IoT Operations instance | `string` | n/a | yes |
| asset\_name | The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud. | `string` | n/a | yes |
| custom\_location\_id | The resource ID of the Custom Location | `string` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| eventhub | Values for the existing Event Hub namespace and Event Hub. | ```object({ namespace_name = string eventhub_name = string })``` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
