<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Kubernetes Service (AKS)

Deploys Azure Kubernetes Service resources

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.8.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| aks\_cluster | ./modules/aks-cluster | n/a |
| arc\_cluster\_instance | ./modules/connectedk8s | n/a |
| network | ./modules/network | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| acr | n/a | ```object({ id = string })``` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| network\_security\_group | n/a | ```object({ id = string })``` | n/a | yes |
| resource\_group | n/a | ```object({ name = string id = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| virtual\_network | n/a | ```object({ name = string id = string })``` | n/a | yes |
| dns\_prefix | DNS prefix for the AKS cluster. This is used to create a unique DNS name for the cluster. If not provided, a default value will be generated. | `string` | `null` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| node\_count | Number of nodes for the agent pool in the AKS cluster. | `number` | `1` | no |
| node\_vm\_size | VM size for the agent pool in the AKS cluster. Default is Standard\_D8ds\_v5. | `string` | `"Standard_D8ds_v5"` | no |
| should\_create\_aks | Should create Azure Kubernetes Service. Default is false. | `bool` | `false` | no |
| should\_create\_arc\_cluster\_instance | Should create an Azure Arc Cluster Instance. Default is false. | `bool` | `false` | no |
| subnet\_address\_prefixes\_aks | Address prefixes for the AKS subnet. | `list(string)` | ```[ "10.0.3.0/24" ]``` | no |
| subnet\_address\_prefixes\_aks\_pod | Address prefixes for the AKS pod subnet. | `list(string)` | ```[ "10.0.4.0/24" ]``` | no |

## Outputs

| Name | Description |
|------|-------------|
| aks | The Azure Kubernetes Service resource created by this module. |
| connected\_cluster\_id | The ID of the Azure Arc Cluster Instance resource. |
| connected\_cluster\_name | The name of the Azure Arc Cluster Instance resource. |
| oidc\_issuer\_url | The OIDC issuer URL for the Azure Arc Cluster Instance. |
| private\_key\_pem | The private key PEM for the Azure Arc Cluster Instance. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
