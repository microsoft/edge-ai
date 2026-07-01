<!-- BEGIN_TF_DOCS -->
# Terraform IaC

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.12.0, < 2.0 |
| azurerm   | >= 4.51.0        |
| fabric    | 1.3.0            |

## Providers

| Name      | Version |
|-----------|---------|
| fabric    | 1.3.0   |
| terraform | n/a     |

## Resources

| Name                                                                                                                        | Type        |
|-----------------------------------------------------------------------------------------------------------------------------|-------------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)              | resource    |
| [fabric_eventhouse.eventhouse](https://registry.terraform.io/providers/microsoft/fabric/1.3.0/docs/data-sources/eventhouse) | data source |
| [fabric_workspace.workspace](https://registry.terraform.io/providers/microsoft/fabric/1.3.0/docs/data-sources/workspace)    | data source |

## Modules

| Name | Source          | Version |
|------|-----------------|---------|
| ci   | ../../terraform | n/a     |

## Inputs

| Name                     | Description                                                                                               | Type     | Default | Required |
|--------------------------|-----------------------------------------------------------------------------------------------------------|----------|---------|:--------:|
| environment              | Environment for all resources in this module: dev, test, or prod                                          | `string` | n/a     |   yes    |
| resource\_prefix         | Prefix for all resources in this module                                                                   | `string` | n/a     |   yes    |
| fabric\_eventhouse\_name | The name of the Microsoft Fabric eventhouse. Otherwise, 'evh-{resource\_prefix}-{environment}-{instance}' | `string` | `null`  |    no    |
| fabric\_workspace\_name  | The name of the Microsoft Fabric workspace. Otherwise, 'ws-{resource\_prefix}-{environment}-{instance}'   | `string` | `null`  |    no    |
| instance                 | Instance identifier for naming resources: 001, 002, etc                                                   | `string` | `"001"` |    no    |
<!-- END_TF_DOCS -->
