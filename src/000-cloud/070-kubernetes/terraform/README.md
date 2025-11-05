<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure Kubernetes Service (AKS)

Deploys Azure Kubernetes Service resources

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| archive | >= 2.5.0 |
| azapi | >= 2.3.0 |
| azurerm | >= 4.8.0 |
| msgraph | >= 0.2.0 |
| random | >= 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| msgraph | >= 0.2.0 |

## Resources

| Name | Type |
|------|------|
| [msgraph_resource_action.current_user](https://registry.terraform.io/providers/microsoft/msgraph/latest/docs/resources/resource_action) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| aks\_cluster | ./modules/aks-cluster | n/a |
| arc\_cluster\_instance | ./modules/connectedk8s | n/a |
| command\_invoke | ./modules/command-invoke | n/a |
| network | ./modules/network | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| acr | Azure Container Registry | ```object({ id = string })``` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| network\_security\_group | Network security group object containing id and name for NSG rule associations | ```object({ id = string name = string })``` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed | ```object({ name = string id = string })``` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| virtual\_network | n/a | ```object({ name = string id = string })``` | n/a | yes |
| aks\_command\_invoke\_configurations | Map of AKS command invoke configurations. Key is used as the configuration name/identifier. | ```map(object({ command = optional(string, null) file_path = optional(string, null) folder_path = optional(string, null) timeout_minutes = optional(number, 30) target_cluster_id = optional(string, null) }))``` | `{}` | no |
| aks\_identity | AKS user-assigned identity for custom private DNS zone scenarios. | ```object({ id = string name = string principal_id = string client_id = string tenant_id = string })``` | `null` | no |
| azure\_monitor\_annotations\_allowed | Comma-separated list of additional Kubernetes resource annotations to scrape for Azure Monitor. Format: "pods=[annotation1,...],namespaces=[annotation2,...]". When null, only name and namespace labels are included (recommended for performance). | `string` | `null` | no |
| azure\_monitor\_labels\_allowed | Comma-separated list of additional Kubernetes resource labels to scrape for Azure Monitor. Format: "pods=[label1,...],namespaces=[label2,...]". When null, only name and namespace labels are included (recommended for performance). | `string` | `null` | no |
| cluster\_admin\_oid | The Object ID that will be given Azure Kubernetes Cluster Admin Role permissions on the cluster. (Otherwise, current logged in user Object ID if 'should\_add\_current\_user\_cluster\_admin=true') | `string` | `null` | no |
| default\_outbound\_access\_enabled | Whether to enable default outbound internet access for AKS subnets | `bool` | `false` | no |
| dns\_prefix | DNS prefix for the AKS cluster. This is used to create a unique DNS name for the cluster. If not provided, a default value will be generated. | `string` | `null` | no |
| enable\_auto\_scaling | Should enable auto-scaler for the default node pool. | `bool` | `false` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| log\_analytics\_workspace | Log Analytics workspace object for Microsoft Defender configuration. | ```object({ id = string name = string workspace_id = string primary_shared_key = string })``` | `null` | no |
| logs\_data\_collection\_rule | Logs data collection rule object from observability component for custom Azure Monitor workspace association | ```object({ id = string })``` | `null` | no |
| max\_count | The maximum number of nodes which should exist in the default node pool. Valid values are between 0 and 1000. | `number` | `null` | no |
| metrics\_data\_collection\_rule | Metrics data collection rule object from observability component for custom Azure Monitor workspace association | ```object({ id = string })``` | `null` | no |
| min\_count | The minimum number of nodes which should exist in the default node pool. Valid values are between 0 and 1000. | `number` | `null` | no |
| nat\_gateway | NAT gateway object from networking component for managed outbound access | ```object({ id = string name = string })``` | `null` | no |
| node\_count | Number of nodes for the agent pool in the AKS cluster. | `number` | `1` | no |
| node\_pools | Additional node pools for the AKS cluster. Map key is used as the node pool name. | ```map(object({ node_count = optional(number, null) vm_size = string subnet_address_prefixes = list(string) pod_subnet_address_prefixes = list(string) node_taints = optional(list(string), []) enable_auto_scaling = optional(bool, false) min_count = optional(number, null) max_count = optional(number, null) priority = optional(string, "Regular") zones = optional(list(string), null) eviction_policy = optional(string, "Deallocate") gpu_driver = optional(string, null) }))``` | `{}` | no |
| node\_vm\_size | VM size for the agent pool in the AKS cluster. Default is Standard\_D8ds\_v5. | `string` | `"Standard_D8ds_v5"` | no |
| private\_dns\_zone\_id | ID of the private DNS zone for the private cluster. Use 'system' to have AKS manage it, 'none' for no private DNS zone, or a resource ID for custom zone | `string` | `null` | no |
| private\_endpoint\_subnet\_id | The ID of the subnet where the private endpoint will be created | `string` | `null` | no |
| should\_add\_current\_user\_cluster\_admin | Whether to assign the current logged in user Azure Kubernetes Cluster Admin Role permissions on the cluster when 'cluster\_admin\_oid' is not provided. | `bool` | `true` | no |
| should\_create\_aks | Should create Azure Kubernetes Service. Default is false. | `bool` | `false` | no |
| should\_create\_arc\_cluster\_instance | Should create an Azure Arc Cluster Instance. Default is false. | `bool` | `false` | no |
| should\_disable\_local\_account | Whether to disable local admin account for the AKS cluster. Recommended for security compliance (CKV\_AZURE\_141). | `bool` | `false` | no |
| should\_enable\_azure\_monitor\_metrics | Whether to enable Azure Monitor Metrics (Prometheus) extension for the AKS cluster. | `bool` | `true` | no |
| should\_enable\_nat\_gateway | Whether to associate AKS subnets with a NAT gateway for managed outbound egress | `bool` | `false` | no |
| should\_enable\_oidc\_issuer | Whether to enable the OIDC issuer URL for the cluster. Required for workload identity. | `bool` | `false` | no |
| should\_enable\_private\_cluster | Whether to enable private cluster mode for AKS | `bool` | `false` | no |
| should\_enable\_private\_cluster\_public\_fqdn | Whether to enable public FQDN for private cluster | `bool` | `false` | no |
| should\_enable\_private\_endpoint | Whether to create a private endpoint for the AKS cluster | `bool` | `false` | no |
| should\_enable\_workload\_identity | Whether to enable Azure AD Workload Identity for the cluster. Requires OIDC issuer to be enabled. | `bool` | `false` | no |
| subnet\_address\_prefixes\_aks | Address prefixes for the AKS subnet. | `list(string)` | ```[ "10.0.5.0/24" ]``` | no |
| subnet\_address\_prefixes\_aks\_pod | Address prefixes for the AKS pod subnet. | `list(string)` | ```[ "10.0.6.0/24" ]``` | no |

## Outputs

| Name | Description |
|------|-------------|
| aks | The AKS cluster. |
| aks\_command\_invoke\_results | Map of command invoke execution results by configuration name. |
| aks\_identity | The AKS identity. |
| aks\_kube\_config | The AKS cluster. |
| aks\_node\_pools | The node pools of the AKS cluster. |
| aks\_oidc\_issuer\_url | The OIDC issuer URL for the AKS cluster. |
| aks\_private\_dns\_zone | The private DNS zone of the AKS cluster. |
| aks\_private\_endpoint | The private endpoint of the AKS cluster. |
| connected\_cluster\_id | The ID of the Azure Arc Cluster Instance resource. |
| connected\_cluster\_name | The name of the Azure Arc Cluster Instance resource. |
| oidc\_issuer\_url | The OIDC issuer URL for the Azure Arc Cluster Instance. |
| private\_key\_pem | The private key PEM for the Azure Arc Cluster Instance. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
