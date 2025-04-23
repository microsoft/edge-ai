<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Virtual Network Module

Deploys virtual network resources for VM hosts

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
| [azurerm_network_security_group.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_subnet.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_network.aio_edge](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| label\_prefix | Prefix to be used for all resource names | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_group\_name | Resource group name for all resources in this module | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| network\_security\_group | The created network security group |
| subnet\_id | The ID of the created subnet |
| virtual\_network | The created virtual network |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
