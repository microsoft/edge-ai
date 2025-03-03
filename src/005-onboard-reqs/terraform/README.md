<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Onboard Infrastructure Requirements

Creates the required resources needed for an edge IaC deployment.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.8.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.new](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_resource_group.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| onboard\_identity | ./modules/onboard-identity | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| onboard\_identity\_type | Identity type to use for onboarding the cluster to Azure Arc.  Allowed values:  - uami - sp | `string` | `"uami"` | no |
| resource\_group\_name | The name for the resource group. | `string` | `null` | no |
| should\_create\_onboard\_identity | Should create either a User Assigned Managed Identity or Service Principal to be used with onboarding a cluster to Azure Arc. | `bool` | `true` | no |
| should\_create\_resource\_group | Should create and manage a new Resource Group. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| arc\_onboarding\_sp\_client\_id | The Service Principal Client ID with 'Kubernetes Cluster - Azure Arc Onboarding' permissions. |
| arc\_onboarding\_sp\_client\_secret | The Service Principal Secret used for automation. `jq -r '.arc_onboard_sp_client_secret.value' <<< "$(terraform output -json)"` |
| arc\_onboarding\_user\_assigned\_identity | n/a |
| arc\_onboarding\_user\_managed\_identity\_id | The User Assigned Managed Identity ID with 'Kubernetes Cluster - Azure Arc Onboarding' permissions. |
| arc\_onboarding\_user\_managed\_identity\_name | The User Assigned Managed Identity name with 'Kubernetes Cluster - Azure Arc Onboarding' permissions. |
| resource\_group | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
