<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Kubernetes Service

Deploys a Kubernetes cluster in Azure with a system-assigned managed identity.

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
| [azurerm_kubernetes_cluster.aks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_role_assignment.acr_pull](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| acr | Azure Container Registry | ```object({ id = string })``` | n/a | yes |
| dns\_prefix | DNS prefix for the AKS cluster. This is used to create a unique DNS name for the cluster. If not provided, a default value will be generated. | `string` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| node\_count | Number of nodes for the agent pool in the AKS cluster. | `number` | n/a | yes |
| node\_vm\_size | VM size for the agent pool in the AKS cluster. Default is Standard\_D8ds\_v5. | `string` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| snet\_aks | Subnet for the AKS vnet. | ```object({ id = string })``` | n/a | yes |
| snet\_aks\_pod | Subnet for the AKS pod vnet. | ```object({ id = string })``` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| aks | The Azure Kubernetes Service resource created by this module. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
