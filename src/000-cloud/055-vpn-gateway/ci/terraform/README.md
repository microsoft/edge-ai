<!-- BEGIN_TF_DOCS -->
# Terraform IaC

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.12.0, < 2.0 |
| azurerm   | >= 4.51.0        |
| tls       | >= 4.0.6         |

## Providers

| Name      | Version   |
|-----------|-----------|
| azurerm   | >= 4.51.0 |
| terraform | n/a       |

## Resources

| Name                                                                                                                               | Type        |
|------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                     | resource    |
| [azurerm_key_vault.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault)             | data source |
| [azurerm_resource_group.aio](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group)    | data source |
| [azurerm_virtual_network.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Modules

| Name | Source          | Version |
|------|-----------------|---------|
| ci   | ../../terraform | n/a     |

## Inputs

| Name                         | Description                                                                                                                                                                                                                                             | Type                                                                                                                                         | Default | Required |
|------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|---------|:--------:|
| environment                  | Environment for all resources in this module: dev, test, or prod                                                                                                                                                                                        | `string`                                                                                                                                     | n/a     |   yes    |
| location                     | Azure region where all resources will be deployed                                                                                                                                                                                                       | `string`                                                                                                                                     | n/a     |   yes    |
| resource\_prefix             | Prefix for all resources in this module                                                                                                                                                                                                                 | `string`                                                                                                                                     | n/a     |   yes    |
| azure\_ad\_config            | Azure AD configuration for VPN Gateway authentication. tenant\_id is required when should\_use\_azure\_ad\_auth is true. audience defaults to Microsoft-registered app. issuer will default to '<https://sts.windows.net/{tenant_id}/>' when not provided | ```object({ tenant_id = optional(string) audience = optional(string, "c632b3df-fb67-4d84-bdcf-b95ad541b5c8") issuer = optional(string) })``` | `{}`    |    no    |
| instance                     | Instance identifier for naming resources: 001, 002, etc                                                                                                                                                                                                 | `string`                                                                                                                                     | `"001"` |    no    |
| should\_use\_azure\_ad\_auth | Whether to use Azure AD authentication for VPN Gateway. When true, uses Azure AD authentication. When false, uses certificate authentication                                                                                                            | `bool`                                                                                                                                       | `true`  |    no    |
<!-- END_TF_DOCS -->
