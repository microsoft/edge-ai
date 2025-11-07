<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure ML Unified Blueprint

Adds Azure Machine Learning capabilities with optional foundational resource creation and scenario-driven deployment.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azuread | >= 3.0.2 |
| azurerm | >= 4.51.0 |
| tls | >= 4.0.6 |

## Providers

| Name | Version |
|------|---------|
| azapi | >= 2.3.0 |
| azurerm | >= 4.51.0 |
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azapi_resource.arc_connected_cluster](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) | data source |
| [azurerm_application_insights.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/application_insights) | data source |
| [azurerm_container_registry.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/container_registry) | data source |
| [azurerm_key_vault.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_kubernetes_cluster.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/kubernetes_cluster) | data source |
| [azurerm_resource_group.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_storage_account.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account) | data source |
| [azurerm_subnet.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| cloud\_acr | ../../../../src/000-cloud/060-acr/terraform | n/a |
| cloud\_azureml | ../../../../src/000-cloud/080-azureml/terraform | n/a |
| cloud\_data | ../../../../src/000-cloud/030-data/terraform | n/a |
| cloud\_kubernetes | ../../../../src/000-cloud/070-kubernetes/terraform | n/a |
| cloud\_managed\_redis | ../../../../src/000-cloud/036-managed-redis/terraform | n/a |
| cloud\_networking | ../../../../src/000-cloud/050-networking/terraform | n/a |
| cloud\_observability | ../../../../src/000-cloud/020-observability/terraform | n/a |
| cloud\_postgresql | ../../../../src/000-cloud/035-postgresql/terraform | n/a |
| cloud\_security\_identity | ../../../../src/000-cloud/010-security-identity/terraform | n/a |
| cloud\_vm\_host | ../../../../src/000-cloud/051-vm-host/terraform | n/a |
| cloud\_vpn\_gateway | ../../../../src/000-cloud/055-vpn-gateway/terraform | n/a |
| edge\_azureml | ../../../../src/100-edge/140-azureml/terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Location for all resources in this module | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| acr\_allow\_trusted\_services | Whether trusted Azure services can bypass ACR network rules | `bool` | `true` | no |
| acr\_allowed\_public\_ip\_ranges | CIDR ranges permitted to reach the ACR public endpoint | `list(string)` | `[]` | no |
| acr\_data\_endpoint\_enabled | Whether to enable the dedicated ACR data endpoint | `bool` | `true` | no |
| acr\_name | Existing or desired ACR name when not creating (Otherwise computed) | `string` | `null` | no |
| acr\_public\_network\_access\_enabled | Whether to enable the ACR public endpoint alongside private connectivity | `bool` | `false` | no |
| acr\_sku | SKU name for the Azure Container Registry | `string` | `"Premium"` | no |
| aks\_cluster\_name | Existing AKS cluster name for ML integration (Otherwise 'aks-{resource\_prefix}-{environment}-{instance}') | `string` | `null` | no |
| aks\_cluster\_purpose | Purpose of AKS cluster: DevTest, DenseProd, or FastProd | `string` | `"DevTest"` | no |
| aks\_compute\_target\_name | Name of the AKS compute target in ML workspace. Otherwise, 'aks-compute-{resource\_prefix}-{environment}-{instance}' | `string` | `null` | no |
| aks\_private\_dns\_zone\_id | ID of the private DNS zone to use for AKS private cluster. If not provided, a new zone will be created | `string` | `null` | no |
| aks\_should\_enable\_private\_cluster | Whether to enable private cluster for AKS | `bool` | `false` | no |
| aks\_should\_enable\_private\_cluster\_public\_fqdn | Whether to create a FQDN for private cluster (sets enable\_private\_cluster\_public\_fqdn) | `bool` | `false` | no |
| application\_insights\_name | Existing or desired Application Insights name (Otherwise 'appi-{resource\_prefix}-{environment}-{instance}') | `string` | `null` | no |
| arc\_cluster\_purpose | Purpose of Arc cluster: DevTest, DenseProd, or FastProd | `string` | `"DevTest"` | no |
| arc\_compute\_target\_name | Name of the Arc compute target in ML workspace. Otherwise, 'arck-{resource\_prefix}-{environment}-{instance}' | `string` | `null` | no |
| arc\_connected\_cluster\_name | Existing Arc connected cluster name for edge ML scenarios (Otherwise 'arck-{resource\_prefix}-{environment}-{instance}') | `string` | `null` | no |
| azureml\_workspace\_name | Existing or desired Azure ML workspace name (Otherwise 'mlw-{resource\_prefix}-{environment}-{instance}') | `string` | `null` | no |
| certificate\_subject | Certificate subject information for auto-generated certificates | ```object({ common_name = optional(string, "Azure ML VPN Gateway Root Certificate") organization = optional(string, "Edge AI Accelerator") organizational_unit = optional(string, "IT") country = optional(string, "US") province = optional(string, "WA") locality = optional(string, "Redmond") })``` | `{}` | no |
| certificate\_validity\_days | Validity period in days for auto-generated certificates | `number` | `365` | no |
| cluster\_integration\_default\_instance\_type | Default instance type for the Kubernetes compute. | `string` | `"defaultinstancetype"` | no |
| cluster\_integration\_description | Description for the AKS integration compute target. Otherwise, 'Azure ML AKS compute target for {resource\_prefix}-{environment}-{instance}'. | `string` | `null` | no |
| cluster\_integration\_disable\_local\_auth | Whether to disable local authentication for the AKS integration compute target. | `bool` | `true` | no |
| cluster\_integration\_instance\_types | Instance types configuration for Kubernetes compute. Key is the instance type name, value contains nodeSelector and resource specifications. | ```map(object({ nodeSelector = optional(map(string)) resources = optional(object({ requests = optional(map(any)) limits = optional(map(any)) })) }))``` | `null` | no |
| compute\_cluster\_idle\_duration | Time to wait before scaling down idle nodes. Format: PT{minutes}M (e.g., PT15M for 30 minutes) | `string` | `"PT30M"` | no |
| compute\_cluster\_max\_nodes | Maximum number of nodes in compute cluster for auto-scaling. Default: 1 (cost-optimized for single-model training) | `number` | `1` | no |
| compute\_cluster\_min\_nodes | Minimum number of nodes in compute cluster for auto-scaling. Default: 0 (cost-optimized, scales to zero when idle) | `number` | `0` | no |
| compute\_cluster\_name | Name of the compute cluster for ML training workloads. Otherwise, 'cluster-{resource\_prefix}-{environment}-{instance}' | `string` | `null` | no |
| compute\_cluster\_vm\_priority | VM priority for compute cluster nodes: Dedicated (production, higher cost) or LowPriority (development, 60-80% cost savings but can be preempted) | `string` | `"Dedicated"` | no |
| compute\_cluster\_vm\_size | VM size for compute cluster nodes. Standard\_DS3\_v2 (4 vCPUs, 14 GiB RAM) recommended for balanced production ML workloads | `string` | `"Standard_DS3_v2"` | no |
| dns\_prefix | DNS prefix for the AKS cluster. This is used to create a unique DNS name for the cluster. If not provided, a default value will be generated. | `string` | `null` | no |
| enable\_auto\_scaling | Should enable auto-scaler for the default node pool. | `bool` | `false` | no |
| existing\_certificate\_name | Name of existing certificate in Key Vault when vpn\_gateway\_should\_generate\_ca is false | `string` | `null` | no |
| extension\_name | Name of the Azure ML extension for AKS cluster. Otherwise, 'azureml-{resource\_prefix}-{environment}-{instance}' | `string` | `null` | no |
| inference\_router\_service\_type | Service type for inference router: LoadBalancer, NodePort, or ClusterIP | `string` | `"NodePort"` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| key\_vault\_name | Existing or desired Key Vault name (Otherwise 'kv-{resource\_prefix}-{environment}-{instance}') | `string` | `null` | no |
| max\_count | The maximum number of nodes which should exist in the default node pool. Valid values are between 0 and 1000. | `number` | `null` | no |
| min\_count | The minimum number of nodes which should exist in the default node pool. Valid values are between 0 and 1000. | `number` | `null` | no |
| ml\_workload\_subjects | Custom Kubernetes service account subjects for AzureML workload federation. Example: ['system:serviceaccount:azureml:azureml-workload', 'system:serviceaccount:osmo:osmo-workload'] | `list(string)` | ```[ "system:serviceaccount:azureml:azureml-workload", "system:serviceaccount:osmo:osmo-workload" ]``` | no |
| nat\_gateway\_idle\_timeout\_minutes | Idle timeout in minutes for NAT gateway connections | `number` | `4` | no |
| nat\_gateway\_public\_ip\_count | Number of public IP addresses to associate with the NAT gateway (example: 2) | `number` | `1` | no |
| nat\_gateway\_zones | Availability zones for NAT gateway resources when zone-redundancy is required (example: ['1','2']) | `list(string)` | `[]` | no |
| node\_count | Number of nodes for the agent pool in the AKS cluster. | `number` | `1` | no |
| node\_pools | Additional node pools for the AKS cluster. Map key is used as the node pool name. | ```map(object({ node_count = optional(number, null) vm_size = string subnet_address_prefixes = list(string) pod_subnet_address_prefixes = list(string) node_taints = optional(list(string), []) enable_auto_scaling = optional(bool, false) min_count = optional(number, null) max_count = optional(number, null) priority = optional(string, "Regular") zones = optional(list(string), null) eviction_policy = optional(string, "Deallocate") gpu_driver = optional(string, null) }))``` | `{}` | no |
| node\_vm\_size | VM size for the agent pool in the AKS cluster. Default is Standard\_D8ds\_v5. | `string` | `"Standard_D8ds_v5"` | no |
| postgresql\_admin\_password | Administrator password for PostgreSQL server. (Otherwise, generated when postgresql\_should\_generate\_admin\_password is true). | `string` | `null` | no |
| postgresql\_admin\_username | Administrator username for PostgreSQL server | `string` | `"pgadmin"` | no |
| postgresql\_databases | Map of databases to create with collation and charset | ```map(object({ collation = string charset = string }))``` | `null` | no |
| postgresql\_delegated\_subnet\_id | Subnet ID with delegation to Microsoft.DBforPostgreSQL/flexibleServers. (Otherwise, created when should\_create\_networking is true). | `string` | `null` | no |
| postgresql\_should\_enable\_extensions | Whether to enable PostgreSQL extensions via azure.extensions | `bool` | `true` | no |
| postgresql\_should\_enable\_geo\_redundant\_backup | Whether to enable geo-redundant backups for PostgreSQL | `bool` | `false` | no |
| postgresql\_should\_enable\_timescaledb | Whether to enable TimescaleDB extension for PostgreSQL | `bool` | `true` | no |
| postgresql\_should\_generate\_admin\_password | Whether to auto-generate PostgreSQL admin password. | `bool` | `true` | no |
| postgresql\_should\_store\_credentials\_in\_key\_vault | Whether to store PostgreSQL admin credentials in Key Vault. | `bool` | `true` | no |
| postgresql\_sku\_name | SKU name for PostgreSQL server | `string` | `"GP_Standard_D2s_v3"` | no |
| postgresql\_storage\_mb | Storage size in megabytes for PostgreSQL | `number` | `32768` | no |
| postgresql\_subnet\_address\_prefixes | Address prefixes for the PostgreSQL delegated subnet. | `list(string)` | ```[ "10.0.12.0/24" ]``` | no |
| postgresql\_version | PostgreSQL server version | `string` | `"16"` | no |
| redis\_access\_keys\_authentication\_enabled | Whether to enable access key authentication for Redis | `bool` | `false` | no |
| redis\_clustering\_policy | Clustering policy for Redis cache (OSSCluster or EnterpriseCluster) | `string` | `"OSSCluster"` | no |
| redis\_should\_enable\_high\_availability | Whether to enable high availability for Redis cache | `bool` | `true` | no |
| redis\_sku\_name | SKU name for Azure Managed Redis cache | `string` | `"Balanced_B10"` | no |
| registry\_should\_enable\_public\_network\_access | Whether to enable public network access to the AzureML Registry | `bool` | `false` | no |
| resolver\_subnet\_address\_prefix | Address prefix for the Private Resolver subnet. Must be /28 or larger and not overlap with other subnets | `string` | `"10.0.9.0/28"` | no |
| resource\_group\_name | Existing resource group name containing foundational and ML resources (Otherwise 'rg-{resource\_prefix}-{environment}-{instance}') | `string` | `null` | no |
| should\_assign\_current\_user\_vm\_admin | Whether to assign the current Azure AD user the Virtual Machine Administrator Login role (sudo access). Requires Microsoft Graph provider permissions | `bool` | `true` | no |
| should\_create\_acr | Whether to create an Azure Container Registry for ML image storage | `bool` | `false` | no |
| should\_create\_aks\_cluster | Whether to create an AKS cluster for Azure ML compute integration | `bool` | `false` | no |
| should\_create\_aks\_identity | Whether to create a user-assigned identity for AKS cluster when using custom private DNS zones. | `bool` | `true` | no |
| should\_create\_compute\_cluster | Whether to create a compute cluster for ML training workloads | `bool` | `true` | no |
| should\_create\_ml\_workload\_identity | Whether to create a user-assigned managed identity for AzureML workload federation. | `bool` | `true` | no |
| should\_create\_networking | Whether to create virtual network and subnet for AKS and secure workspace integration | `bool` | `false` | no |
| should\_create\_observability | Whether to create observability component (Application Insights) when not already deployed | `bool` | `false` | no |
| should\_create\_security\_identity | Whether to create security + identity component (Key Vault, identities) when not already deployed | `bool` | `false` | no |
| should\_create\_storage | Whether to create cloud data component (storage account) when not already deployed | `bool` | `false` | no |
| should\_create\_vm\_host | Whether to create a VM host for GPU workloads, edge testing, or jump box access | `bool` | `false` | no |
| should\_create\_vm\_ssh\_key | Generate SSH key pair for VM fallback access. Defaults to true to ensure emergency access when Azure AD authentication is unavailable | `bool` | `true` | no |
| should\_deploy\_azureml\_registry | Whether to deploy AzureML Registry with private endpoint support | `bool` | `false` | no |
| should\_deploy\_edge\_extension | Whether to deploy the Azure ML edge extension on a connected cluster | `bool` | `false` | no |
| should\_deploy\_postgresql | Whether to deploy PostgreSQL Flexible Server component | `bool` | `false` | no |
| should\_deploy\_redis | Whether to deploy Azure Managed Redis component | `bool` | `false` | no |
| should\_disable\_aks\_local\_account | Whether to disable the local admin account for the AKS cluster | `bool` | `false` | no |
| should\_enable\_cluster\_inference | Whether to enable inference workloads on the AKS cluster | `bool` | `true` | no |
| should\_enable\_cluster\_training | Whether to enable training workloads on the AKS cluster | `bool` | `true` | no |
| should\_enable\_inference\_router\_ha | Whether to enable high availability for inference router | `bool` | `true` | no |
| should\_enable\_managed\_outbound\_access | Whether to enable managed outbound egress via NAT gateway instead of platform default internet access | `bool` | `true` | no |
| should\_enable\_private\_endpoints | Whether to enable private endpoints across Key Vault, Storage Account, and observability resources to support managed Prometheus ingestion. Requires networking to be created or existing | `bool` | `false` | no |
| should\_enable\_private\_resolver | Whether to enable Azure Private Resolver for VPN client DNS resolution of private endpoints. Only used when should\_enable\_vpn\_gateway is true | `bool` | `true` | no |
| should\_enable\_public\_network\_access | Whether to enable public network access to the Azure ML workspace | `bool` | `false` | no |
| should\_enable\_vpn\_gateway | Whether to create a VPN Gateway for secure access to private endpoints. Requires networking to be created or existing. | `bool` | `false` | no |
| should\_install\_azureml\_charts | Whether to install AzureML-specific charts. | `bool` | `false` | no |
| should\_install\_dcgm\_exporter | Whether to install DCGM exporter for GPU metrics collection in Azure ML extension | `bool` | `false` | no |
| should\_install\_nvidia\_device\_plugin | Whether to install NVIDIA Device Plugin for GPU hardware support in Azure ML extension | `bool` | `false` | no |
| should\_install\_prom\_op | Whether to install Prometheus operator for monitoring in Azure ML extension. Set to false if Azure Monitor is already enabled on AKS | `bool` | `false` | no |
| should\_install\_robotics\_charts | Whether to install robotics-specific charts (NVIDIA related charts). | `bool` | `false` | no |
| should\_install\_volcano | Whether to install Volcano scheduler for job scheduling in Azure ML extension | `bool` | `false` | no |
| should\_integrate\_aks\_cluster | Whether to integrate an AKS cluster as a compute target with the workspace | `bool` | `false` | no |
| should\_use\_current\_user\_key\_vault\_admin | Whether to give the current user the Key Vault Secrets Officer Role | `bool` | `true` | no |
| should\_use\_vm\_password\_auth | Use password authentication for VM access. When enabled, a random secure password will be generated and stored in Terraform state | `bool` | `false` | no |
| ssl\_cert\_pem | PEM-encoded TLS certificate chain (server first then intermediates) or empty when not using HTTPS | `string` | `null` | no |
| ssl\_cname | CNAME used for HTTPS endpoint; required when providing cert/key; otherwise empty | `string` | `null` | no |
| ssl\_key\_pem | PEM-encoded unencrypted private key matching ssl\_cert\_pem or empty when not using HTTPS | `string` | `null` | no |
| storage\_account\_name | Existing Storage Account name required for workspace deployment when not creating data component | `string` | `null` | no |
| subnet\_address\_prefixes\_acr | Address prefixes for the ACR subnet | `list(string)` | ```[ "10.0.3.0/24" ]``` | no |
| subnet\_address\_prefixes\_aks | Address prefixes for the AKS subnet. | `list(string)` | ```[ "10.0.5.0/24" ]``` | no |
| subnet\_address\_prefixes\_aks\_pod | Address prefixes for the AKS pod subnet. | `list(string)` | ```[ "10.0.6.0/24" ]``` | no |
| subnet\_name | Existing or desired subnet name (Otherwise 'snet-{resource\_prefix}-{environment}-{instance}') | `string` | `null` | no |
| system\_tolerations | Tolerations for AzureML extension system components to schedule on tainted nodes. Useful for dedicated GPU nodes or spot instances. Default: empty list (no tolerations). | ```list(object({ key = optional(string) operator = optional(string, "Exists") value = optional(string) effect = optional(string) }))``` | `[]` | no |
| virtual\_network\_config | Configuration for the virtual network including address space and subnet prefix | ```object({ address_space = string subnet_address_prefix = string })``` | ```{ "address_space": "10.0.0.0/16", "subnet_address_prefix": "10.0.1.0/24" }``` | no |
| virtual\_network\_name | Existing or desired virtual network name (Otherwise 'vnet-{resource\_prefix}-{environment}-{instance}') | `string` | `null` | no |
| vm\_admin\_principals | Map of Azure AD principals for Virtual Machine Administrator Login role (sudo access). Keys are descriptive identifiers (e.g., `user@company.com`), values are principal object IDs. | `map(string)` | `{}` | no |
| vm\_eviction\_policy | Eviction policy for Spot VMs: Deallocate (recommended - VM stopped, can restart later) or Delete (VM and disks removed). Only applies when vm\_priority is Spot | `string` | `"Deallocate"` | no |
| vm\_host\_count | Number of VM hosts to create for multi-node scenarios | `number` | `1` | no |
| vm\_max\_bid\_price | Maximum hourly price in USD for Spot VM. Set to -1 (recommended) to pay current spot price without price-based eviction. Custom values support up to 5 decimal places. Only applies when vm\_priority is Spot | `number` | `-1` | no |
| vm\_priority | VM priority: Regular (production, guaranteed capacity) or Spot (cost-optimized, up to 90% savings, can be evicted). Recommended: Spot for dev/test GPU workloads | `string` | `"Regular"` | no |
| vm\_sku\_size | VM SKU size for the host. Examples: Standard\_D8s\_v3 (general purpose), Standard\_NV36ads\_A10\_v5 (GPU workload) | `string` | `"Standard_D8s_v3"` | no |
| vm\_user\_principals | Map of Azure AD principals for Virtual Machine User Login role (standard access). Keys are descriptive identifiers (e.g., `user@company.com`), values are principal object IDs. | `map(string)` | `{}` | no |
| vpn\_gateway\_azure\_ad\_config | Azure AD configuration for VPN Gateway authentication. tenant\_id is required when vpn\_gateway\_should\_use\_azure\_ad\_auth is true. audience defaults to Microsoft-registered app. issuer will default to `https://sts.windows.net/{tenant_id}/` when not provided | ```object({ tenant_id = optional(string) audience = optional(string, "c632b3df-fb67-4d84-bdcf-b95ad541b5c8") issuer = optional(string) })``` | `{}` | no |
| vpn\_gateway\_config | VPN Gateway configuration including SKU, generation, client address pool, and supported protocols | ```object({ sku = optional(string, "VpnGw1") generation = optional(string, "Generation1") client_address_pool = optional(list(string), ["192.168.200.0/24"]) protocols = optional(list(string), ["OpenVPN", "IkeV2"]) })``` | `{}` | no |
| vpn\_gateway\_should\_generate\_ca | Whether to generate a new CA certificate. When false, uses existing certificate from Key Vault | `bool` | `true` | no |
| vpn\_gateway\_should\_use\_azure\_ad\_auth | Whether to use Azure AD authentication for VPN Gateway. When true, uses Azure AD authentication. When false, uses certificate authentication | `bool` | `true` | no |
| vpn\_gateway\_subnet\_address\_prefixes | Address prefixes for the GatewaySubnet. Must be /27 or larger | `list(string)` | ```[ "10.0.2.0/27" ]``` | no |
| vpn\_site\_connections | Site-to-site VPN site definitions for on-premises connectivity. Ensure address spaces do not overlap with Azure virtual networks | ```list(object({ name = string address_spaces = list(string) shared_key_reference = string connection_mode = optional(string, "Default") dpd_timeout_seconds = optional(number) gateway_fqdn = optional(string) gateway_ip_address = optional(string) ike_protocol = optional(string, "IKEv2") use_policy_based_selectors = optional(bool, false) bgp_settings = optional(object({ asn = number peer_address = string peer_weight = optional(number) })) ipsec_policy = optional(object({ dh_group = string ike_encryption = string ike_integrity = string ipsec_encryption = string ipsec_integrity = string pfs_group = string sa_datasize_kb = optional(number) sa_lifetime_seconds = optional(number) })) }))``` | `[]` | no |
| vpn\_site\_default\_ipsec\_policy | Fallback IPsec policy applied when vpn\_site\_connections omit ipsec\_policy overrides | ```object({ dh_group = string ike_encryption = string ike_integrity = string ipsec_encryption = string ipsec_integrity = string pfs_group = string sa_datasize_kb = optional(number) sa_lifetime_seconds = optional(number) })``` | `null` | no |
| vpn\_site\_shared\_keys | Pre-shared keys keyed by shared\_key\_reference for site-to-site connections. Retrieve values from secure secret stores | `map(string)` | `{}` | no |
| workload\_tolerations | Tolerations for AzureML workloads (training and inference) to schedule on tainted nodes. Essential for GPU node pools with taints like 'sku=gpu:NoSchedule' or spot instances. Default: empty list (no tolerations). | ```list(object({ key = optional(string) operator = optional(string, "Exists") value = optional(string) effect = optional(string) }))``` | `[]` | no |
| workspace\_friendly\_name | Friendly display name for the workspace. (Default, {var.resource\_prefix}-{var.environment}-{var.instance} ML Workspace) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| acr\_network\_posture | Azure Container Registry network posture metadata. |
| aks\_cluster | The AKS cluster object when created or discovered for ML integration. |
| aks\_oidc\_issuer\_url | The OIDC issuer URL for the AKS cluster when workload identity is enabled. |
| application\_insights | Application Insights object used for the workspace. |
| arc\_connected\_cluster\_id | The Arc connected cluster id when created or discovered for edge ML scenarios. |
| azureml\_edge\_extension | The Azure ML edge extension deployment object when deployed. |
| azureml\_workspace | The Azure ML workspace object when created or discovered. |
| key\_vault | Key Vault object used for the workspace. |
| managed\_redis | Azure Managed Redis cache object. |
| managed\_redis\_connection\_info | Azure Managed Redis connection information. |
| nat\_gateway | The NAT gateway resource used for managed outbound access when networking is created. |
| nat\_gateway\_public\_ips | Public IP resources associated with the NAT gateway when managed outbound access is enabled. |
| postgresql\_connection\_info | PostgreSQL connection information. |
| postgresql\_databases | Map of PostgreSQL databases. |
| postgresql\_server | PostgreSQL Flexible Server object. |
| private\_resolver\_dns\_ip | Private Resolver DNS IP address for VPN client configuration. |
| resource\_group | The resource group object for the deployment. |
| storage\_account | Storage Account object used for the workspace. |
| virtual\_network | The virtual network object when created. |
| vm\_host\_private\_ips | Private IP addresses of VM hosts for VPN/internal access. |
| vm\_host\_public\_ips | Public IP addresses of VM hosts. |
| vm\_host\_ssh\_command | Azure AD SSH command to connect to the first VM host. |
| vm\_host\_ssh\_private\_key\_path | Path to SSH private key for VM host access. |
| vpn\_client\_connection\_info | VPN client connection information including download URLs. |
| vpn\_gateway | VPN Gateway configuration when enabled. |
| vpn\_gateway\_public\_ip | VPN Gateway public IP address for client configuration. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
