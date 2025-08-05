<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Cloud Fabric

Contains all the resources needed for Fabric based resources.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0.0 |
| azurerm | >= 4.23.0 |
| fabric | 1.3.0 |

## Providers

| Name | Version |
|------|---------|
| fabric | 1.3.0 |

## Resources

| Name | Type |
|------|------|
| [fabric_capacity.existing](https://registry.terraform.io/providers/microsoft/fabric/1.3.0/docs/data-sources/capacity) | data source |
| [fabric_workspace.existing](https://registry.terraform.io/providers/microsoft/fabric/1.3.0/docs/data-sources/workspace) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| fabric\_capacity | ./modules/capacity | n/a |
| fabric\_eventhouse | ./modules/eventhouse | n/a |
| fabric\_lakehouse | ./modules/lakehouse | n/a |
| fabric\_workspace | ./modules/workspace | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_group | n/a | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| additional\_kql\_databases | Additional KQL databases to create within the eventhouse. | ```map(object({ display_name = string description = string }))``` | `{}` | no |
| eventhouse\_description | The description of the Microsoft Fabric eventhouse. | `string` | `"Eventhouse for real-time analytics of Edge device data"` | no |
| fabric\_capacity\_admins | List of AAD object IDs for Fabric capacity administrators. | `list(string)` | `[]` | no |
| fabric\_capacity\_name | The name of the Microsoft Fabric capacity. Otherwise, 'cap-{resource\_prefix}-{environment}-{instance}'. | `string` | `null` | no |
| fabric\_capacity\_sku | The SKU name for the Fabric capacity. | `string` | `"F2"` | no |
| fabric\_eventhouse\_name | The name of the Microsoft Fabric eventhouse. Otherwise, 'evh-{resource\_prefix}-{environment}-{instance}'. | `string` | `null` | no |
| fabric\_lakehouse\_name | The name of the Microsoft Fabric lakehouse. Otherwise, 'lh-{resource\_prefix}-{environment}-{instance}'. | `string` | `null` | no |
| fabric\_workspace\_name | The name of the Microsoft Fabric workspace. Otherwise, 'ws-{resource\_prefix}-{environment}-{instance}'. | `string` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| lakehouse\_description | The description of the Microsoft Fabric lakehouse. | `string` | `"Lakehouse for storing and analyzing data from Edge devices"` | no |
| should\_create\_fabric\_capacity | Whether to create a new Fabric capacity or use an existing one. | `bool` | `false` | no |
| should\_create\_fabric\_eventhouse | Whether to create a Microsoft Fabric Eventhouse for real-time intelligence scenarios. | `bool` | `false` | no |
| should\_create\_fabric\_lakehouse | Whether to create a Microsoft Fabric lakehouse. | `bool` | `false` | no |
| should\_create\_fabric\_workspace | Whether to create a new Microsoft Fabric workspace or use an existing one. | `bool` | `false` | no |
| workspace\_description | The description of the Microsoft Fabric workspace. | `string` | `"Microsoft Fabric workspace for the Edge AI Accelerator solution"` | no |

## Outputs

| Name | Description |
|------|-------------|
| fabric\_capacity | Fabric capacity details. |
| fabric\_eventhouse | Fabric eventhouse details for real-time intelligence. |
| fabric\_lakehouse | Fabric lakehouse details. |
| fabric\_workspace | Fabric workspace details. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
