<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Robotics Blueprint

Deploys robotics infrastructure with NVIDIA GPU support, KAI Scheduler,
and optional Azure Machine Learning integration.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.8.0 |
| tls | >= 4.0.6 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| robotics | ../../modules/robotics/terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| aks\_cluster\_name | Existing AKS cluster name for ML integration (Otherwise 'aks-{resource\_prefix}-{environment}-{instance}') | `string` | `null` | no |
| aks\_cluster\_purpose | Purpose of AKS cluster: DevTest, DenseProd, or FastProd | `string` | `"DevTest"` | no |
| azureml\_workspace\_name | Existing or desired Azure ML workspace name (Otherwise 'mlw-{resource\_prefix}-{environment}-{instance}') | `string` | `null` | no |
| cluster\_integration\_instance\_types | Instance types configuration for Kubernetes compute. Key is the instance type name, value contains nodeSelector and resource specifications | ```map(object({ nodeSelector = optional(map(string)) resources = optional(object({ requests = optional(map(any)) limits = optional(map(any)) })) }))``` | `null` | no |
| compute\_cluster\_max\_nodes | Maximum number of nodes in compute cluster | `number` | `1` | no |
| compute\_cluster\_min\_nodes | Minimum number of nodes in compute cluster | `number` | `0` | no |
| compute\_cluster\_vm\_priority | VM priority for compute cluster: Dedicated or LowPriority | `string` | `"Dedicated"` | no |
| enable\_auto\_scaling | Should enable auto-scaler for the default node pool | `bool` | `false` | no |
| inference\_router\_service\_type | Service type for inference router: LoadBalancer, NodePort, or ClusterIP | `string` | `"NodePort"` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| max\_count | The maximum number of nodes which should exist in the default node pool. Valid values are between 0 and 1000 | `number` | `null` | no |
| min\_count | The minimum number of nodes which should exist in the default node pool. Valid values are between 0 and 1000 | `number` | `null` | no |
| node\_count | Number of nodes for the agent pool in the AKS cluster | `number` | `1` | no |
| node\_pools | Additional node pools for the AKS cluster. Map key is used as the node pool name | ```map(object({ node_count = optional(number, null) vm_size = string subnet_address_prefixes = list(string) pod_subnet_address_prefixes = list(string) node_taints = optional(list(string), []) enable_auto_scaling = optional(bool, false) min_count = optional(number, null) max_count = optional(number, null) priority = optional(string, "Regular") zones = optional(list(string), null) eviction_policy = optional(string, "Deallocate") gpu_driver = optional(string, null) }))``` | `{}` | no |
| node\_vm\_size | VM size for the agent pool in the AKS cluster. Default is Standard\_D8ds\_v5 | `string` | `"Standard_D8ds_v5"` | no |
| resource\_group\_name | Existing resource group name containing foundational and ML resources (Otherwise 'rg-{resource\_prefix}-{environment}-{instance}') | `string` | `null` | no |
| should\_assign\_current\_user\_vm\_admin | Whether to assign current user VM admin role for Azure AD login | `bool` | `true` | no |
| should\_create\_acr | Whether to create Azure Container Registry for robotics images | `bool` | `true` | no |
| should\_create\_aks\_cluster | Whether to create AKS cluster for robotics workloads | `bool` | `true` | no |
| should\_create\_compute\_cluster | Whether to create compute cluster for ML training workloads | `bool` | `true` | no |
| should\_create\_ml\_workload\_identity | Whether to create user-assigned managed identity for AzureML workload federation | `bool` | `true` | no |
| should\_create\_networking | Whether to create virtual network for robotics infrastructure | `bool` | `true` | no |
| should\_create\_observability | Whether to create observability resources | `bool` | `true` | no |
| should\_create\_security\_identity | Whether to create security and identity resources | `bool` | `true` | no |
| should\_create\_storage | Whether to create storage resources | `bool` | `true` | no |
| should\_create\_vm\_host | Whether to create VM host for GPU workloads and testing | `bool` | `false` | no |
| should\_create\_vm\_ssh\_key | Whether to generate SSH key pair for VM access | `bool` | `true` | no |
| should\_deploy\_azureml\_registry | Whether to deploy AzureML Registry for model management | `bool` | `false` | no |
| should\_deploy\_edge\_extension | Whether to deploy Azure ML edge extension on a connected cluster | `bool` | `false` | no |
| should\_enable\_managed\_outbound\_access | Whether to enable managed outbound egress via NAT gateway instead of platform default internet access | `bool` | `true` | no |
| should\_enable\_private\_endpoints | Whether to enable private endpoints across resources for secure connectivity | `bool` | `false` | no |
| should\_enable\_vpn\_gateway | Whether to create VPN Gateway for remote access | `bool` | `false` | no |
| should\_install\_azureml\_charts | Whether to install AzureML charts | `bool` | `false` | no |
| should\_install\_dcgm\_exporter | Whether to install DCGM exporter for GPU metrics (prefer should\_install\_robotics\_charts) | `bool` | `false` | no |
| should\_install\_nvidia\_device\_plugin | Whether to install NVIDIA Device Plugin for GPU support (prefer should\_install\_robotics\_charts) | `bool` | `false` | no |
| should\_install\_robotics\_charts | Whether to install robotics charts (NVIDIA related) | `bool` | `true` | no |
| should\_install\_volcano | Whether to install Volcano scheduler (prefer should\_install\_azureml\_charts) | `bool` | `false` | no |
| should\_integrate\_aks\_cluster | Whether to integrate an AKS cluster as a compute target with the workspace | `bool` | `false` | no |
| should\_use\_vm\_password\_auth | Whether to use password authentication for VM access | `bool` | `false` | no |
| subnet\_address\_prefixes\_aks | Address prefixes for the AKS subnet | `list(string)` | ```[ "10.0.5.0/24" ]``` | no |
| subnet\_address\_prefixes\_aks\_pod | Address prefixes for the AKS pod subnet | `list(string)` | ```[ "10.0.6.0/24" ]``` | no |
| virtual\_network\_config | Configuration for the virtual network including address space and subnet prefix | ```object({ address_space = string subnet_address_prefix = string })``` | ```{ "address_space": "10.0.0.0/16", "subnet_address_prefix": "10.0.1.0/24" }``` | no |
| virtual\_network\_name | Existing or desired virtual network name (Otherwise 'vnet-{resource\_prefix}-{environment}-{instance}') | `string` | `null` | no |
| vm\_eviction\_policy | Eviction policy for Spot VMs: Deallocate or Delete | `string` | `"Deallocate"` | no |
| vm\_host\_count | Number of VM hosts to create | `number` | `1` | no |
| vm\_max\_bid\_price | Maximum hourly price for Spot VM (-1 for Azure default) | `number` | `-1` | no |
| vm\_priority | VM priority: Regular or Spot for cost optimization | `string` | `"Regular"` | no |
| vm\_sku\_size | VM SKU size for the host | `string` | `"Standard_D8s_v3"` | no |
| vpn\_site\_connections | Site-to-site VPN site definitions for connecting on-premises networks | ```list(object({ name = string address_spaces = list(string) shared_key_reference = string gateway_ip_address = optional(string) gateway_fqdn = optional(string) bgp_asn = optional(number) bgp_peering_address = optional(string) ike_protocol = optional(string, "IKEv2") }))``` | `[]` | no |
| vpn\_site\_default\_ipsec\_policy | Fallback IPsec policy applied when vpn\_site\_connections omit ipsec\_policy overrides | ```object({ dh_group = string ike_encryption = string ike_integrity = string ipsec_encryption = string ipsec_integrity = string pfs_group = string sa_datasize_kb = optional(number) sa_lifetime_seconds = optional(number) })``` | `null` | no |
| vpn\_site\_shared\_keys | Pre-shared keys for site-to-site VPN connections indexed by connection name | `map(string)` | `{}` | no |
| workload\_tolerations | Tolerations for AzureML workloads (training/inference) to schedule on nodes with taints | ```list(object({ key = string operator = string value = optional(string) effect = string }))``` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| acr\_network\_posture | Container registry network posture |
| aks\_cluster | AKS cluster for robotics workloads |
| aks\_oidc\_issuer\_url | OIDC issuer URL for workload identity |
| azureml\_workspace | Azure ML workspace when AzureML charts are enabled |
| resource\_group | Resource group for robotics infrastructure |
| virtual\_network | Virtual network for robotics infrastructure |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
