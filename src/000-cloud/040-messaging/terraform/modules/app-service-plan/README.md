<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure App Service Plan

Creates an Azure App Service Plan that can be used to host Azure Functions and other web applications.
This module provides the compute infrastructure needed for serverless and web applications.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_service_plan.app_service_plan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| os\_type | Operating system type (only linux supported) | `string` | n/a | yes |
| resource\_group\_name | Name of the resource group | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| sku\_name | The SKU name for the App Service Plan. | `string` | n/a | yes |
| tags | Tags to apply to all resources | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| app\_service\_plan | The App Service Plan resource object. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
