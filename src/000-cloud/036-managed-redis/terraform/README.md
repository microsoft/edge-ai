<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Managed Redis Component

Provisions Azure Managed Redis cache with optional private endpoint networking.
Supports Microsoft Entra ID authentication and customer-managed key encryption.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.51.0 |

## Providers

| Name | Version |
|------|---------|
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| managed\_redis | ./modules/managed-redis | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_group | Resource group object containing name and id | ```object({ id = string name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| access\_keys\_authentication\_enabled | Whether to enable access key authentication. Set to false for Entra ID only (recommended for production) | `bool` | `false` | no |
| clustering\_policy | Redis clustering policy. Options: OSSCluster (default, Redis OSS), EnterpriseCluster (Redis Enterprise) | `string` | `"OSSCluster"` | no |
| customer\_managed\_key | Customer-managed key configuration for encryption at rest | ```object({ key_vault_key_id = string user_assigned_identity_id = string })``` | `null` | no |
| managed\_identity | User Assigned Managed Identity for Entra ID authentication. Required when access\_keys\_authentication\_enabled is false | ```object({ id = string })``` | `null` | no |
| private\_endpoint\_subnet | Subnet for private endpoint deployment. Required when should\_enable\_private\_endpoint is true | ```object({ id = string })``` | `null` | no |
| should\_create\_private\_dns\_zone | Whether to create a new private DNS zone. Set to false if using existing zone | `bool` | `true` | no |
| should\_deploy\_redis | Whether to deploy Azure Managed Redis cache | `bool` | `true` | no |
| should\_enable\_high\_availability | Whether to enable high availability mode. Recommended for production, can be disabled for dev/test cost savings | `bool` | `true` | no |
| should\_enable\_private\_endpoint | Whether to create a private endpoint for the Redis cache | `bool` | `false` | no |
| sku\_name | Azure Managed Redis SKU name. Format: {Family}\_{Size} where Family is Balanced, Memory, Compute, or Flash | `string` | `"Balanced_B10"` | no |
| virtual\_network | Virtual network for private DNS zone linking. Required when should\_create\_private\_dns\_zone is true | ```object({ id = string })``` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| connection\_info | Redis connection information. |
| defer | Deferred output for dependency management. |
| managed\_redis | Azure Managed Redis cache details. |
| private\_endpoint | Private endpoint details when enabled. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
