<!-- BEGIN_TF_DOCS -->
# Terraform IaC

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.12.0, < 2.0 |
| azapi     | >= 2.3.0         |
| azuread   | >= 3.0.2         |
| azurerm   | >= 4.51.0        |

## Providers

| Name      | Version   |
|-----------|-----------|
| azurerm   | >= 4.51.0 |
| terraform | n/a       |

## Resources

| Name                                                                                                                                            | Type        |
|-------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data)                                  | resource    |
| [azurerm_key_vault.aio](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault)                           | data source |
| [azurerm_resource_group.aio](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group)                 | data source |
| [azurerm_user_assigned_identity.arc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/user_assigned_identity) | data source |
| [azurerm_virtual_machine.aio](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_machine)               | data source |

## Modules

| Name | Source          | Version |
|------|-----------------|---------|
| ci   | ../../terraform | n/a     |

## Inputs

| Name                                            | Description                                                                                                                                                                                                                                                                                        | Type     | Default | Required |
|-------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|---------|:--------:|
| environment                                     | Environment for all resources in this module: dev, test, or prod                                                                                                                                                                                                                                   | `string` | n/a     |   yes    |
| resource\_prefix                                | Prefix for all resources in this module                                                                                                                                                                                                                                                            | `string` | n/a     |   yes    |
| custom\_locations\_oid                          | The object id of the Custom Locations Entra ID application for your tenant. If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions. ```sh az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv``` | `string` | `null`  |    no    |
| instance                                        | Instance identifier for naming resources: 001, 002, etc                                                                                                                                                                                                                                            | `string` | `"001"` |    no    |
| key\_vault\_script\_secret\_prefix              | Optional prefix for the Key Vault script secret name when should\_use\_script\_from\_secrets\_for\_deploy is true.                                                                                                                                                                                 | `string` | `""`    |    no    |
| should\_add\_current\_user\_cluster\_admin      | Gives the current logged in user cluster-admin permissions with the new cluster.                                                                                                                                                                                                                   | `bool`   | `true`  |    no    |
| should\_get\_custom\_locations\_oid             | Whether to get Custom Locations Object ID using Terraform's azuread provider. (Otherwise, provided by 'custom\_locations\_oid' or `az connectedk8s enable-features` for custom-locations on cluster setup if not provided.)                                                                        | `bool`   | `true`  |    no    |
| should\_use\_script\_from\_secrets\_for\_deploy | Whether to use the deploy-script-secrets.sh script to fetch and execute deployment scripts from Key Vault                                                                                                                                                                                          | `bool`   | `true`  |    no    |
<!-- END_TF_DOCS -->
