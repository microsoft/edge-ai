<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Managed Redis Internal Module

Creates Azure Managed Redis cache with optional private endpoint and DNS zone.
All variables are required - defaults are provided at component level only.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.51.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.51.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_managed_redis.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_redis) | resource |
| [azurerm_private_dns_a_record.redis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_zone.redis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.redis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.redis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access\_keys\_authentication\_enabled | Whether to enable access key authentication | `bool` | n/a | yes |
| clustering\_policy | Redis clustering policy | `string` | n/a | yes |
| customer\_managed\_key | Customer-managed key configuration for encryption at rest | ```object({ key_vault_key_id = string user_assigned_identity_id = string })``` | n/a | yes |
| location | Azure region for resource deployment | `string` | n/a | yes |
| managed\_identity\_id | User-assigned managed identity ID for Entra ID authentication | `string` | n/a | yes |
| name | Name of the Azure Managed Redis cache | `string` | n/a | yes |
| private\_endpoint\_subnet\_id | Subnet ID for private endpoint deployment | `string` | n/a | yes |
| resource\_group\_name | Resource group name | `string` | n/a | yes |
| should\_create\_private\_dns\_zone | Whether to create a new private DNS zone | `bool` | n/a | yes |
| should\_enable\_high\_availability | Whether to enable high availability mode | `bool` | n/a | yes |
| should\_enable\_private\_endpoint | Whether to create a private endpoint | `bool` | n/a | yes |
| sku\_name | Azure Managed Redis SKU name | `string` | n/a | yes |
| virtual\_network\_id | Virtual network ID for private DNS zone linking | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| connection\_info | Redis connection information. |
| managed\_redis | Azure Managed Redis cache details. |
| private\_endpoint | Private endpoint details when enabled. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
