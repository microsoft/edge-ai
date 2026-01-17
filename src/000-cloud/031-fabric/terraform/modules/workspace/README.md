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
| [fabric_workspace.this](https://registry.terraform.io/providers/microsoft/fabric/1.3.0/docs/resources/workspace) | resource |

## Inputs

| Name                     | Description                                       | Type     | Default | Required |
|--------------------------|---------------------------------------------------|----------|---------|:--------:|
| capacity\_id             | The capacity ID for the workspace                 | `string` | n/a     |   yes    |
| workspace\_description   | The description of the Microsoft Fabric workspace | `string` | n/a     |   yes    |
| workspace\_display\_name | The display name of the workspace                 | `string` | n/a     |   yes    |

## Outputs

| Name      | Description           |
|-----------|-----------------------|
| workspace | The Fabric workspace. |
<!-- END_TF_DOCS -->
