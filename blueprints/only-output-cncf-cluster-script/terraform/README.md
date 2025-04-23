<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Terraform IaC

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.8.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_user_assigned_identity.arc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/user_assigned_identity) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| edge\_cncf\_cluster | ../../../src/100-edge/100-cncf-cluster/terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| aio\_resource\_group\_name | The name of the Resource Group that will be used to connect the new cluster to Azure Arc. (Otherwise, 'rg-{var.resource\_prefix}-{var.environment}-{var.instance}' Does not need to exist for output script)" | `string` | `null` | no |
| arc\_onboarding\_identity\_name | The Principal ID for the identity that will be used for onboarding the cluster to Arc. | `string` | `null` | no |
| arc\_onboarding\_sp | n/a | ```object({ client_id = string object_id = string client_secret = string })``` | `null` | no |
| cluster\_admin\_oid | The Object ID that will be given cluster-admin permissions with the new cluster. (Otherwise, current logged in user if 'should\_add\_current\_user\_cluster\_admin=true') | `string` | `null` | no |
| cluster\_server\_host\_machine\_username | Username used for the host machines that will be given kube-config settings on setup. (Otherwise, 'resource\_prefix' if it exists as a user) | `string` | `null` | no |
| custom\_locations\_oid | The object id of the Custom Locations Entra ID application for your tenant. If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions. ```sh az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv``` | `string` | `null` | no |
| enable\_arc\_auto\_upgrade | Enable or disable auto-upgrades of Arc agents. (Otherwise, 'false' for 'env=prod' else 'true' for all other envs). | `bool` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| script\_output\_filepath | The location of where to write out the script file. (Otherwise, '{path.root}/out') | `string` | `null` | no |
| should\_add\_current\_user\_cluster\_admin | Gives the current logged in user cluster-admin permissions with the new cluster. | `bool` | `true` | no |
| should\_assign\_roles | Whether to assign Key Vault roles to identity or service principal. | `bool` | `false` | no |
| should\_get\_custom\_locations\_oid | Whether to get Custom Locations Object ID using Terraform's azuread provider. (Otherwise, provided by 'custom\_locations\_oid' or `az connectedk8s enable-features` for custom-locations on cluster setup if not provided.) | `bool` | `true` | no |
| should\_output\_cluster\_node\_script | Whether to write out the script for setting up cluster node host machines. (Needed for multi-node clusters) | `string` | `false` | no |
| should\_output\_cluster\_server\_script | Whether to write out the script for setting up the cluster server host machine. | `string` | `true` | no |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
