<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Terraform IaC

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.8.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| aks\_cluster | ./modules/aks-cluster | n/a |
| container\_registry | ./modules/container-registry | n/a |
| network | ./modules/network | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Location for all resources in this module. | `string` | n/a | yes |
| network\_security\_group | n/a | ```object({ id = string })``` | n/a | yes |
| resource\_group | n/a | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| virtual\_network | n/a | ```object({ name = string id = string })``` | n/a | yes |
| dns\_prefix | DNS prefix for the AKS cluster. This is used to create a unique DNS name for the cluster. If not provided, a default value will be generated. | `string` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc... | `string` | `"001"` | no |
| node\_count | Number of nodes for the agent pool in the AKS cluster. | `number` | `1` | no |
| node\_vm\_size | VM size for the agent pool in the AKS cluster. Default is Standard\_D8ds\_v5. | `string` | `"Standard_D8ds_v5"` | no |
| should\_create\_aks | Should create Azure Kubernetes Service. Default is false. | `bool` | `false` | no |
| should\_create\_private\_endpoint | Should create a private endpoint for the Azure Container Registry. Default is false. | `bool` | `false` | no |
| sku | SKU for the Azure Container Registry. Options are Basic, Standard, Premium. Default is Premium because of the need for private endpoints. | `string` | `"Premium"` | no |

## Outputs

| Name | Description |
|------|-------------|
| acr | The Azure Container Registry resource created by this module. |
| aks | The Azure Kubernetes Service resource created by this module. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
