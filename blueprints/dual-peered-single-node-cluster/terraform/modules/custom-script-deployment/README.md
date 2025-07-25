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
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| client\_vm\_id | The resource ID of the client VM (Cluster B). | `string` | n/a | yes |
| cluster\_a\_key\_vault | The Key Vault for Cluster A. | ```object({ name = string })``` | n/a | yes |
| cluster\_a\_name | The name identifier for Cluster A. | `string` | n/a | yes |
| cluster\_a\_secret\_sync\_identity | The secret sync identity for Cluster A. | ```object({ client_id = string })``` | n/a | yes |
| cluster\_b\_key\_vault | The Key Vault for Cluster B. | ```object({ name = string })``` | n/a | yes |
| cluster\_b\_name | The name identifier for Cluster B. | `string` | n/a | yes |
| cluster\_b\_secret\_sync\_identity | The secret sync identity for Cluster B. | ```object({ client_id = string })``` | n/a | yes |
| enterprise\_client\_ca\_configmap\_name | The name of the Kubernetes configmap containing the client CA certificate | `string` | n/a | yes |
| server\_vm\_id | The resource ID of the server VM (Cluster A). | `string` | n/a | yes |
| should\_deploy\_client\_technology\_script | Whether to deploy the client-technology.sh script to the client VM. | `bool` | n/a | yes |
| should\_deploy\_server\_central\_script | Whether to deploy the server-central.sh script to the server VM. | `bool` | n/a | yes |
| site\_tls\_ca\_configmap\_name | The name of the Kubernetes configmap containing the TLS CA certificate | `string` | n/a | yes |
| enterprise\_synced\_certificates\_secret\_name | The name of the Kubernetes secret containing certificates synced from Key Vault for the enterprise cluster (Cluster A). | `string` | `"certificates-sync-a"` | no |
| site\_synced\_certificates\_secret\_name | The name of the Kubernetes secret containing certificates synced from Key Vault for the site cluster (Cluster B). | `string` | `"certificates-sync-b"` | no |

## Outputs

| Name | Description |
|------|-------------|
| client\_technology\_script\_deployment | The client technology script deployment extension. |
| server\_central\_script\_deployment | The server central script deployment extension. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
