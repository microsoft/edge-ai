<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# IoT Ops Utilities Extensions

Creates resources needed for additional utilities and features.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.1.0 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.8.0 |
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| cluster\_extensions\_obs | ./modules/cluster-extensions-obs | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| azure\_monitor\_workspace\_name | The name of the Azure Monitor resource. (Otherwise, 'azmon-{var.resource\_prefix}-{var.environment}-{var.instance}') | `string` | `null` | no |
| connected\_cluster\_name | The name of the Azure Arc connected cluster resource for Azure IoT Operations. (Otherwise, '{var.resource\_prefix}-arc') | `string` | `null` | no |
| grafana\_name | The name of the Azure Managed Grafana resource. (Otherwise, 'amg-{var.resource\_prefix}-{var.environment}-{var.instance}') | `string` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| log\_analytics\_workspace\_name | The name of the Azure Log Analytics resource. (Otherwise, 'log-{var.resource\_prefix}-{var.environment}-{var.instance}') | `string` | `null` | no |
| resource\_group\_name | The name for the resource group. (Otherwise, 'rg-{var.resource\_prefix}-{var.environment}-{var.instance}') | `string` | `null` | no |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
