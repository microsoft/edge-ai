<!-- BEGIN_TF_DOCS -->
# Terraform IaC

## Requirements

| Name      | Version           |
|-----------|-------------------|
| terraform | >= 1.9.8, < 2.0.0 |
| fabric    | 1.3.0             |

## Providers

| Name   | Version |
|--------|---------|
| fabric | 1.3.0   |

## Resources

| Name                                                                                                             | Type     |
|------------------------------------------------------------------------------------------------------------------|----------|
| [fabric_lakehouse.this](https://registry.terraform.io/providers/microsoft/fabric/1.3.0/docs/resources/lakehouse) | resource |

## Inputs

| Name                     | Description                                                 | Type     | Default | Required |
|--------------------------|-------------------------------------------------------------|----------|---------|:--------:|
| lakehouse\_description   | The description of the Microsoft Fabric lakehouse           | `string` | n/a     |   yes    |
| lakehouse\_display\_name | The display name of the lakehouse                           | `string` | n/a     |   yes    |
| workspace\_id            | The ID of the workspace where the lakehouse will be created | `string` | n/a     |   yes    |

## Outputs

| Name            | Description                       |
|-----------------|-----------------------------------|
| lakehouse\_id   | The ID of the created lakehouse   |
| lakehouse\_name | The name of the created lakehouse |
<!-- END_TF_DOCS -->
