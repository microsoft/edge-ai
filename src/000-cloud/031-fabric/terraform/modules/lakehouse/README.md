<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Terraform IaC

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0.0 |
| fabric | 0.1.0-rc.2 |

## Providers

| Name | Version |
|------|---------|
| fabric | 0.1.0-rc.2 |

## Resources

| Name | Type |
|------|------|
| [fabric_lakehouse.this](https://registry.terraform.io/providers/microsoft/fabric/0.1.0-rc.2/docs/resources/lakehouse) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| lakehouse\_description | The description of the lakehouse | `string` | n/a | yes |
| lakehouse\_display\_name | The display name of the lakehouse | `string` | n/a | yes |
| workspace\_id | The ID of the workspace where the lakehouse will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| lakehouse\_id | The ID of the created lakehouse |
| lakehouse\_name | The name of the created lakehouse |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
