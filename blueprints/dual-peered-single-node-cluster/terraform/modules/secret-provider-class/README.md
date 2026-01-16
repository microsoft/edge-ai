<!-- BEGIN_TF_DOCS -->
# Secret Provider Class Module

Creates Azure Key Vault Secret Provider Classes for Azure IoT Operations
when certificate generation is disabled. This module provisions the
Microsoft.SecretSyncController/azureKeyVaultSecretProviderClasses
resources for both clusters to enable secret synchronization from Key Vault.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| azapi     | >= 2.3.0        |
| azurerm   | >= 4.51.0       |

## Providers

| Name    | Version   |
|---------|-----------|
| azapi   | >= 2.3.0  |
| azurerm | >= 4.51.0 |

## Resources

| Name                                                                                                                                 | Type        |
|--------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [azapi_resource.cluster_a_secret_provider_class](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource    |
| [azapi_resource.cluster_a_secret_sync](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource)           | resource    |
| [azapi_resource.cluster_b_secret_provider_class](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource    |
| [azapi_resource.cluster_b_secret_sync](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource)           | resource    |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription)      | data source |

## Inputs

| Name                                           | Description                                                                                       | Type                                 | Default                 | Required |
|------------------------------------------------|---------------------------------------------------------------------------------------------------|--------------------------------------|-------------------------|:--------:|
| cluster\_a\_custom\_location\_id               | The custom location ID for Cluster A.                                                             | `string`                             | n/a                     |   yes    |
| cluster\_a\_key\_vault                         | The Key Vault for Cluster A.                                                                      | ```object({ name = string })```      | n/a                     |   yes    |
| cluster\_a\_location                           | The Azure location for Cluster A resources.                                                       | `string`                             | n/a                     |   yes    |
| cluster\_a\_name                               | The name identifier for Cluster A                                                                 | `string`                             | n/a                     |   yes    |
| cluster\_a\_resource\_group                    | The resource group for Cluster A.                                                                 | ```object({ id = string })```        | n/a                     |   yes    |
| cluster\_a\_secret\_sync\_identity             | The secret sync identity for Cluster A.                                                           | ```object({ client_id = string })``` | n/a                     |   yes    |
| cluster\_b\_custom\_location\_id               | The custom location ID for Cluster B.                                                             | `string`                             | n/a                     |   yes    |
| cluster\_b\_key\_vault                         | The Key Vault for Cluster B.                                                                      | ```object({ name = string })```      | n/a                     |   yes    |
| cluster\_b\_location                           | The Azure location for Cluster B resources.                                                       | `string`                             | n/a                     |   yes    |
| cluster\_b\_name                               | The name identifier for Cluster B                                                                 | `string`                             | n/a                     |   yes    |
| cluster\_b\_resource\_group                    | The resource group for Cluster B.                                                                 | ```object({ id = string })```        | n/a                     |   yes    |
| cluster\_b\_secret\_sync\_identity             | The secret sync identity for Cluster B.                                                           | ```object({ client_id = string })``` | n/a                     |   yes    |
| enterprise\_broker\_tls\_cert\_secret\_name    | The name of the Kubernetes secret containing the broker tls certificate                           | `string`                             | n/a                     |   yes    |
| site\_client\_secret\_name                     | The name of the Kubernetes secret containing the client certificate and key                       | `string`                             | n/a                     |   yes    |
| cluster\_a\_synced\_certificates\_secret\_name | The name of the Kubernetes secret where certificates will be synced from Key Vault for Cluster A. | `string`                             | `"certificates-sync-a"` |    no    |
| cluster\_b\_synced\_certificates\_secret\_name | The name of the Kubernetes secret where certificates will be synced from Key Vault for Cluster B. | `string`                             | `"certificates-sync-b"` |    no    |

## Outputs

| Name                                           | Description                                                                                        |
|------------------------------------------------|----------------------------------------------------------------------------------------------------|
| cluster\_a\_secret\_provider\_class            | The Secret Provider Class resource for Cluster A.                                                  |
| cluster\_a\_synced\_certificates\_secret\_name | The name of the Kubernetes secret containing the synced certificates from Key Vault for Cluster A. |
| cluster\_b\_secret\_provider\_class            | The Secret Provider Class resource for Cluster B.                                                  |
| cluster\_b\_synced\_certificates\_secret\_name | The name of the Kubernetes secret containing the synced certificates from Key Vault for Cluster B. |
| secret\_sync\_dependency                       | Dependency marker for secret synchronization setup completion.                                     |
<!-- END_TF_DOCS -->
