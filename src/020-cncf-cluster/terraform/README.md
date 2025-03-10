<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# CNCF Cluster

Sets up and deploys a script to a VM host that will setup the cluster,
Arc connect the cluster, Add cluster admins to the cluster, enable workload identity,
install extensions for cluster connect and custom locations.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.2.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | >= 2.2.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |
| local | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_virtual_machine_extension.linux_setup](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [local_sensitive_file.k3s_device_setup_script](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [azapi_resource.arc_connected_cluster](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) | data source |
| [azuread_service_principal.custom_locations](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_resource\_group | n/a | ```object({ name = string id = optional(string) })``` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| aio\_virtual\_machine | n/a | ```object({ id = string })``` | `null` | no |
| arc\_onboarding\_sp\_client\_id | If using, the Service Principal Client ID with 'Kubernetes Cluster - Azure Arc Onboarding' permissions. (Otherwise, not used and will attempt to use identity of the host) | `string` | `null` | no |
| arc\_onboarding\_sp\_client\_secret | If using, the Service Principal Client Secret to use for automation. (Otherwise, not used and will attempt to use identity of the host) | `string` | `null` | no |
| cluster\_admin\_oid | The Object ID that will be given cluster-admin permissions with the new cluster. (Otherwise, current logged in user if 'should\_add\_current\_user\_cluster\_admin=true') | `string` | `null` | no |
| custom\_locations\_oid | The object id of the Custom Locations Entra ID application for your tenant. If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions. ```sh az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv``` | `string` | `null` | no |
| enable\_arc\_auto\_upgrade | Enable or disable auto-upgrades of Arc agents. (Otherwise, 'false' for 'env=prod' else 'true' for all other envs). | `bool` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| script\_output\_filepath | The location of where to write out the script file. (Otherwise, '{path.root}/out') | `string` | `null` | no |
| should\_add\_current\_user\_cluster\_admin | Gives the current logged in user cluster-admin permissions with the new cluster. | `bool` | `true` | no |
| should\_deploy\_script\_to\_vm | Should deploy the script to an Azure VM assuming that it exists. | `bool` | `true` | no |
| should\_output\_script | Should write out the script to a file. (Specified by 'var.script\_output\_filepath') | `bool` | `false` | no |
| vm\_username | Username used for the host VM that will be given kube-config settings on setup. (Otherwise, 'resource\_prefix' if it exists as a user) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| arc\_connected\_cluster | n/a |
| azure\_arc\_proxy\_command | n/a |
| connected\_cluster\_name | n/a |
| connected\_cluster\_resource\_group\_name | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
