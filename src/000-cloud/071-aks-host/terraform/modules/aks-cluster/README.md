<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Kubernetes Service

Deploys a Kubernetes cluster in Azure with a system-assigned managed identity.
Supports private clusters with optional private endpoints and DNS zone management.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azurerm | >= 4.51.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.51.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_kubernetes_cluster.aks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_kubernetes_cluster_node_pool.additional](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) | resource |
| [azurerm_monitor_data_collection_rule_association.aks_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule_association) | resource |
| [azurerm_monitor_data_collection_rule_association.aks_metrics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule_association) | resource |
| [azurerm_private_dns_a_record.aks_a_record](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_zone.aks_private_dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.aks_vnet_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.aks_pe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_role_assignment.acr_pull](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.cluster_admin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.dns_zone_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| acr | Azure Container Registry | ```object({ id = string })``` | n/a | yes |
| dns\_prefix | DNS prefix for the AKS cluster. This is used to create a unique DNS name for the cluster. If not provided, a default value will be generated. | `string` | n/a | yes |
| enable\_auto\_scaling | Should enable auto-scaler for the default node pool. | `bool` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod. | `string` | n/a | yes |
| instance | Instance identifier for naming resources: 001, 002, etc. | `string` | n/a | yes |
| location | Location for all resources in this module. | `string` | n/a | yes |
| max\_count | The maximum number of nodes which should exist in the default node pool. | `number` | n/a | yes |
| min\_count | The minimum number of nodes which should exist in the default node pool. | `number` | n/a | yes |
| node\_count | Number of nodes for the agent pool in the AKS cluster. | `number` | n/a | yes |
| node\_pools | Additional node pools for the AKS cluster. Map key is used as the node pool name. | ```map(object({ node_count = optional(number, null) vm_size = string vnet_subnet_id = string pod_subnet_id = string node_taints = optional(list(string), []) enable_auto_scaling = optional(bool, false) min_count = optional(number, null) max_count = optional(number, null) priority = optional(string, "Regular") zones = optional(list(string), null) eviction_policy = optional(string) gpu_driver = optional(string, null) }))``` | n/a | yes |
| node\_vm\_size | VM size for the agent pool in the AKS cluster. Default is Standard\_D8ds\_v5. | `string` | n/a | yes |
| private\_dns\_zone\_id | ID of the private DNS zone for the private cluster. Use 'system' to have AKS manage it, 'none' for no private DNS zone, or a resource ID for custom zone | `string` | n/a | yes |
| private\_endpoint\_subnet\_id | The ID of the subnet where the private endpoint will be created | `string` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed | ```object({ name = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module. | `string` | n/a | yes |
| should\_assign\_cluster\_admin | Whether to assign Azure Kubernetes Cluster Admin Role permissions on the cluster. | `bool` | n/a | yes |
| should\_disable\_local\_account | Whether to disable local admin account for the AKS cluster. | `bool` | n/a | yes |
| should\_enable\_private\_cluster | Whether to enable private cluster mode for AKS | `bool` | n/a | yes |
| should\_enable\_private\_cluster\_public\_fqdn | Whether to enable public FQDN for private cluster | `bool` | n/a | yes |
| should\_enable\_private\_endpoint | Whether to create a private endpoint for the AKS cluster | `bool` | n/a | yes |
| snet\_aks | Subnet for the AKS vnet. | ```object({ id = string })``` | n/a | yes |
| snet\_aks\_pod | Subnet for the AKS pod vnet. | ```object({ id = string })``` | n/a | yes |
| virtual\_network\_id | The ID of the virtual network to link to the private DNS zone | `string` | n/a | yes |
| aks\_identity | AKS user-assigned identity for custom private DNS zone scenarios. Required when using custom private DNS zones. | ```object({ id = string name = string principal_id = string client_id = string tenant_id = string })``` | `null` | no |
| azure\_monitor\_annotations\_allowed | Comma-separated list of additional Kubernetes resource annotations to scrape for Azure Monitor. Format: "pods=[annotation1,...],namespaces=[annotation2,...]". When null, only name and namespace labels are included (recommended for performance). | `string` | `null` | no |
| azure\_monitor\_labels\_allowed | Comma-separated list of additional Kubernetes resource labels to scrape for Azure Monitor. Format: "pods=[label1,...],namespaces=[label2,...]". When null, only name and namespace labels are included (recommended for performance). | `string` | `null` | no |
| cluster\_admin\_oid | The Object ID that will be given Azure Kubernetes Cluster Admin Role permissions on the cluster. | `string` | `null` | no |
| log\_analytics\_workspace | Log Analytics workspace object for Microsoft Defender configuration | ```object({ id = string })``` | `null` | no |
| logs\_data\_collection\_rule | Logs data collection rule object from observability component for custom Azure Monitor workspace association | ```object({ id = string })``` | `null` | no |
| metrics\_data\_collection\_rule | Metrics data collection rule object from observability component for custom Azure Monitor workspace association | ```object({ id = string })``` | `null` | no |
| should\_enable\_azure\_monitor\_metrics | Whether to enable Azure Monitor Metrics (Prometheus) extension for the AKS cluster. | `bool` | `true` | no |
| should\_enable\_oidc\_issuer | Whether to enable the OIDC issuer URL for the cluster. Required for workload identity. | `bool` | `false` | no |
| should\_enable\_workload\_identity | Whether to enable Azure AD Workload Identity for the cluster. Requires OIDC issuer to be enabled. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| aks | The Azure Kubernetes Service resource created by this module. |
| aks\_identity | The Azure Kubernetes Service identity. |
| aks\_kube\_config | The Azure Kubernetes Service .kube config. |
| node\_pools | The additional node pools created for the AKS cluster. |
| private\_dns\_zone | The private DNS zone for AKS cluster. |
| private\_endpoint | The private endpoint resource for AKS cluster. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
