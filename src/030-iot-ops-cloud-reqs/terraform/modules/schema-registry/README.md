<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure IoT Schema Registry Module

Deploys a storage account and schema registry to be used for Azure IoT Operations deployments

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | 2.1.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | 2.1.0 |
| azurerm | n/a |
| random | n/a |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.schema_registry](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) | resource |
| [azurerm_role_assignment.registry_storage_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_storage_account.schema_registry_store](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_container.schema_container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [random_string.name](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_group\_name | Name of the pre-existing resource group in which to create resources | `string` | n/a | yes |
| resource\_prefix | Prefix for the registry and registry namespace created in this module | `string` | n/a | yes |
| storage\_account | Storage account name, tier and replication\_type for the Storage Account to be created. Defaults to a randomly generated name, "Standard" tier and "LRS" replication\_type | ```object({ name = string tier = string replication_type = string })``` | ```{ "name": "", "replication_type": "LRS", "tier": "Standard" }``` | no |

## Outputs

| Name | Description |
|------|-------------|
| registry\_id | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
