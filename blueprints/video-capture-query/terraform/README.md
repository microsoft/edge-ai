<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Video Capture Query Blueprint

Deploys cloud infrastructure for continuous video recording and time-based query capabilities.
This blueprint orchestrates storage account, lifecycle policies, and Azure Functions for the Video Query API.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azurerm | >= 4.51.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.51.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_role_assignment.video_query_storage_blob_data_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| cloud\_data | ../../../src/000-cloud/030-data/terraform | n/a |
| cloud\_messaging | ../../../src/000-cloud/040-messaging/terraform | n/a |
| cloud\_resource\_group | ../../../src/000-cloud/000-resource-group/terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| recording\_mode | Video recording mode: continuous, hybrid, or ring\_buffer\_only | `string` | `"continuous"` | no |
| segment\_duration\_seconds | Duration of each video segment in seconds | `number` | `300` | no |
| tags | Tags to apply to all resources in this blueprint | `map(string)` | `{}` | no |
| video\_retention\_days | Number of days to retain video files before deletion | `number` | `365` | no |

## Outputs

| Name | Description |
|------|-------------|
| function\_app | Azure Function App resource for Video Query API. |
| function\_app\_url | Azure Function App default hostname URL. |
| function\_storage\_account | Storage Account used by the Function App for internal state. |
| resource\_group | Resource group for all video capture query resources. |
| storage\_account | Storage Account resource for video recordings. |
| storage\_account\_connection\_string | Storage Account primary connection string for edge device configuration. |
| video\_recording\_config | Video recording configuration parameters for edge deployment. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
