/*
 * Core Variables - Required
 */

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
}

/*
 * Core Variables - Optional
 */

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
  default     = "001"
}

/*
 * Infrastructure Creation Flags - Optional
 */

variable "should_create_networking" {
  type        = bool
  description = "Whether to create virtual network for robotics infrastructure"
  default     = true
}

variable "should_create_aks_cluster" {
  type        = bool
  description = "Whether to create AKS cluster for robotics workloads"
  default     = true
}

variable "should_create_acr" {
  type        = bool
  description = "Whether to create Azure Container Registry for robotics images"
  default     = true
}

variable "should_create_security_identity" {
  type        = bool
  description = "Whether to create security and identity resources"
  default     = true
}

variable "should_use_current_user_key_vault_admin" {
  type        = bool
  description = "Whether to give the current user the Key Vault Secrets Officer Role"
  default     = true
}

variable "should_create_observability" {
  type        = bool
  description = "Whether to create observability resources"
  default     = true
}

variable "should_create_storage" {
  type        = bool
  description = "Whether to create storage resources"
  default     = true
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
  description = "Subnet ID with delegation to Microsoft.DBforPostgreSQL/flexibleServers. (Otherwise, created when should_create_networking is true)."
  default     = null
}

variable "postgresql_subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the PostgreSQL delegated subnet."
  default     = ["10.0.12.0/24"]
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

variable "redis_access_keys_authentication_enabled" {
  type        = bool
  description = "Whether to enable access key authentication for Redis. Set to true to use access keys (not recommended for production)"
  default     = false
}

variable "should_create_ml_workload_identity" {
  type        = bool
  description = "Whether to create user-assigned managed identity for AzureML workload federation"
  default     = true
}

variable "should_create_compute_cluster" {
  type        = bool
  description = "Whether to create compute cluster for ML training workloads"
  default     = true
}

/*
 * Compute Cluster Configuration - Optional
 */

variable "compute_cluster_vm_priority" {
  type        = string
  description = "VM priority for compute cluster: Dedicated or LowPriority"
  default     = "Dedicated"
}

variable "compute_cluster_min_nodes" {
  type        = number
  description = "Minimum number of nodes in compute cluster"
  default     = 0
}

variable "compute_cluster_max_nodes" {
  type        = number
  description = "Maximum number of nodes in compute cluster"
  default     = 1
}

/*
 * Chart Installation Configuration - Optional
 */

variable "should_install_robotics_charts" {
  type        = bool
  description = "Whether to install robotics charts (NVIDIA related)"
  default     = true
}

variable "should_install_azureml_charts" {
  type        = bool
  description = "Whether to install AzureML charts"
  default     = false
}

/*
 * Resource Name Overrides - Optional
 */

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name containing foundational and ML resources (Otherwise 'rg-{resource_prefix}-{environment}-{instance}')"
  default     = null
}

variable "virtual_network_name" {
  type        = string
  description = "Existing or desired virtual network name (Otherwise 'vnet-{resource_prefix}-{environment}-{instance}')"
  default     = null
}

variable "aks_cluster_name" {
  type        = string
  description = "Existing AKS cluster name for ML integration (Otherwise 'aks-{resource_prefix}-{environment}-{instance}')"
  default     = null
}

variable "azureml_workspace_name" {
  type        = string
  description = "Existing or desired Azure ML workspace name (Otherwise 'mlw-{resource_prefix}-{environment}-{instance}')"
  default     = null
}

/*
 * Networking Configuration - Optional
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

variable "subnet_address_prefixes_aks" {
  type        = list(string)
  description = "Address prefixes for the AKS subnet"
  default     = ["10.0.5.0/24"]
}

variable "subnet_address_prefixes_aks_pod" {
  type        = list(string)
  description = "Address prefixes for the AKS pod subnet"
  default     = ["10.0.6.0/24"]
}

/*
 * AKS Cluster Configuration - Optional
 */

variable "node_vm_size" {
  type        = string
  description = "VM size for the agent pool in the AKS cluster. Default is Standard_D8ds_v5"
  default     = "Standard_D8ds_v5"
}

variable "node_count" {
  type        = number
  description = "Number of nodes for the agent pool in the AKS cluster"
  default     = 1
}

variable "enable_auto_scaling" {
  type        = bool
  description = "Should enable auto-scaler for the default node pool"
  default     = false
}

variable "min_count" {
  type        = number
  description = "The minimum number of nodes which should exist in the default node pool. Valid values are between 0 and 1000"
  default     = null
}

variable "max_count" {
  type        = number
  description = "The maximum number of nodes which should exist in the default node pool. Valid values are between 0 and 1000"
  default     = null
}

/*
 * GPU Node Pool Configuration - Optional
 */

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
  description = "Additional node pools for the AKS cluster. Map key is used as the node pool name"
  default     = {}
}

/*
 * AKS Integration Configuration - Optional
 */

variable "should_integrate_aks_cluster" {
  type        = bool
  description = "Whether to integrate an AKS cluster as a compute target with the workspace"
  default     = false
}

variable "aks_cluster_purpose" {
  type        = string
  description = "Purpose of AKS cluster: DevTest, DenseProd, or FastProd"
  default     = "DevTest"
  validation {
    condition     = contains(["DevTest", "DenseProd", "FastProd"], var.aks_cluster_purpose)
    error_message = "aks_cluster_purpose must be one of: DevTest, DenseProd, or FastProd."
  }
}

variable "workload_tolerations" {
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = string
  }))
  description = "Tolerations for AzureML workloads (training/inference) to schedule on nodes with taints"
  default     = []
}

variable "cluster_integration_instance_types" {
  type = map(object({
    nodeSelector = optional(map(string))
    resources = optional(object({
      requests = optional(map(any))
      limits   = optional(map(any))
    }))
  }))
  description = "Instance types configuration for Kubernetes compute. Key is the instance type name, value contains nodeSelector and resource specifications"
  default     = null
}

/*
 * Edge Deployment Configuration - Optional
 */

variable "should_deploy_edge_extension" {
  type        = bool
  description = "Whether to deploy Azure ML edge extension on a connected cluster"
  default     = false
}

/*
 * Private Endpoints Configuration - Optional
 */

variable "should_enable_private_endpoints" {
  type        = bool
  description = "Whether to enable private endpoints across resources for secure connectivity"
  default     = false
}

/*
 * Outbound Access Configuration - Optional
 */

variable "should_enable_managed_outbound_access" {
  type        = bool
  description = "Whether to enable managed outbound egress via NAT gateway instead of platform default internet access"
  default     = true
}

/*
 * VPN Gateway Configuration - Optional
 */

variable "should_enable_vpn_gateway" {
  type        = bool
  description = "Whether to create VPN Gateway for remote access"
  default     = false
}

variable "vpn_site_connections" {
  type = list(object({
    name                 = string
    address_spaces       = list(string)
    shared_key_reference = string
    gateway_ip_address   = optional(string)
    gateway_fqdn         = optional(string)
    bgp_asn              = optional(number)
    bgp_peering_address  = optional(string)
    ike_protocol         = optional(string, "IKEv2")
  }))
  description = "Site-to-site VPN site definitions for connecting on-premises networks"
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
  description = "Pre-shared keys for site-to-site VPN connections indexed by connection name"
  sensitive   = true
  default     = {}
}

/*
 * VM Host Configuration - Optional
 */

variable "should_create_vm_host" {
  type        = bool
  description = "Whether to create VM host for GPU workloads and testing"
  default     = false
}

variable "vm_host_count" {
  type        = number
  description = "Number of VM hosts to create"
  default     = 1
}

variable "vm_sku_size" {
  type        = string
  description = "VM SKU size for the host"
  default     = "Standard_D8s_v3"
}

variable "vm_priority" {
  type        = string
  description = "VM priority: Regular or Spot for cost optimization"
  default     = "Regular"
}

variable "vm_eviction_policy" {
  type        = string
  description = "Eviction policy for Spot VMs: Deallocate or Delete"
  default     = "Deallocate"
}

variable "vm_max_bid_price" {
  type        = number
  description = "Maximum hourly price for Spot VM (-1 for Azure default)"
  default     = -1
}

variable "should_assign_current_user_vm_admin" {
  type        = bool
  description = "Whether to assign current user VM admin role for Azure AD login"
  default     = true
}

variable "should_use_vm_password_auth" {
  type        = bool
  description = "Whether to use password authentication for VM access"
  default     = false
}

variable "should_create_vm_ssh_key" {
  type        = bool
  description = "Whether to generate SSH key pair for VM access"
  default     = true
}

/*
 * Inference Router Configuration - Optional
 */

variable "inference_router_service_type" {
  type        = string
  description = "Service type for inference router: LoadBalancer, NodePort, or ClusterIP"
  default     = "NodePort"
  validation {
    condition     = contains(["LoadBalancer", "NodePort", "ClusterIP"], var.inference_router_service_type)
    error_message = "inference_router_service_type must be one of: LoadBalancer, NodePort, or ClusterIP."
  }
}

/*
 * Individual Chart Installation Flags - Optional
 */

variable "should_install_nvidia_device_plugin" {
  type        = bool
  description = "Whether to install NVIDIA Device Plugin for GPU support (prefer should_install_robotics_charts)"
  default     = false
}

variable "should_install_dcgm_exporter" {
  type        = bool
  description = "Whether to install DCGM exporter for GPU metrics (prefer should_install_robotics_charts)"
  default     = false
}

variable "should_install_volcano" {
  type        = bool
  description = "Whether to install Volcano scheduler (prefer should_install_azureml_charts)"
  default     = false
}

/*
 * AzureML Registry Configuration - Optional
 */

variable "should_deploy_azureml_registry" {
  type        = bool
  description = "Whether to deploy AzureML Registry for model management"
  default     = false
}

