<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Arc Server Script Deployment

This module handles script deployment to Azure Arc-connected servers, with the option
to either deploy a script directly, or deploy the deploy-script-secrets.sh script
which will fetch the real script from Key Vault and execute it.

Note: Windows support will be added in a future update.

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
| [azurerm_arc_machine_extension.linux_script_deployment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_machine_extension) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| arc\_machine\_id | The ID of the Azure Arc-connected machine to deploy the script to. | `string` | n/a | yes |
| extension\_name | The name of the Arc machine extension. | `string` | n/a | yes |
| kubernetes\_distro | The Kubernetes distribution (e.g., 'k3s', 'aks') - Used to construct the Key Vault secret name. | `string` | n/a | yes |
| location | The Azure region where the Arc-connected machine is registered. | `string` | n/a | yes |
| node\_type | The node type (e.g., 'server', 'node') - Used to construct the Key Vault secret name. | `string` | n/a | yes |
| secret\_name\_prefix | Optional prefix for the Key Vault secret name. | `string` | n/a | yes |
| should\_use\_script\_from\_secrets\_for\_deploy | Flag to enable fetching script from Key Vault instead of using script\_content directly. | `bool` | n/a | yes |
| key\_vault | The Key Vault object containing id, name, and vault\_uri properties. | ```object({ id = string name = string vault_uri = string })``` | `null` | no |
| os\_type | The OS type of the machine (currently only 'linux' is supported). | `string` | `"linux"` | no |
| script\_content | The content of the script to deploy when not fetching from Key Vault. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| linux\_extension\_id | The ID of the Linux Arc machine extension, if it was created. |
| script\_deployed | Whether a script was successfully deployed to the Arc-connected machine. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
