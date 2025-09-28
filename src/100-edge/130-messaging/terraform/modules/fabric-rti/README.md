<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Fabric RTI DataFlow for Edge Messaging

Creates a DataFlow endpoint and dataflow for Microsoft Fabric Real-Time Intelligence integration.
This module enables direct data flow from Azure IoT Operations to Fabric RTI
via Kafka-compatible interface with managed identity authentication.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.0.1 |
| fabric | >= 1.3.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | >= 2.0.1 |
| fabric | >= 1.3.0 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.fabric_rti_dataflow](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.fabric_rti_endpoint](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [fabric_workspace_role_assignment.fabric_workspace_contributor](https://registry.terraform.io/providers/microsoft/fabric/latest/docs/resources/workspace_role_assignment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_dataflow\_profile | The AIO dataflow profile | ```object({ id = string })``` | n/a | yes |
| aio\_identity | Azure IoT Operations managed identity for workspace access | ```object({ id = string principal_id = string tenant_id = string client_id = string })``` | n/a | yes |
| aio\_instance | The Azure IoT Operations instance | ```object({ id = string })``` | n/a | yes |
| asset\_name | The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud. | `string` | n/a | yes |
| custom\_location\_id | The resource ID of the Custom Location | `string` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| fabric\_eventstream\_endpoint | Fabric RTI connection details from EventStream. If provided, creates a Fabric RTI dataflow endpoint. | ```object({ bootstrap_server = string topic_name = string endpoint_type = string })``` | n/a | yes |
| fabric\_workspace | Fabric workspace for RTI resources. Required when fabric\_eventstream\_endpoint is provided. | ```object({ id = string display_name = string })``` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| fabric\_rti\_dataflow | The Fabric RTI dataflow. |
| fabric\_rti\_endpoint | The Fabric RTI dataflow endpoint. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
