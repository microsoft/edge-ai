<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Application Insights

Creates an Azure Application Insights instance for monitoring applications,
specifically designed to integrate with Azure Functions and other application services.
This module provides comprehensive monitoring capabilities including telemetry collection,
performance tracking, and diagnostic insights.

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
| [azurerm_application_insights.app_insights](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| application\_type | The type of application being monitored. | `string` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| instance\_suffix | Instance suffix for naming resources: fn, web, api, etc. | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| log\_analytics\_workspace\_id | The ID of the Log Analytics Workspace to associate with Application Insights. | `string` | n/a | yes |
| resource\_group\_name | Name of the resource group | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| retention\_in\_days | The retention period in days for Application Insights data. | `number` | n/a | yes |
| tags | Tags to apply to all resources | `map(string)` | n/a | yes |
| internet\_ingestion\_enabled | Should the Application Insights support ingestion over the Public Internet. | `bool` | `true` | no |
| internet\_query\_enabled | Should the Application Insights support querying over the Public Internet. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| application\_insights | The Application Insights resource object with connection details for monitoring applications. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
