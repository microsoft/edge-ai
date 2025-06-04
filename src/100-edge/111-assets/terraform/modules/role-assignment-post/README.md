<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# K8 Bridge Role Assignment Module

Assigns Azure Kubernetes Service Arc Contributor Role to K8 Bridge principal.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azuread | >= 2.0.0 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azuread | >= 2.0.0 |
| azurerm | >= 4.8.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_role_assignment.k8_bridge_role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azuread_service_principal.k8_bridge](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| custom\_location\_id | The Resource ID of the custom location. | `string` | n/a | yes |
| k8s\_bridge\_principal\_id | The principal ID of the K8 Bridge that will be assigned the role. If null, will be automatically retrieved using the service principal data source. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| k8s\_bridge\_principal\_id | The principal ID of the K8 Bridge service principal used. |
| role\_assignment\_id | The ID of the role assignment created for the K8 Bridge. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
