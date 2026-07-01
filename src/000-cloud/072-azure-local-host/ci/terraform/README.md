<!-- BEGIN_TF_DOCS -->
# Terraform IaC

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.12.0, < 2.0 |
| azapi     | >= 1.13.0        |
| azurerm   | >= 4.8.0         |

## Providers

| Name      | Version  |
|-----------|----------|
| azurerm   | >= 4.8.0 |
| terraform | n/a      |

## Resources

| Name                                                                                                                           | Type        |
|--------------------------------------------------------------------------------------------------------------------------------|-------------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                 | resource    |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Modules

| Name | Source          | Version |
|------|-----------------|---------|
| ci   | ../../terraform | n/a     |

## Inputs

| Name                                    | Description                                                                        | Type     | Default | Required |
|-----------------------------------------|------------------------------------------------------------------------------------|----------|---------|:--------:|
| custom\_locations\_oid                  | Custom Location resource ID for Azure Local deployment                             | `string` | n/a     |   yes    |
| environment                             | Environment for all resources in this module: dev, test, or prod                   | `string` | n/a     |   yes    |
| location                                | Azure region where all resources will be deployed                                  | `string` | n/a     |   yes    |
| resource\_prefix                        | Prefix for all resources in this module                                            | `string` | n/a     |   yes    |
| instance                                | Instance identifier for naming resources: 001, 002, etc                            | `string` | `"001"` |    no    |
| logical\_network\_name                  | Name of the Azure Local logical network used for cluster infrastructure networking | `string` | `null`  |    no    |
| logical\_network\_resource\_group\_name | Name of the resource group containing the Azure Local logical network              | `string` | `null`  |    no    |
| resource\_group\_name                   | Name of the resource group containing Azure Local resources                        | `string` | `null`  |    no    |
<!-- END_TF_DOCS -->
