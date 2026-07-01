<!-- BEGIN_TF_DOCS -->
# Notification CI

Minimal deployment configuration for CI testing of the notification component.

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.12.0, < 2.0 |
| azapi     | >= 2.3.0         |
| azurerm   | >= 4.51.0        |

## Providers

| Name      | Version   |
|-----------|-----------|
| azurerm   | >= 4.51.0 |
| terraform | n/a       |

## Resources

| Name                                                                                                                             | Type        |
|----------------------------------------------------------------------------------------------------------------------------------|-------------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                   | resource    |
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Modules

| Name | Source          | Version |
|------|-----------------|---------|
| ci   | ../../terraform | n/a     |

## Inputs

| Name                 | Description                                                      | Type     | Default                         | Required |
|----------------------|------------------------------------------------------------------|----------|---------------------------------|:--------:|
| environment          | Environment for all resources in this module: dev, test, or prod | `string` | n/a                             |   yes    |
| resource\_prefix     | Prefix for all resources in this module                          | `string` | n/a                             |   yes    |
| eventhub\_name       | Name of the Event Hub to subscribe to for events                 | `string` | `"evh-aio-sample"`              |    no    |
| instance             | Instance identifier for naming resources: 001, 002, etc          | `string` | `"001"`                         |    no    |
| teams\_recipient\_id | Teams chat or channel thread ID for posting event notifications  | `string` | `"19:mock-thread-id@thread.v2"` |    no    |
<!-- END_TF_DOCS -->
