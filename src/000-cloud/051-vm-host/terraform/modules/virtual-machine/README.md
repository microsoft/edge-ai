<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Virtual Machine Module

Deploys a Linux VM with configuration for Arc-connected K3s cluster

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
| [azurerm_linux_virtual_machine.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_public_ip.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| label\_prefix | Prefix to be used for all resource names | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_group\_name | Resource group name for all resources in this module | `string` | n/a | yes |
| ssh\_public\_key | SSH public key to use for VM authentication | `string` | n/a | yes |
| subnet\_id | ID of the subnet to attach the VM to | `string` | n/a | yes |
| vm\_index | Index of the VM for deployment of multiple VMs | `number` | n/a | yes |
| vm\_username | Username for the VM admin account | `string` | n/a | yes |
| arc\_onboarding\_identity\_id | ID of the user assigned identity for Arc onboarding | `string` | `null` | no |
| vm\_sku\_size | Size of the VM | `string` | `"Standard_D8s_v3"` | no |

## Outputs

| Name | Description |
|------|-------------|
| linux\_virtual\_machine\_name | The name of the VM |
| private\_ip | The private IP address of the VM |
| public\_fqdn | The public FQDN of the VM |
| public\_ip | The public IP address of the VM |
| virtual\_machine | The complete VM resource |
| vm\_id | The ID of the VM |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
