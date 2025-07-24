<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Key Vault Certificate Publisher Module

This module publishes certificates to Azure Key Vault using the exact same secret names
as defined in the SecretProviderClass resource. It supports both terraform-generated
certificates and externally provided certificates.

## Providers

| Name | Version |
|------|---------|
| azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_secret.cluster_a_client_intermediate_ca_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.cluster_a_client_leaf_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.cluster_a_client_leaf_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.cluster_a_client_root_ca_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.cluster_a_server_intermediate_ca_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.cluster_a_server_leaf_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.cluster_a_server_leaf_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.cluster_a_server_root_ca_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.cluster_b_client_intermediate_ca_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.cluster_b_client_leaf_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.cluster_b_client_leaf_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.cluster_b_client_root_ca_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.cluster_b_server_intermediate_ca_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.cluster_b_server_leaf_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.cluster_b_server_leaf_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.cluster_b_server_root_ca_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| certificates | Certificate data to write to Key Vault. Can come from terraform-certificate-generation module or external source. | ```object({ server_root_ca_cert = string server_root_ca_key = string server_intermediate_ca_cert = string server_intermediate_ca_key = string server_leaf_cert = string server_leaf_key = string client_root_ca_cert = string client_root_ca_key = string client_intermediate_ca_cert = string client_intermediate_ca_key = string client_leaf_cert = string client_leaf_key = string })``` | n/a | yes |
| cluster\_a\_key\_vault\_id | Resource ID of the Key Vault for cluster A. | `string` | n/a | yes |
| cluster\_a\_name | Name of cluster A for tagging purposes. | `string` | n/a | yes |
| cluster\_b\_key\_vault\_id | Resource ID of the Key Vault for cluster B. | `string` | n/a | yes |
| cluster\_b\_name | Name of cluster B for tagging purposes. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| certificate\_secret\_names | Names of certificate secrets created in Key Vault (same for both clusters). |
| cluster\_a\_certificate\_secret\_ids | Resource IDs of certificate secrets created in Cluster A Key Vault. |
| cluster\_b\_certificate\_secret\_ids | Resource IDs of certificate secrets created in Cluster B Key Vault. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
