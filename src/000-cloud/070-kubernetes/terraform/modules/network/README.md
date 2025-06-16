<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Virtual Network Module

Deploys virtual network resources for ACR and AKS

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
| [azurerm_subnet.snet_acr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.snet_aks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.snet_aks_pod](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.snet_nsg_acr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.snet_nsg_aks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.snet_nsg_aks_pod](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod. | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc. | `string` | n/a | yes |
| network\_security\_group | n/a | ```object({ id = string })``` | n/a | yes |
| resource\_group | n/a | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module. | `string` | n/a | yes |
| should\_create\_acr\_private\_endpoint | Should create a private endpoint for the Azure Container Registry. Default is false. | `bool` | n/a | yes |
| virtual\_network | n/a | ```object({ name = string })``` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| snet\_acr | The subnet created for Azure Container Registry private endpoint. |
| snet\_aks | The subnet created for Azure Kubernetes service. |
| snet\_aks\_pod | The subnet created for Azure Kubernetes service pod vnet. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
