<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure DevOps Infrastructure Module

Creates or uses existing Azure resources for Azure DevOps integration:

- Resource Group
- Virtual Network with subnets for Key Vault, ACR, and DevOps agent pool
- Storage Account
- Key Vault with private endpoint
- Container Registry with private endpoint
- DevOps Managed Pool
- User Assigned Managed Identity with appropriate role assignments

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.2.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.8.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| acr | ./modules/container-registry | n/a |
| identity | ./modules/identity | n/a |
| key\_vault | ./modules/key-vault | n/a |
| managed\_pool | ./modules/devops-infra-pool | n/a |
| network | ./modules/network | n/a |
| storage\_account | ./modules/storage-account | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod. | `string` | n/a | yes |
| location | Location for all resources in this module. | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module. | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc. | `string` | `"001"` | no |
| resource\_group\_name | Name of the resource group to create or use. | `string` | `null` | no |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
