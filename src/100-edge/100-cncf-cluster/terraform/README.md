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
| azapi | >= 2.3.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | >= 2.3.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.defer_azuread_user](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.defer_custom_locations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azapi_resource.arc_connected_cluster](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) | data source |
| [azuread_service_principal.custom_locations](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |
| [azuread_user.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/user) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| arc\_agents | ./modules/arc-agents | n/a |
| cluster\_node\_arc\_script\_deployment | ./modules/arc-server-script-deployment | n/a |
| cluster\_node\_script\_deployment | ./modules/vm-script-deployment | n/a |
| cluster\_server\_arc\_script\_deployment | ./modules/arc-server-script-deployment | n/a |
| cluster\_server\_script\_deployment | ./modules/vm-script-deployment | n/a |
| role\_assignments | ./modules/role-assignments | n/a |
| ubuntu\_k3s | ./modules/ubuntu-k3s | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| resource\_group | n/a | ```object({ name = string id = optional(string) })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| should\_get\_custom\_locations\_oid | Whether to get Custom Locations Object ID using Terraform's azuread provider. (Otherwise, provided by 'custom\_locations\_oid' or `az connectedk8s enable-features` for custom-locations on cluster setup if not provided.) | `bool` | n/a | yes |
| arc\_onboarding\_identity | The Principal ID for the identity that will be used for onboarding the cluster to Arc. | ```object({ principal_id = string })``` | `null` | no |
| arc\_onboarding\_principal\_ids | The Principal IDs for a pre-existing identity that will be used for onboarding the cluster to Arc. | `list(string)` | `null` | no |
| arc\_onboarding\_sp | n/a | ```object({ client_id = string object_id = string client_secret = string })``` | `null` | no |
| cluster\_admin\_oid | The Object ID that will be given cluster-admin permissions with the new cluster. (Otherwise, current logged in user Object ID if 'should\_add\_current\_user\_cluster\_admin=true') | `string` | `null` | no |
| cluster\_admin\_upn | The User Principal Name that will be given cluster-admin permissions with the new cluster. (Otherwise, current logged in user UPN if 'should\_add\_current\_user\_cluster\_admin=true') | `string` | `null` | no |
| cluster\_node\_machine | n/a | ```list(object({ id = string location = string }))``` | `null` | no |
| cluster\_server\_host\_machine\_username | Username used for the host machines that will be given kube-config settings on setup. (Otherwise, 'resource\_prefix' if it exists as a user) | `string` | `null` | no |
| cluster\_server\_ip | The IP address for the server for the cluster. (Needed for mult-node cluster) | `string` | `null` | no |
| cluster\_server\_machine | n/a | ```object({ id = string location = string })``` | `null` | no |
| cluster\_server\_token | The token that will be given to the server for the cluster or used by the agent nodes to connect them to the cluster. (ex. <https://docs.k3s.io/cli/token)> | `string` | `null` | no |
| custom\_locations\_oid | The object id of the Custom Locations Entra ID application for your tenant. If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions. ```sh az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv``` | `string` | `null` | no |
| http\_proxy | HTTP proxy URL | `string` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| key\_vault | The Key Vault object containing id, name, and vault\_uri properties. | ```object({ id = string name = string vault_uri = string })``` | `null` | no |
| key\_vault\_script\_secret\_prefix | Optional prefix for the Key Vault script secret name when should\_use\_script\_from\_secrets\_for\_deploy is true. | `string` | `""` | no |
| private\_key\_pem | Private key for onboarding | `string` | `null` | no |
| script\_output\_filepath | The location of where to write out the script file. (Otherwise, '{path.root}/out') | `string` | `null` | no |
| should\_add\_current\_user\_cluster\_admin | Gives the current logged in user cluster-admin permissions with the new cluster. | `bool` | `true` | no |
| should\_assign\_roles | Whether to assign Key Vault roles to identity or service principal. | `bool` | `true` | no |
| should\_deploy\_arc\_agents | Should deploy arc agents using helm charts instead of Azure CLI. | `bool` | `false` | no |
| should\_deploy\_arc\_machines | Should deploy to Arc-connected servers instead of Azure VMs. When true, machine\_id refers to an Arc-connected server ID. | `bool` | `false` | no |
| should\_deploy\_script\_to\_vm | Should deploy the scripts to the provided Azure VMs. | `bool` | `true` | no |
| should\_enable\_arc\_auto\_upgrade | Enable or disable auto-upgrades of Arc agents. (Otherwise, 'false' for 'env=prod' else 'true' for all other envs). | `bool` | `null` | no |
| should\_generate\_cluster\_server\_token | Should generate token used by the server. ('cluster\_server\_token' must be null if this is 'true') | `bool` | `false` | no |
| should\_output\_cluster\_node\_script | Whether to write out the script for setting up cluster node host machines. (Needed for multi-node clusters) | `bool` | `false` | no |
| should\_output\_cluster\_server\_script | Whether to write out the script for setting up the cluster server host machine. | `bool` | `false` | no |
| should\_skip\_az\_cli\_login | Should skip login process with Azure CLI on the server. (Skipping assumes 'az login' has been completed prior to script execution) | `bool` | `false` | no |
| should\_skip\_installing\_az\_cli | Should skip downloading and installing Azure CLI on the server. (Skipping assumes the server will already have the Azure CLI) | `bool` | `false` | no |
| should\_upload\_to\_key\_vault | Whether to upload the scripts to Key Vault as secrets. | `bool` | `true` | no |
| should\_use\_script\_from\_secrets\_for\_deploy | Whether to use the deploy-script-secrets.sh script to fetch and execute deployment scripts from Key Vault. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| arc\_connected\_cluster | The Arc resource for the connected cluster. |
| azure\_arc\_proxy\_command | The AZ CLI command to Arc Connect Proxy to the cluster. |
| connected\_cluster\_name | The name of the Arc connected cluster. |
| connected\_cluster\_resource\_group\_name | The name of the resource group containing the Arc connected cluster. |
| node\_script\_secret\_download\_command | Az CLI command to download the node script secret. |
| node\_script\_secret\_name | The name of the key vault secret containing the node script. |
| server\_script\_secret\_download\_command | Az CLI command to download the server script secret. |
| server\_script\_secret\_name | The name of the key vault secret containing the server script. |
| server\_token | The token used by the server in the k3s cluster. ('null' if the server is responsible for generating the token) |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
