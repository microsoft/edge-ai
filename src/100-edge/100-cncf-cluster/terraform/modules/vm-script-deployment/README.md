<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# VM Script Deployment

This module handles script deployment to Linux virtual machines, with the option
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
| [azurerm_virtual_machine_extension.linux_script_deployment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| extension\_name | The name of the VM extension. | `string` | n/a | yes |
| kubernetes\_distro | The Kubernetes distribution (e.g., 'k3s', 'aks') - Used to construct the Key Vault secret name. | `string` | n/a | yes |
| node\_type | The node type (e.g., 'server', 'node') - Used to construct the Key Vault secret name. | `string` | n/a | yes |
| secret\_name\_prefix | Optional prefix for the Key Vault secret name. | `string` | n/a | yes |
| should\_use\_script\_from\_secrets\_for\_deploy | Flag to enable fetching script from Key Vault instead of using script\_content directly. | `bool` | n/a | yes |
| virtual\_machine\_id | The ID of the virtual machine to deploy the script to. | `string` | n/a | yes |
| key\_vault | The Key Vault object containing id, name, and vault\_uri properties. | ```object({ id = string name = string vault_uri = string })``` | `null` | no |
| managed\_identity\_client\_id | The client ID of the managed identity used to access Key Vault. | `string` | `null` | no |
| os\_type | The OS type of the virtual machine (currently only 'linux' is supported). | `string` | `"linux"` | no |
| script\_content | The content of the script to deploy when not fetching from Key Vault. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| linux\_extension\_id | The ID of the Linux VM extension, if it was created. |
| script\_deployed | Whether a script was successfully deployed to the VM. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
