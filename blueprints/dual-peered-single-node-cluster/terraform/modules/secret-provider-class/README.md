<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Secret Provider Class Module

Creates Azure Key Vault Secret Provider Classes for Azure IoT Operations
when certificate generation is disabled. This module provisions the
Microsoft.SecretSyncController/azureKeyVaultSecretProviderClasses
resources for both clusters to enable secret synchronization from Key Vault.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | >= 2.3.0 |
| azurerm | >= 4.8.0 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.cluster_a_secret_provider_class](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.cluster_a_secret_sync](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.cluster_b_secret_provider_class](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.cluster_b_secret_sync](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_a\_custom\_location\_id | The custom location ID for Cluster A. | `string` | n/a | yes |
| cluster\_a\_key\_vault | The Key Vault for Cluster A. | ```object({ name = string })``` | n/a | yes |
| cluster\_a\_location | The Azure location for Cluster A resources. | `string` | n/a | yes |
| cluster\_a\_name | The name identifier for Cluster A. | `string` | n/a | yes |
| cluster\_a\_resource\_group | The resource group for Cluster A. | ```object({ id = string })``` | n/a | yes |
| cluster\_a\_secret\_sync\_identity | The secret sync identity for Cluster A. | ```object({ client_id = string })``` | n/a | yes |
| cluster\_b\_custom\_location\_id | The custom location ID for Cluster B. | `string` | n/a | yes |
| cluster\_b\_key\_vault | The Key Vault for Cluster B. | ```object({ name = string })``` | n/a | yes |
| cluster\_b\_location | The Azure location for Cluster B resources. | `string` | n/a | yes |
| cluster\_b\_name | The name identifier for Cluster B. | `string` | n/a | yes |
| cluster\_b\_resource\_group | The resource group for Cluster B. | ```object({ id = string })``` | n/a | yes |
| cluster\_b\_secret\_sync\_identity | The secret sync identity for Cluster B. | ```object({ client_id = string })``` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cluster\_a\_secret\_provider\_class | The Secret Provider Class resource for Cluster A. |
| cluster\_b\_secret\_provider\_class | The Secret Provider Class resource for Cluster B. |
| secret\_sync\_dependency | Dependency marker for secret synchronization setup completion. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
