<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Fabric Blueprint

Deploys Microsoft Fabric capacity, workspace, lakehouse, and eventhouse resources.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.51.0 |
| fabric | 1.3.0 |
| msgraph | >= 0.2.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.51.0 |
| msgraph | >= 0.2.0 |
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [msgraph_resource_action.current_user](https://registry.terraform.io/providers/microsoft/msgraph/latest/docs/resources/resource_action) | resource |
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azurerm_resource_group.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| cloud\_fabric | ../../../src/000-cloud/031-fabric/terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| fabric\_capacity\_admins\_list | List of user principal names (UPNs) or Azure AD object IDs for Fabric capacity administrators. For users, provide UPN (<user@domain.com>) or Object ID. For service principals, provide Application ID or Object ID. If left empty, current user will be added as admin. | `list(string)` | `[]` | no |
| fabric\_workspace\_name | The name of the Microsoft Fabric workspace. Otherwise, 'ws-{resource\_prefix}-{environment}-{instance}' | `string` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| resource\_group\_name | Name of the resource group | `string` | `null` | no |
| should\_create\_fabric\_capacity | Whether to create a new Fabric capacity or use an existing one. | `bool` | `false` | no |
| should\_create\_fabric\_eventhouse | Whether to create a Microsoft Fabric Eventhouse for real-time intelligence scenarios. | `bool` | `false` | no |
| should\_create\_fabric\_lakehouse | Whether to create a Microsoft Fabric lakehouse. | `bool` | `false` | no |
| should\_create\_fabric\_workspace | Whether to create a new Microsoft Fabric workspace or use an existing one. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| fabric\_capacity | The Microsoft Fabric capacity details. |
| fabric\_eventhouse | The Microsoft Fabric eventhouse details. |
| fabric\_lakehouse | The Microsoft Fabric lakehouse details. |
| fabric\_workspace | The Microsoft Fabric workspace details. |
| resource\_group | The resource group for the fabric resources. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
