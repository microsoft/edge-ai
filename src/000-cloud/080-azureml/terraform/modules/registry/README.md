<!-- BEGIN_TF_DOCS -->
# AzureML Registry Module

Creates an Azure Machine Learning Registry with optional private endpoint support.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| azapi     | >= 1.0.0        |
| azurerm   | >= 4.51.0       |

## Providers

| Name    | Version   |
|---------|-----------|
| azapi   | >= 1.0.0  |
| azurerm | >= 4.51.0 |

## Resources

| Name                                                                                                                                                   | Type     |
|--------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| [azapi_resource.machine_learning_registry](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource)                         | resource |
| [azurerm_private_dns_a_record.registry_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_endpoint.registry_pe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint)               | resource |

## Inputs

| Name                                    | Description                                                             | Type                                        | Default | Required |
|-----------------------------------------|-------------------------------------------------------------------------|---------------------------------------------|---------|:--------:|
| acr                                     | Azure Container Registry from cloud ACR component                       | ```object({ id = string name = string })``` | n/a     |   yes    |
| api\_dns\_zone\_name                    | Name of the privatelink.api.azureml.ms DNS zone (shared with workspace) | `string`                                    | n/a     |   yes    |
| description                             | Description for the AzureML Registry                                    | `string`                                    | n/a     |   yes    |
| environment                             | Environment for all resources in this module: dev, test, or prod        | `string`                                    | n/a     |   yes    |
| instance                                | Instance identifier for naming resources: 001, 002, etc                 | `string`                                    | n/a     |   yes    |
| location                                | Location for all resources in this module                               | `string`                                    | n/a     |   yes    |
| private\_endpoint\_subnet\_id           | Subnet ID for the private endpoint                                      | `string`                                    | n/a     |   yes    |
| resource\_group                         | Resource group object containing name and id                            | ```object({ id = string name = string })``` | n/a     |   yes    |
| resource\_group\_name                   | Name of the resource group                                              | `string`                                    | n/a     |   yes    |
| resource\_prefix                        | Prefix for all resources in this module                                 | `string`                                    | n/a     |   yes    |
| should\_enable\_private\_endpoint       | Whether to create a private endpoint for the registry                   | `bool`                                      | n/a     |   yes    |
| should\_enable\_public\_network\_access | Whether to enable public network access to the registry                 | `bool`                                      | n/a     |   yes    |
| storage\_account                        | Storage account from cloud data component                               | ```object({ id = string name = string })``` | n/a     |   yes    |

## Outputs

| Name                     | Description                                     |
|--------------------------|-------------------------------------------------|
| private\_endpoint        | Registry private endpoint information           |
| registry                 | AzureML Registry resource information           |
| registry\_discovery\_url | Registry discovery URL for client configuration |
<!-- END_TF_DOCS -->
