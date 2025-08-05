<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Terraform IaC

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.8.0 |
| fabric | 1.3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| cloud\_fabric | ../../../src/000-cloud/031-fabric/terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod. | `string` | n/a | yes |
| location | Location for all resources in this module. | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module. | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| resource\_group | n/a | ```object({ name = string })``` | `null` | no |
| should\_create\_fabric\_capacity | Whether to create a new Fabric capacity or use an existing one. | `bool` | `false` | no |
| should\_create\_fabric\_eventhouse | Whether to create a Microsoft Fabric Eventhouse for real-time intelligence scenarios. | `bool` | `false` | no |
| should\_create\_fabric\_lakehouse | Whether to create a Microsoft Fabric lakehouse. | `bool` | `false` | no |
| should\_create\_fabric\_workspace | Whether to create a new Microsoft Fabric workspace or use an existing one. | `bool` | `false` | no |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
