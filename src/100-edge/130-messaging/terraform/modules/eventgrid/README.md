<!-- BEGIN_TF_DOCS -->
# Azure IoT Operations Dataflow Event Grid sample

Provisions the ARM based data flow endpoint and data flow for Event Grid, requires Asset

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| azapi     | >= 2.3.0        |

## Providers

| Name  | Version  |
|-------|----------|
| azapi | >= 2.3.0 |

## Resources

| Name                                                                                                                                | Type     |
|-------------------------------------------------------------------------------------------------------------------------------------|----------|
| [azapi_resource.dataflow_endpoint_to_eventgrid](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.dataflow_to_eventgrid](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource)          | resource |

## Inputs

| Name                   | Description                                                                                              | Type                                                    | Default | Required |
|------------------------|----------------------------------------------------------------------------------------------------------|---------------------------------------------------------|---------|:--------:|
| adr\_namespace         | Azure Device Registry namespace to use with Azure IoT Operations. Otherwise, not configured.             | ```object({ id = string, name = string })```            | n/a     |   yes    |
| aio\_dataflow\_profile | The AIO dataflow profile                                                                                 | ```object({ id = string })```                           | n/a     |   yes    |
| aio\_instance          | The Azure IoT Operations instance                                                                        | ```object({ id = string })```                           | n/a     |   yes    |
| aio\_uami\_client\_id  | Client ID of the User Assigned Managed Identity for the Azure IoT Operations instance                    | `string`                                                | n/a     |   yes    |
| aio\_uami\_tenant\_id  | Tenant ID of the User Assigned Managed Identity for the Azure IoT Operations instance                    | `string`                                                | n/a     |   yes    |
| asset\_name            | The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud. | `string`                                                | n/a     |   yes    |
| custom\_location\_id   | The resource ID of the Custom Location                                                                   | `string`                                                | n/a     |   yes    |
| environment            | Environment for all resources in this module: dev, test, or prod                                         | `string`                                                | n/a     |   yes    |
| eventgrid              | Values for the existing Event Grid                                                                       | ```object({ topic_name = string endpoint = string })``` | n/a     |   yes    |
| instance               | Instance identifier for naming resources: 001, 002, etc                                                  | `string`                                                | n/a     |   yes    |
| resource\_prefix       | Prefix for all resources in this module                                                                  | `string`                                                | n/a     |   yes    |
<!-- END_TF_DOCS -->
