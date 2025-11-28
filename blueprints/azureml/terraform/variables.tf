/*
 * Azure ML Blueprint Variables
 *
 * This blueprint wraps the robotics module with AzureML-specific defaults.
 * All variables are passed through to the underlying robotics module.
 *
 * See blueprints/modules/robotics/terraform/README.md for complete module documentation.
 */

/*
 *  Core Variables - Required
 */

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
  default     = "001"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
}

/*
 *  Foundational Creation Flags - Optional
 */

variable "should_create_acr" {
  type        = bool
  description = "Whether to create an Azure Container Registry for ML image storage"
  default     = false
}

variable "should_create_aks_cluster" {
  type        = bool
  description = "Whether to create an AKS cluster for Azure ML compute integration"
  default     = false
}

variable "should_create_networking" {
  type        = bool
  description = "Whether to create virtual network and subnet for AKS and secure workspace integration"
  default     = false
}

/*
 *  Foundational Resource Name Overrides - Optional
 */

variable "acr_name" {
  type        = string
  description = "Existing or desired ACR name when not creating (Otherwise computed)"
  default     = null
}

variable "subnet_name" {
  type        = string
  description = "Existing or desired subnet name (Otherwise 'snet-{resource_prefix}-{environment}-{instance}')"
  default     = null
}

variable "virtual_network_name" {
  type        = string
  description = "Existing or desired virtual network name (Otherwise 'vnet-{resource_prefix}-{environment}-{instance}')"
  default     = null
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name containing foundational and ML resources (Otherwise 'rg-{resource_prefix}-{environment}-{instance}')"
  default     = null
}

variable "aks_cluster_name" {
  type        = string
  description = "Existing AKS cluster name for ML integration (Otherwise 'aks-{resource_prefix}-{environment}-{instance}')"
  default     = null
}

variable "arc_connected_cluster_name" {
  type        = string
  description = "Existing Arc connected cluster name for edge ML scenarios (Otherwise 'arck-{resource_prefix}-{environment}-{instance}')"
  default     = null
}

/*
 *  AKS Cluster Configuration - Optional
 */

variable "should_create_aks_identity" {
  description = "Whether to create a user-assigned identity for AKS cluster when using custom private DNS zones."
  type        = bool
  default     = true
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix for the AKS cluster. This is used to create a unique DNS name for the cluster. If not provided, a default value will be generated."
  default     = null
}

variable "node_count" {
  type        = number
  description = "Number of nodes for the agent pool in the AKS cluster."
  default     = 1
}

variable "node_vm_size" {
  type        = string
  description = "VM size for the agent pool in the AKS cluster. Default is Standard_D8ds_v5."
  default     = "Standard_D8ds_v5"
}

variable "subnet_address_prefixes_aks" {
  type        = list(string)
  description = "Address prefixes for the AKS subnet."
  default     = ["10.0.5.0/24"]
}

variable "subnet_address_prefixes_aks_pod" {
  type        = list(string)
  description = "Address prefixes for the AKS pod subnet."
  default     = ["10.0.6.0/24"]
}

variable "enable_auto_scaling" {
  type        = bool
  description = "Should enable auto-scaler for the default node pool."
  default     = false
}

variable "min_count" {
  type        = number
  description = "The minimum number of nodes which should exist in the default node pool. Valid values are between 0 and 1000."
  default     = null
}

variable "max_count" {
  type        = number
  description = "The maximum number of nodes which should exist in the default node pool. Valid values are between 0 and 1000."
  default     = null
}

variable "node_pools" {
  type = map(object({
    node_count                  = optional(number, null)
    vm_size                     = string
    subnet_address_prefixes     = list(string)
    pod_subnet_address_prefixes = list(string)
    node_taints                 = optional(list(string), [])
    enable_auto_scaling         = optional(bool, false)
    min_count                   = optional(number, null)
    max_count                   = optional(number, null)
    priority                    = optional(string, "Regular")
    zones                       = optional(list(string), null)
    eviction_policy             = optional(string, "Deallocate")
    gpu_driver                  = optional(string, null)
  }))
  description = "Additional node pools for the AKS cluster. Map key is used as the node pool name."
  default     = {}
}

variable "should_disable_aks_local_account" {
  type        = bool
  description = "Whether to disable the local admin account for the AKS cluster"
  default     = false
}

/*
 *  Scenario Selection Flags - Optional
 */

variable "should_deploy_edge_extension" {
  type        = bool
  description = "Whether to deploy the Azure ML edge extension on a connected cluster"
  default     = false
}

variable "should_integrate_aks_cluster" {
  type        = bool
  description = "Whether to integrate an AKS cluster as a compute target with the workspace"
  default     = false
}

/*
 *  Azure ML Workspace Configuration - Optional
 */

variable "azureml_workspace_name" {
  type        = string
  description = "Existing or desired Azure ML workspace name (Otherwise 'mlw-{resource_prefix}-{environment}-{instance}')"
  default     = null
}

/*
 *  Public Network Access Configuration - Optional
 */

variable "should_enable_public_network_access" {
  type        = bool
  description = "Whether to enable public network access to the Azure ML workspace"
  default     = false
}

/*
 *  Optional Supporting Components - Optional
 */

variable "should_create_security_identity" {
  type        = bool
  description = "Whether to create security + identity component (Key Vault, identities) when not already deployed"
  default     = false
}

variable "should_create_ml_workload_identity" {
  type        = bool
  description = "Whether to create a user-assigned managed identity for AzureML workload federation."
  default     = true
}

variable "should_create_observability" {
  type        = bool
  description = "Whether to create observability component (Application Insights) when not already deployed"
  default     = false
}

variable "key_vault_name" {
  type        = string
  description = "Existing or desired Key Vault name (Otherwise 'kv-{resource_prefix}-{environment}-{instance}')"
  default     = null
}

variable "application_insights_name" {
  type        = string
  description = "Existing or desired Application Insights name (Otherwise 'appi-{resource_prefix}-{environment}-{instance}')"
  default     = null
}

variable "storage_account_name" {
  type        = string
  description = "Existing Storage Account name required for workspace deployment when not creating data component"
  default     = null
}

variable "should_create_storage" {
  type        = bool
  description = "Whether to create cloud data component (storage account) when not already deployed"
  default     = false
}

/*
 * PostgreSQL Configuration
 */

variable "should_deploy_postgresql" {
  type        = bool
  description = "Whether to deploy PostgreSQL Flexible Server component"
  default     = false
}

variable "postgresql_admin_password" {
  type        = string
  description = "Administrator password for PostgreSQL server. (Otherwise, generated when postgresql_should_generate_admin_password is true)."
  sensitive   = true
  default     = null
}

variable "postgresql_should_generate_admin_password" {
  type        = bool
  description = "Whether to auto-generate PostgreSQL admin password."
  default     = true
}

variable "postgresql_should_store_credentials_in_key_vault" {
  type        = bool
  description = "Whether to store PostgreSQL admin credentials in Key Vault."
  default     = true
}

variable "postgresql_admin_username" {
  type        = string
  description = "Administrator username for PostgreSQL server"
  default     = "pgadmin"
}

variable "postgresql_databases" {
  type = map(object({
    collation = string
    charset   = string
  }))
  description = "Map of databases to create with collation and charset"
  default     = null
}

variable "postgresql_delegated_subnet_id" {
  type        = string
  description = "Subnet ID with delegation to Microsoft.DBforPostgreSQL/flexibleServers"
  default     = null
}

variable "postgresql_should_enable_geo_redundant_backup" {
  type        = bool
  description = "Whether to enable geo-redundant backups for PostgreSQL"
  default     = false
}

variable "postgresql_should_enable_extensions" {
  type        = bool
  description = "Whether to enable PostgreSQL extensions via azure.extensions"
  default     = true
}

variable "postgresql_should_enable_timescaledb" {
  type        = bool
  description = "Whether to enable TimescaleDB extension for PostgreSQL"
  default     = true
}

variable "postgresql_sku_name" {
  type        = string
  description = "SKU name for PostgreSQL server"
  default     = "GP_Standard_D2s_v3"
}

variable "postgresql_storage_mb" {
  type        = number
  description = "Storage size in megabytes for PostgreSQL"
  default     = 32768
}

variable "postgresql_version" {
  type        = string
  description = "PostgreSQL server version"
  default     = "16"
}

/*
 * Azure Managed Redis Configuration - Optional
 */

variable "should_deploy_redis" {
  type        = bool
  description = "Whether to deploy Azure Managed Redis component"
  default     = false
}

variable "redis_sku_name" {
  type        = string
  description = "SKU name for Azure Managed Redis cache"
  default     = "Balanced_B10"
}

variable "redis_should_enable_high_availability" {
  type        = bool
  description = "Whether to enable high availability for Redis cache"
  default     = true
}

variable "redis_clustering_policy" {
  type        = string
  description = "Clustering policy for Redis cache (OSSCluster or EnterpriseCluster)"
  default     = "OSSCluster"

  validation {
    condition     = contains(["OSSCluster", "EnterpriseCluster"], var.redis_clustering_policy)
    error_message = "Clustering policy must be either OSSCluster or EnterpriseCluster."
  }
}

/*
 *  Azure ML Workspace Additional Configuration - Optional
 */

variable "workspace_friendly_name" {
  type        = string
  description = "Friendly display name for the workspace. (Default, {var.resource_prefix}-{var.environment}-{var.instance} ML Workspace)"
  default     = null
}

/*
 * Registry Configuration - Optional
 */

variable "should_deploy_azureml_registry" {
  type        = bool
  description = "Whether to deploy AzureML Registry with private endpoint support"
  default     = false
}

variable "registry_should_enable_public_network_access" {
  type        = bool
  description = "Whether to enable public network access to the AzureML Registry"
  default     = false
}

variable "should_create_compute_cluster" {
  type        = bool
  description = "Whether to create a compute cluster for ML training workloads"
  default     = true
}

variable "ml_workload_subjects" {
  type        = list(string)
  description = "Custom Kubernetes service account subjects for AzureML workload federation. Example: ['system:serviceaccount:azureml:azureml-workload', 'system:serviceaccount:osmo:osmo-workload']"
  default = [
    "system:serviceaccount:azureml:azureml-workload",
    "system:serviceaccount:osmo:osmo-workload",
  ]
}

variable "compute_cluster_name" {
  type        = string
  description = "Name of the compute cluster for ML training workloads. Otherwise, 'cluster-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "compute_cluster_idle_duration" {
  type        = string
  description = "Time to wait before scaling down idle nodes. Format: PT{minutes}M (e.g., PT15M for 30 minutes)"
  default     = "PT30M"
}

variable "compute_cluster_max_nodes" {
  type        = number
  description = "Maximum number of nodes in compute cluster for auto-scaling. Default: 1 (cost-optimized for single-model training)"
  default     = 1
  validation {
    condition     = var.compute_cluster_max_nodes >= 1
    error_message = "Maximum node count must be at least 1."
  }
}

variable "compute_cluster_min_nodes" {
  type        = number
  description = "Minimum number of nodes in compute cluster for auto-scaling. Default: 0 (cost-optimized, scales to zero when idle)"
  default     = 0
  validation {
    condition     = var.compute_cluster_min_nodes >= 0 && var.compute_cluster_min_nodes <= var.compute_cluster_max_nodes
    error_message = "Minimum node count must be greater than or equal to 0 and less than or equal to compute_cluster_max_nodes."
  }
}

variable "compute_cluster_vm_priority" {
  type        = string
  description = "VM priority for compute cluster nodes: Dedicated (production, higher cost) or LowPriority (development, 60-80% cost savings but can be preempted)"
  default     = "Dedicated"
  validation {
    condition     = contains(["Dedicated", "LowPriority"], var.compute_cluster_vm_priority)
    error_message = "VM priority must be either 'Dedicated' or 'LowPriority'."
  }
}

variable "compute_cluster_vm_size" {
  type        = string
  description = "VM size for compute cluster nodes. Standard_DS3_v2 (4 vCPUs, 14 GiB RAM) recommended for balanced production ML workloads"
  default     = "Standard_DS3_v2"
}

/*
 *  Component-Specific Configuration Variables - Optional
 */

variable "virtual_network_config" {
  type = object({
    address_space         = string
    subnet_address_prefix = string
  })
  description = "Configuration for the virtual network including address space and subnet prefix"
  default = {
    address_space         = "10.0.0.0/16"
    subnet_address_prefix = "10.0.1.0/24"
  }
  validation {
    condition     = can(cidrhost(var.virtual_network_config.address_space, 0)) && can(cidrhost(var.virtual_network_config.subnet_address_prefix, 0))
    error_message = "Both address_space and subnet_address_prefix must be valid CIDR blocks."
  }
}

variable "should_enable_private_endpoints" {
  type        = bool
  description = "Whether to enable private endpoints across Key Vault, Storage Account, and observability resources to support managed Prometheus ingestion. Requires networking to be created or existing"
  default     = false
}

/*
 * Outbound Access Configuration
 */

variable "should_enable_managed_outbound_access" {
  type        = bool
  description = "Whether to enable managed outbound egress via NAT gateway instead of platform default internet access"
  default     = true
}

variable "nat_gateway_idle_timeout_minutes" {
  type        = number
  description = "Idle timeout in minutes for NAT gateway connections"
  default     = 4
  validation {
    condition     = var.nat_gateway_idle_timeout_minutes >= 4 && var.nat_gateway_idle_timeout_minutes <= 240
    error_message = "Idle timeout must be between 4 and 240 minutes"
  }
}

variable "nat_gateway_public_ip_count" {
  type        = number
  description = "Number of public IP addresses to associate with the NAT gateway (example: 2)"
  default     = 1
  validation {
    condition     = var.nat_gateway_public_ip_count >= 1 && var.nat_gateway_public_ip_count <= 16
    error_message = "Public IP count must be between 1 and 16"
  }
}

variable "nat_gateway_zones" {
  type        = list(string)
  description = "Availability zones for NAT gateway resources when zone-redundancy is required (example: ['1','2'])"
  default     = []
}

/*
 * AKS Private Cluster Configuration - Optional
 */

variable "aks_should_enable_private_cluster" {
  type        = bool
  description = "Whether to enable private cluster for AKS"
  default     = false
}

variable "aks_should_enable_private_cluster_public_fqdn" {
  type        = bool
  description = "Whether to create a FQDN for private cluster (sets enable_private_cluster_public_fqdn)"
  default     = false
}

variable "aks_private_dns_zone_id" {
  type        = string
  description = "ID of the private DNS zone to use for AKS private cluster. If not provided, a new zone will be created"
  default     = null
}

/*
 * VPN Gateway Configuration - Optional
 */

variable "should_enable_vpn_gateway" {
  type        = bool
  description = "Whether to create a VPN Gateway for secure access to private endpoints. Requires networking to be created or existing."
  default     = false
}

variable "vpn_gateway_config" {
  type = object({
    sku                 = optional(string, "VpnGw1")
    generation          = optional(string, "Generation1")
    client_address_pool = optional(list(string), ["192.168.200.0/24"])
    protocols           = optional(list(string), ["OpenVPN", "IkeV2"])
  })
  description = "VPN Gateway configuration including SKU, generation, client address pool, and supported protocols"
  default     = {}
}

variable "vpn_gateway_subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the GatewaySubnet. Must be /27 or larger"
  default     = ["10.0.2.0/27"]
}

variable "vpn_site_connections" {
  type = list(object({
    name                       = string
    address_spaces             = list(string)
    shared_key_reference       = string
    connection_mode            = optional(string, "Default")
    dpd_timeout_seconds        = optional(number)
    gateway_fqdn               = optional(string)
    gateway_ip_address         = optional(string)
    ike_protocol               = optional(string, "IKEv2")
    use_policy_based_selectors = optional(bool, false)
    bgp_settings = optional(object({
      asn          = number
      peer_address = string
      peer_weight  = optional(number)
    }))
    ipsec_policy = optional(object({
      dh_group            = string
      ike_encryption      = string
      ike_integrity       = string
      ipsec_encryption    = string
      ipsec_integrity     = string
      pfs_group           = string
      sa_datasize_kb      = optional(number)
      sa_lifetime_seconds = optional(number)
    }))
  }))
  description = "Site-to-site VPN site definitions for on-premises connectivity. Ensure address spaces do not overlap with Azure virtual networks"
  default     = []
}

variable "vpn_site_default_ipsec_policy" {
  type = object({
    dh_group            = string
    ike_encryption      = string
    ike_integrity       = string
    ipsec_encryption    = string
    ipsec_integrity     = string
    pfs_group           = string
    sa_datasize_kb      = optional(number)
    sa_lifetime_seconds = optional(number)
  })
  description = "Fallback IPsec policy applied when vpn_site_connections omit ipsec_policy overrides"
  default     = null
}

variable "vpn_site_shared_keys" {
  type        = map(string)
  description = "Pre-shared keys keyed by shared_key_reference for site-to-site connections. Retrieve values from secure secret stores"
  default     = {}
  sensitive   = true
}

variable "vpn_gateway_should_use_azure_ad_auth" {
  type        = bool
  description = "Whether to use Azure AD authentication for VPN Gateway. When true, uses Azure AD authentication. When false, uses certificate authentication"
  default     = true
}

variable "vpn_gateway_azure_ad_config" {
  type = object({
    tenant_id = optional(string)
    audience  = optional(string, "c632b3df-fb67-4d84-bdcf-b95ad541b5c8")
    issuer    = optional(string)
  })
  description = "Azure AD configuration for VPN Gateway authentication. tenant_id is required when vpn_gateway_should_use_azure_ad_auth is true. audience defaults to Microsoft-registered app. issuer will default to `https://sts.windows.net/{tenant_id}/` when not provided"
  default     = {}
}

variable "vpn_gateway_should_generate_ca" {
  type        = bool
  description = "Whether to generate a new CA certificate. When false, uses existing certificate from Key Vault"
  default     = true
}

variable "existing_certificate_name" {
  type        = string
  description = "Name of existing certificate in Key Vault when vpn_gateway_should_generate_ca is false"
  default     = null
}

variable "should_enable_private_resolver" {
  type        = bool
  description = "Whether to enable Azure Private Resolver for VPN client DNS resolution of private endpoints. Only used when should_enable_vpn_gateway is true"
  default     = true
}

variable "resolver_subnet_address_prefix" {
  type        = string
  description = "Address prefix for the Private Resolver subnet. Must be /28 or larger and not overlap with other subnets"
  default     = "10.0.9.0/28"
  validation {
    condition     = can(cidrhost(var.resolver_subnet_address_prefix, 0))
    error_message = "The resolver_subnet_address_prefix must be a valid CIDR block."
  }
}

variable "certificate_validity_days" {
  type        = number
  description = "Validity period in days for auto-generated certificates"
  default     = 365
}

variable "certificate_subject" {
  type = object({
    common_name         = optional(string, "Azure ML VPN Gateway Root Certificate")
    organization        = optional(string, "Edge AI Accelerator")
    organizational_unit = optional(string, "IT")
    country             = optional(string, "US")
    province            = optional(string, "WA")
    locality            = optional(string, "Redmond")
  })
  description = "Certificate subject information for auto-generated certificates"
  default     = {}
}

variable "acr_sku" {
  type        = string
  description = "SKU name for the Azure Container Registry"
  default     = "Premium"
}

variable "subnet_address_prefixes_acr" {
  type        = list(string)
  description = "Address prefixes for the ACR subnet"
  default     = ["10.0.3.0/24"]
}

/*
 * ACR Network Posture Controls - Optional
 */

variable "acr_allow_trusted_services" {
  type        = bool
  description = "Whether trusted Azure services can bypass ACR network rules"
  default     = true
}

variable "acr_allowed_public_ip_ranges" {
  type        = list(string)
  description = "CIDR ranges permitted to reach the ACR public endpoint"
  default     = []
}

variable "acr_data_endpoint_enabled" {
  type        = bool
  description = "Whether to enable the dedicated ACR data endpoint"
  default     = true
}

variable "acr_public_network_access_enabled" {
  type        = bool
  description = "Whether to enable the ACR public endpoint alongside private connectivity"
  default     = false
}

/*
 * VM Host Configuration - Optional
 */

variable "should_create_vm_host" {
  type        = bool
  description = "Whether to create a VM host for GPU workloads, edge testing, or jump box access"
  default     = false
}

variable "vm_host_count" {
  type        = number
  description = "Number of VM hosts to create for multi-node scenarios"
  default     = 1
  validation {
    condition     = var.vm_host_count >= 1
    error_message = "VM host count must be at least 1."
  }
}

variable "vm_sku_size" {
  type        = string
  description = "VM SKU size for the host. Examples: Standard_D8s_v3 (general purpose), Standard_NV36ads_A10_v5 (GPU workload)"
  default     = "Standard_D8s_v3"
}

variable "vm_priority" {
  type        = string
  description = "VM priority: Regular (production, guaranteed capacity) or Spot (cost-optimized, up to 90% savings, can be evicted). Recommended: Spot for dev/test GPU workloads"
  default     = "Regular"
  validation {
    condition     = contains(["Regular", "Spot"], var.vm_priority)
    error_message = "VM priority must be either 'Regular' or 'Spot'."
  }
}

variable "vm_eviction_policy" {
  type        = string
  description = "Eviction policy for Spot VMs: Deallocate (recommended - VM stopped, can restart later) or Delete (VM and disks removed). Only applies when vm_priority is Spot"
  default     = "Deallocate"
  validation {
    condition     = contains(["Deallocate", "Delete"], var.vm_eviction_policy)
    error_message = "Eviction policy must be either 'Deallocate' or 'Delete'."
  }
}

variable "vm_max_bid_price" {
  type        = number
  description = "Maximum hourly price in USD for Spot VM. Set to -1 (recommended) to pay current spot price without price-based eviction. Custom values support up to 5 decimal places. Only applies when vm_priority is Spot"
  default     = -1
  validation {
    condition     = var.vm_max_bid_price == -1 || var.vm_max_bid_price > 0
    error_message = "Max bid price must be -1 or a positive number."
  }
}

variable "should_assign_current_user_vm_admin" {
  type        = bool
  description = "Whether to assign the current Azure AD user the Virtual Machine Administrator Login role (sudo access). Requires Microsoft Graph provider permissions"
  default     = true
}

variable "vm_admin_principals" {
  type        = map(string)
  description = "Map of Azure AD principals for Virtual Machine Administrator Login role (sudo access). Keys are descriptive identifiers (e.g., `user@company.com`), values are principal object IDs."
  default     = {}
}

variable "vm_user_principals" {
  type        = map(string)
  description = "Map of Azure AD principals for Virtual Machine User Login role (standard access). Keys are descriptive identifiers (e.g., `user@company.com`), values are principal object IDs."
  default     = {}
}

variable "should_create_vm_ssh_key" {
  type        = bool
  description = "Generate SSH key pair for VM fallback access. Defaults to true to ensure emergency access when Azure AD authentication is unavailable"
  default     = true
}

variable "should_use_vm_password_auth" {
  type        = bool
  description = "Use password authentication for VM access. When enabled, a random secure password will be generated and stored in Terraform state"
  default     = false
}

/*
 *  AKS Integration Configuration - Optional
 */

variable "extension_name" {
  type        = string
  description = "Name of the Azure ML extension for AKS cluster. Otherwise, 'azureml-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "aks_compute_target_name" {
  type        = string
  description = "Name of the AKS compute target in ML workspace. Otherwise, 'aks-compute-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "arc_compute_target_name" {
  type        = string
  description = "Name of the Arc compute target in ML workspace. Otherwise, 'arck-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "arc_cluster_purpose" {
  type        = string
  description = "Purpose of Arc cluster: DevTest, DenseProd, or FastProd"
  default     = "DevTest"
}

variable "should_enable_cluster_training" {
  type        = bool
  description = "Whether to enable training workloads on the AKS cluster"
  default     = true
}

variable "should_enable_cluster_inference" {
  type        = bool
  description = "Whether to enable inference workloads on the AKS cluster"
  default     = true
}

variable "should_enable_inference_router_ha" {
  type        = bool
  description = "Whether to enable high availability for inference router"
  default     = true
}

variable "inference_router_service_type" {
  type        = string
  description = "Service type for inference router: LoadBalancer, NodePort, or ClusterIP"
  default     = "NodePort"
  validation {
    condition     = contains(["LoadBalancer", "NodePort", "ClusterIP"], var.inference_router_service_type)
    error_message = "Inference router service type must be LoadBalancer, NodePort, or ClusterIP."
  }
}



variable "should_install_dcgm_exporter" {
  type        = bool
  description = "Whether to install DCGM exporter for GPU metrics collection in Azure ML extension"
  default     = false
}

variable "should_install_nvidia_device_plugin" {
  type        = bool
  description = "Whether to install NVIDIA Device Plugin for GPU hardware support in Azure ML extension"
  default     = false
}

variable "should_install_prom_op" {
  type        = bool
  description = "Whether to install Prometheus operator for monitoring in Azure ML extension. Set to false if Azure Monitor is already enabled on AKS"
  default     = false
}

variable "should_install_volcano" {
  type        = bool
  description = "Whether to install Volcano scheduler for job scheduling in Azure ML extension"
  default     = false
}

variable "aks_cluster_purpose" {
  type        = string
  description = "Purpose of AKS cluster: DevTest, DenseProd, or FastProd"
  default     = "DevTest"
  validation {
    condition     = contains(["DevTest", "DenseProd", "FastProd"], var.aks_cluster_purpose)
    error_message = "AKS cluster purpose must be DevTest, DenseProd, or FastProd."
  }
}

/*
 * App Configuration Extension Configuration - Optional
 */

/*
 *  SSL/TLS Configuration - Optional
 */

variable "ssl_cname" {
  type        = string
  description = "CNAME used for HTTPS endpoint; required when providing cert/key; otherwise empty"
  default     = null
}

variable "ssl_cert_pem" {
  type        = string
  description = "PEM-encoded TLS certificate chain (server first then intermediates) or empty when not using HTTPS"
  default     = null
  sensitive   = true
}

variable "ssl_key_pem" {
  type        = string
  description = "PEM-encoded unencrypted private key matching ssl_cert_pem or empty when not using HTTPS"
  default     = null
  sensitive   = true
}

/*
 * AzureML Extension Toleration Configuration - Optional
 */

variable "system_tolerations" {
  type = list(object({
    key      = optional(string)
    operator = optional(string, "Exists")
    value    = optional(string)
    effect   = optional(string)
  }))
  description = "Tolerations for AzureML extension system components to schedule on tainted nodes. Useful for dedicated GPU nodes or spot instances. Default: empty list (no tolerations)."
  default     = []
}

variable "workload_tolerations" {
  type = list(object({
    key      = optional(string)
    operator = optional(string, "Exists")
    value    = optional(string)
    effect   = optional(string)
  }))
  description = "Tolerations for AzureML workloads (training and inference) to schedule on tainted nodes. Essential for GPU node pools with taints like 'sku=gpu:NoSchedule' or spot instances. Default: empty list (no tolerations)."
  default     = []
}

/*
 * Kubernetes Compute Configuration - Optional
 */

variable "cluster_integration_description" {
  type        = string
  description = "Description for the AKS integration compute target. Otherwise, 'Azure ML AKS compute target for {resource_prefix}-{environment}-{instance}'."
  default     = null
}

variable "cluster_integration_disable_local_auth" {
  type        = bool
  description = "Whether to disable local authentication for the AKS integration compute target."
  default     = true
}

variable "cluster_integration_default_instance_type" {
  type        = string
  description = "Default instance type for the Kubernetes compute."
  default     = "defaultinstancetype"
}

variable "cluster_integration_instance_types" {
  type = map(object({
    nodeSelector = optional(map(string))
    resources = optional(object({
      requests = optional(map(any))
      limits   = optional(map(any))
    }))
  }))
  description = "Instance types configuration for Kubernetes compute. Key is the instance type name, value contains nodeSelector and resource specifications."
  default     = null
}


/*
 * Chart Installation Configuration - Optional
 */

variable "should_install_charts" {
  type        = bool
  description = "Whether to install charts via AKS command invoke."
  default     = false
}





