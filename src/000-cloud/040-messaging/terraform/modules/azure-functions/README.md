<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Functions

Creates an Azure Function App that runs on the provided App Service Plan.
This module creates the Function App with necessary configuration for messaging scenarios.

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
| [azurerm_linux_function_app.function_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_storage_account.function_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_windows_function_app.function_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_function_app) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| app\_service\_plan | The App Service Plan object containing id and os\_type. | ```object({ id = string os_type = string })``` | n/a | yes |
| app\_settings | A map of key-value pairs for App Settings. | `map(string)` | n/a | yes |
| cors\_allowed\_origins | A list of origins that should be allowed to make cross-origin calls. | `list(string)` | n/a | yes |
| cors\_support\_credentials | Whether CORS requests with credentials are allowed. | `bool` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| node\_version | The version of Node.js to use. | `string` | n/a | yes |
| resource\_group\_name | Name of the resource group | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| tags | Tags to apply to all resources | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| function\_app | The Function App resource object. |
| storage\_account | The Storage Account used by the Function App. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
