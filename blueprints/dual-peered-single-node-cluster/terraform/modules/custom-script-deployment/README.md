<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Custom Script Deployment Module (Refactored)

This module handles deployment of custom scripts to VMs using Azure VM extensions.
Scripts are stored in separate files for better maintainability and readability.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_virtual_machine_extension.enterprise_deployment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.site_deployment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| client\_vm\_id | The resource ID of the client VM (Cluster B). | `string` | n/a | yes |
| enterprise\_client\_ca\_configmap\_name | The name of the Kubernetes configmap containing the client CA certificate | `string` | n/a | yes |
| server\_vm\_id | The resource ID of the server VM (Cluster A). | `string` | n/a | yes |
| should\_deploy\_client\_technology\_script | Whether to deploy the client-technology.sh script to the client VM. | `bool` | n/a | yes |
| should\_deploy\_server\_central\_script | Whether to deploy the server-central.sh script to the server VM. | `bool` | n/a | yes |
| site\_tls\_ca\_configmap\_name | The name of the Kubernetes configmap containing the TLS CA certificate | `string` | n/a | yes |
| certificates | Certificate data to use in scripts. Can come from terraform-certificate-generation module or external source. | ```object({ server_root_ca_cert = string server_root_ca_key = string server_intermediate_ca_cert = string server_intermediate_ca_key = string server_leaf_cert = string server_leaf_key = string client_root_ca_cert = string client_root_ca_key = string client_intermediate_ca_cert = string client_intermediate_ca_key = string client_leaf_cert = string client_leaf_key = string })``` | `null` | no |
| cluster\_config\_ca | The CA certificate for cluster configuration. | `string` | `""` | no |
| enterprise\_synced\_certificates\_secret\_name | The name of the Kubernetes secret containing certificates synced from Key Vault for the enterprise cluster (Cluster A). | `string` | `"certificates-sync-a"` | no |
| site\_synced\_certificates\_secret\_name | The name of the Kubernetes secret containing certificates synced from Key Vault for the site cluster (Cluster B). | `string` | `"certificates-sync-b"` | no |

## Outputs

| Name | Description |
|------|-------------|
| client\_technology\_script\_deployment | The client technology script deployment extension. |
| server\_central\_script\_deployment | The server central script deployment extension. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
