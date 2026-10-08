<!-- BEGIN_TF_DOCS -->
# Azure Key Vault for Secret Sync Extension

Create or use and existing a Key Vault for Secret Sync Extension

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.12.0, < 2.0 |
| azapi     | >= 2.3.0         |
| time      | >= 0.13.0        |

## Providers

| Name      | Version   |
|-----------|-----------|
| azapi     | >= 2.3.0  |
| azurerm   | n/a       |
| terraform | n/a       |
| time      | >= 0.13.0 |

## Resources

| Name                                                                                                                                                                             | Type        |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [azapi_resource.network_security_perimeter_association](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource)                                      | resource    |
| [azurerm_key_vault.new](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault)                                                               | resource    |
| [azurerm_monitor_diagnostic_setting.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting)                       | resource    |
| [azurerm_private_dns_a_record.a_record](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record)                                    | resource    |
| [azurerm_private_dns_zone.dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone)                                            | resource    |
| [azurerm_private_dns_zone_virtual_network_link.vnet_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource    |
| [azurerm_private_endpoint.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint)                                           | resource    |
| [azurerm_role_assignment.user_key_vault_secrets_officer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment)                        | resource    |
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                                                                   | resource    |
| [time_sleep.network_security_perimeter_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep)                                          | resource    |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config)                                                | data source |

## Inputs

| Name                                               | Description                                                                                                               | Type                            | Default | Required |
|----------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------|---------------------------------|---------|:--------:|
| environment                                        | Environment for all resources in this module: dev, test, or prod                                                          | `string`                        | n/a     |   yes    |
| key\_vault\_admin\_principal\_id                   | The Principal ID or Object ID for the admin that will have access to update secrets on the Key Vault.                     | `string`                        | n/a     |   yes    |
| key\_vault\_name                                   | The name of the Key Vault to store secrets. If not provided, defaults to 'kv-{resource\_prefix}-{environment}-{instance}' | `string`                        | n/a     |   yes    |
| location                                           | Azure region where all resources will be deployed                                                                         | `string`                        | n/a     |   yes    |
| log\_analytics\_workspace\_id                      | The ID of the Log Analytics workspace for diagnostic settings                                                             | `string`                        | n/a     |   yes    |
| network\_security\_perimeter\_id                   | Resource ID of the Network Security Perimeter to associate with the Key Vault                                             | `string`                        | n/a     |   yes    |
| network\_security\_perimeter\_profile\_id          | Resource ID of the Network Security Perimeter profile applied to the Key Vault                                            | `string`                        | n/a     |   yes    |
| network\_security\_perimeter\_propagation\_delay   | Duration to wait after enforcing the Network Security Perimeter association before allowing data-plane operations         | `string`                        | n/a     |   yes    |
| network\_security\_perimeter\_propagation\_trigger | Value that changes when Network Security Perimeter access rules change                                                    | `string`                        | n/a     |   yes    |
| private\_endpoint\_subnet\_id                      | The ID of the subnet where the private endpoint will be created                                                           | `string`                        | n/a     |   yes    |
| resource\_group                                    | Resource group object containing name and id where resources will be deployed                                             | ```object({ name = string })``` | n/a     |   yes    |
| resource\_prefix                                   | Prefix for all resources in this module                                                                                   | `string`                        | n/a     |   yes    |
| should\_add\_key\_vault\_role\_assignment          | Whether to add role assignment to the Key Vault                                                                           | `bool`                          | n/a     |   yes    |
| should\_create\_private\_endpoint                  | Whether to create a private endpoint for the Key Vault                                                                    | `bool`                          | n/a     |   yes    |
| should\_enable\_diagnostic\_settings               | Whether to enable diagnostic settings for the Key Vault                                                                   | `bool`                          | n/a     |   yes    |
| should\_enable\_public\_network\_access            | Whether to enable public network access for the Key Vault                                                                 | `bool`                          | n/a     |   yes    |
| should\_enable\_purge\_protection                  | Whether to enable purge protection for the Key Vault                                                                      | `bool`                          | n/a     |   yes    |
| should\_use\_network\_security\_perimeter          | Whether to associate the Key Vault with a Network Security Perimeter                                                      | `bool`                          | n/a     |   yes    |
| virtual\_network\_id                               | The ID of the virtual network to link to the private DNS zone                                                             | `string`                        | n/a     |   yes    |
| instance                                           | Instance identifier for naming resources: 001, 002, etc                                                                   | `string`                        | `"001"` |    no    |

## Outputs

| Name               | Description                                  |
|--------------------|----------------------------------------------|
| key\_vault         | n/a                                          |
| private\_dns\_zone | The private DNS zone for Key Vault.          |
| private\_endpoint  | The private endpoint resource for Key Vault. |
<!-- END_TF_DOCS -->
