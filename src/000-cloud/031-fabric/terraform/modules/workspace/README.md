<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Terraform IaC

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0.0 |
| fabric | 1.3.0 |

## Providers

| Name | Version |
|------|---------|
| fabric | 1.3.0 |

## Resources

| Name | Type |
|------|------|
| [fabric_workspace.this](https://registry.terraform.io/providers/microsoft/fabric/1.3.0/docs/resources/workspace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| capacity\_id | The ID of the premium capacity to assign to the workspace (Run ./scripts/select-fabric-capacity.sh to choose one) | `string` | n/a | yes |
| workspace\_description | The description of the workspace | `string` | n/a | yes |
| workspace\_display\_name | The display name of the workspace | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| workspace | The Fabric workspace. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
