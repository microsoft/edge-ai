<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Cloud Fabric

Contains all the resources needed for Fabric based resources.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0.0 |
| azurerm | >= 4.23.0 |
| fabric | 1.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| fabric\_capacity | ./modules/capacity | n/a |
| fabric\_eventstream | ./modules/eventstream | n/a |
| fabric\_lakehouse | ./modules/lakehouse | n/a |
| fabric\_workspace | ./modules/workspace | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_group | n/a | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| capacity\_id | ID of the Microsoft Fabric capacity to use. Leave empty to use free tier. | `string` | `null` | no |
| eventhub\_endpoint | The endpoint of the Eventhub to connect to the EventStream | `string` | `null` | no |
| eventstream\_description | The description of the Microsoft Fabric event stream | `string` | `"Event Stream for real-time ingestion of Edge device data"` | no |
| existing\_fabric\_workspace\_id | The ID of an existing Microsoft Fabric workspace to use (if should\_create\_fabric\_workspace=false) | `string` | `null` | no |
| fabric\_capacity\_admins | List of AAD object IDs for Fabric capacity administrators | `list(string)` | `[]` | no |
| fabric\_capacity\_id | The ID of an existing Fabric capacity to use (required when create\_fabric\_capacity=false) | `string` | `null` | no |
| fabric\_capacity\_sku | The SKU name for the Fabric capacity | `string` | `"F2"` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| lakehouse\_description | The description of the Microsoft Fabric lakehouse | `string` | `"Lakehouse for storing and analyzing data from Edge devices"` | no |
| should\_create\_fabric\_capacity | Whether to create a new Fabric capacity or use an existing one | `bool` | `false` | no |
| should\_create\_fabric\_eventstream | Whether to create a new Fabric EventStream | `bool` | `false` | no |
| should\_create\_fabric\_lakehouse | Whether to create a Microsoft Fabric lakehouse | `bool` | `false` | no |
| should\_create\_fabric\_workspace | Whether to create a new Microsoft Fabric workspace or use an existing one | `bool` | `false` | no |
| workspace\_description | The description of the Microsoft Fabric workspace | `string` | `"Microsoft Fabric workspace for the Edge AI Accelerator solution"` | no |

## Outputs

| Name | Description |
|------|-------------|
| fabric\_capacity | Fabric capacity details |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
