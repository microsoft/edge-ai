<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Storage Account for Accelerator

Create a Storage Account for Accelerator

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_storage_account.store](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_container.container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod. | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc. | `string` | n/a | yes |
| resource\_group | Resource group for all resources in this module. | ```object({ name = string location = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module. | `string` | n/a | yes |
| storage\_account | Storage account name, tier and replication\_type for the Storage Account to be created. Defaults to a randomly generated name, "Standard" tier and "LRS" replication\_type. | ```object({ name = string tier = string replication_type = string })``` | ```{ "name": "", "replication_type": "LRS", "tier": "Standard" }``` | no |

## Outputs

| Name | Description |
|------|-------------|
| storage\_account | The Storage Account resource created by this module. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
