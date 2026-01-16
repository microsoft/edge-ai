<!-- BEGIN_TF_DOCS -->
# Azure Key Vault Module for DevOps Infrastructure

Creates an Azure Key Vault with private endpoint connectivity:

- Key Vault with RBAC authorization enabled
- Private endpoint for secure network access
- Private DNS A record for name resolution
- Public network access disabled for enhanced security

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name    | Version |
|---------|---------|
| azurerm | n/a     |

## Resources

| Name                                                                                                                                                                             | Type     |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| [azurerm_key_vault.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault)                                                         | resource |
| [azurerm_private_dns_a_record.a_record](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record)                                    | resource |
| [azurerm_private_dns_zone.dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone)                                            | resource |
| [azurerm_private_dns_zone_virtual_network_link.vnet_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.pep](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint)                                                 | resource |

## Inputs

| Name             | Description                                                                   | Type                                              | Default | Required |
|------------------|-------------------------------------------------------------------------------|---------------------------------------------------|---------|:--------:|
| environment      | Environment for all resources in this module: dev, test, or prod              | `string`                                          | n/a     |   yes    |
| instance         | Instance identifier for naming resources: 001, 002, etc                       | `string`                                          | n/a     |   yes    |
| resource\_group  | Resource group object containing name and id where resources will be deployed | ```object({ name = string location = string })``` | n/a     |   yes    |
| resource\_prefix | Prefix for all resources in this module                                       | `string`                                          | n/a     |   yes    |
| snet\_kv         | Subnet for the Key Vault private endpoint.                                    | ```object({ id = string })```                     | n/a     |   yes    |
| tenant\_id       | Tenant Id for the Azure Key Vault.                                            | `string`                                          | n/a     |   yes    |
| vnet             | Virtual Network for Key Vault Private DNS Zone.                               | ```object({ id = string })```                     | n/a     |   yes    |

## Outputs

| Name       | Description                                    |
|------------|------------------------------------------------|
| key\_vault | The Key Vault resource created by this module. |
<!-- END_TF_DOCS -->
