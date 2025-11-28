<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Fabric RTI Minimal Blueprint

This blueprint deploys only the essential Fabric RTI components (EventStream with CustomEndpoint → Eventhouse)
and edge messaging on top of existing Azure IoT Operations infrastructure, using data sources to reference
already deployed resources.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.0.1 |
| azurerm | >= 4.51.0 |
| fabric | 1.3.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | >= 2.0.1 |
| azurerm | >= 4.51.0 |
| fabric | 1.3.0 |
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azapi_resource.aio_instance](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource) | data source |
| [azapi_resource.custom_location](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource) | data source |
| [azapi_resource.dataflow_profile](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource) | data source |
| [azurerm_resource_group.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_user_assigned_identity.aio](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/user_assigned_identity) | data source |
| [fabric_eventhouse.existing](https://registry.terraform.io/providers/microsoft/fabric/1.3.0/docs/data-sources/eventhouse) | data source |
| [fabric_workspace.existing](https://registry.terraform.io/providers/microsoft/fabric/1.3.0/docs/data-sources/workspace) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| cloud\_fabric | ../../../src/000-cloud/031-fabric/terraform | n/a |
| edge\_messaging | ../../../src/100-edge/130-messaging/terraform | n/a |
| fabric\_rti | ../../../src/000-cloud/032-fabric-rti/terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| aio\_identity\_name | Name of the existing AIO user-assigned managed identity. Otherwise, 'id-{resource\_prefix}-{environment}-aio-{instance}'. | `string` | `null` | no |
| aio\_instance\_name | Name of the existing AIO instance. Otherwise, 'arck-{resource\_prefix}-{environment}-{instance}-ops-instance'. | `string` | `null` | no |
| custom\_location\_name | Name of the existing custom location. Otherwise, 'arck-{resource\_prefix}-{environment}-{instance}-cl'. | `string` | `null` | no |
| eventhouse\_kql\_database\_name | Name of the Eventhouse KQL Database. (default, Eventhouse name) | `string` | `null` | no |
| eventstream\_table\_name | Name of the Eventhouse table for data ingestion. | `string` | `null` | no |
| fabric\_eventhouse\_name | The name of the Microsoft Fabric eventhouse. Otherwise, 'evh-{resource\_prefix}-{environment}-{instance}' | `string` | `null` | no |
| fabric\_workspace\_name | The name of the Microsoft Fabric workspace. Otherwise, 'ws-{resource\_prefix}-{environment}-{instance}' | `string` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| resource\_group\_name | Name of the resource group | `string` | `null` | no |
| should\_create\_eventgrid\_dataflows | Whether to create EventGrid dataflows in the edge messaging component | `bool` | `false` | no |
| should\_create\_eventhub\_dataflows | Whether to create EventHub dataflows in the edge messaging component | `bool` | `false` | no |
| should\_create\_fabric\_eventhouse | Whether to create a Microsoft Fabric Eventhouse for real-time intelligence scenarios. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| aio\_custom\_location | The existing custom location for Azure IoT Operations. |
| aio\_instance | The existing Azure IoT Operations instance. |
| eventstream\_dag\_configuration | The DAG configuration used for EventStream creation. |
| fabric\_eventhouse | The existing Microsoft Fabric Eventhouse for real-time analytics. |
| fabric\_eventstream | The Microsoft Fabric EventStream with custom endpoint for AIO integration. |
| fabric\_rti\_custom\_endpoint\_source\_connections | The Fabric RTI connection details. |
| fabric\_rti\_dataflow | The Fabric RTI dataflow endpoint for data ingestion. |
| fabric\_workspace | The existing Microsoft Fabric workspace for RTI analytics. |
| resource\_group | The existing resource group containing all resources. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
