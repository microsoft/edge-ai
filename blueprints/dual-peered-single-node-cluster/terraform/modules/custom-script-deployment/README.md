<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Custom Script Deployment Module (Refactored)

This module handles deployment of custom scripts to VMs using Azure VM extensions.
Scripts are stored in separate files for better maintainability and readability.

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
| enterprise\_broker\_server\_cert\_secret\_name | The name of the Kubernetes secret containing the broker server certificate | `string` | n/a | yes |
| enterprise\_client\_ca\_configmap\_name | The name of the Kubernetes configmap containing the client CA certificate | `string` | n/a | yes |
| server\_vm\_id | The resource ID of the server VM (Cluster A). | `string` | n/a | yes |
| should\_deploy\_client\_technology\_script | Whether to deploy the client-technology.sh script to the client VM. | `bool` | n/a | yes |
| should\_deploy\_server\_central\_script | Whether to deploy the server-central.sh script to the server VM. | `bool` | n/a | yes |
| site\_client\_secret\_name | The name of the Kubernetes secret containing the client certificate and key | `string` | n/a | yes |
| site\_tls\_ca\_configmap\_name | The name of the Kubernetes configmap containing the TLS CA certificate | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| client\_technology\_script\_deployment | The client technology script deployment extension. |
| server\_central\_script\_deployment | The server central script deployment extension. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
