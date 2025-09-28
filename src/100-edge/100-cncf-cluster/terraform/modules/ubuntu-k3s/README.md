<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Ubuntu k3s

Sets up and deploys a script to a VM host that will setup the k3s cluster,
connect the cluster to Arc, add cluster admins to the cluster, enable workload identity,
along with installing extensions for cluster connect and custom locations.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.8.0 |
| local | n/a |
| random | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_secret.node_script](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.server_script](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [local_sensitive_file.cluster_node_setup_script](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [local_sensitive_file.cluster_server_setup_script](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [random_string.cluster_server_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_resource\_group | n/a | ```object({ name = string id = optional(string) })``` | n/a | yes |
| arc\_onboarding\_sp | n/a | ```object({ client_id = string object_id = string client_secret = string })``` | n/a | yes |
| arc\_resource\_name | The name of the new Azure Arc resource. | `string` | n/a | yes |
| arc\_tenant\_id | The ID of the Tenant for the new Azure Arc resource. | `string` | n/a | yes |
| cluster\_admin\_oid | The Object ID that will be given cluster-admin permissions with the new cluster. (Otherwise, current logged in user Object ID if 'should\_add\_current\_user\_cluster\_admin=true') | `string` | n/a | yes |
| cluster\_admin\_upn | The User Principal Name that will be given cluster-admin permissions with the new cluster. (Otherwise, current logged in user UPN if 'should\_add\_current\_user\_cluster\_admin=true') | `string` | n/a | yes |
| cluster\_server\_host\_machine\_username | Username used for the host machines that will be given kube-config settings on setup. (Otherwise, 'resource\_prefix' if it exists as a user) | `string` | n/a | yes |
| cluster\_server\_ip | The IP Address for the cluster server that the cluster nodes will use to connect. | `string` | n/a | yes |
| cluster\_server\_token | The token that will be given to the server for the cluster or used by the agent nodes to connect them to the cluster. (ex. <https://docs.k3s.io/cli/token>) | `string` | n/a | yes |
| custom\_locations\_oid | The object id of the Custom Locations Entra ID application for your tenant. If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions. ```sh az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv``` | `string` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| script\_output\_filepath | The location of where to write out the script file. (Otherwise, '{path.root}/out') | `string` | n/a | yes |
| should\_enable\_arc\_auto\_upgrade | Enable or disable auto-upgrades of Arc agents. (Otherwise, 'false' for 'env=prod' else 'true' for all other envs). | `bool` | n/a | yes |
| should\_generate\_cluster\_server\_token | Should generate token used by the server. ('cluster\_server\_token' must be null if this is 'true') | `bool` | n/a | yes |
| should\_output\_cluster\_node\_script | Whether to write out the script for setting up cluster node host machines. (Needed for multi-node clusters) | `bool` | n/a | yes |
| should\_output\_cluster\_server\_script | Whether to write out the script for setting up the cluster server host machine. | `bool` | n/a | yes |
| should\_skip\_az\_cli\_login | Should skip login process with Azure CLI on the server. (Skipping assumes 'az login' has been completed prior to script execution) | `bool` | n/a | yes |
| should\_skip\_installing\_az\_cli | Should skip downloading and installing Azure CLI on the server. (Skipping assumes the server will already have the Azure CLI) | `bool` | n/a | yes |
| should\_upload\_to\_key\_vault | Whether to upload the scripts to Key Vault as secrets. | `bool` | n/a | yes |
| should\_use\_script\_from\_secrets\_for\_deploy | Whether to use the deploy-script-secrets.sh script to fetch and execute deployment scripts from Key Vault | `bool` | n/a | yes |
| key\_vault | The Key Vault object containing id, name, and vault\_uri properties | ```object({ id = string name = string vault_uri = string })``` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster\_server\_token | The token used by the server in the cluster for node authentication. ('null' if the server is responsible for generating the token) |
| node\_script\_content | The content of the node setup script. |
| node\_script\_secret\_download\_command | Az CLI command to download the node script secret. |
| node\_script\_secret\_name | The name of the secret for the cluster node script. |
| server\_script\_content | The content of the server setup script. |
| server\_script\_secret\_download\_command | Az CLI command to download the server script secret. |
| server\_script\_secret\_name | The name of the secret for the cluster server script. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
