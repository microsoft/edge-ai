<!-- BEGIN_TF_DOCS -->
# Terraform IaC

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.12.0, < 2.0 |
| azurerm   | >= 4.51.0        |

## Modules

| Name | Source          | Version |
|------|-----------------|---------|
| ci   | ../../terraform | n/a     |

## Inputs

| Name                           | Description                                                                                                                                                                                  | Type     | Default | Required |
|--------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|---------|:--------:|
| environment                    | Environment for all resources in this module: dev, test, or prod                                                                                                                             | `string` | n/a     |   yes    |
| location                       | Azure region where all resources will be deployed                                                                                                                                            | `string` | n/a     |   yes    |
| resource\_prefix               | Prefix for all resources in this module                                                                                                                                                      | `string` | n/a     |   yes    |
| instance                       | Instance identifier for naming resources: 001, 002, etc                                                                                                                                      | `string` | `"001"` |    no    |
| resource\_group\_name          | Name of the resource group                                                                                                                                                                   | `string` | `null`  |    no    |
| use\_existing\_resource\_group | Whether to use an existing resource group instead of creating a new one. When true, the component will look up a resource group with the specified or generated name instead of creating it. | `bool`   | `false` |    no    |
<!-- END_TF_DOCS -->
