/*
 * Optional Variables
 */

variable "should_create_aks" {
  type        = bool
  description = "Should create Azure Kubernetes Service. Default is false."
  default     = false
}

variable "should_enable_azure_monitor_metrics" {
  type        = bool
  description = "Whether to enable Azure Monitor Metrics (Prometheus) extension for the AKS cluster."
  default     = true
}

variable "azure_monitor_annotations_allowed" {
  type        = string
  description = "Comma-separated list of additional Kubernetes resource annotations to scrape for Azure Monitor. Format: \"pods=[annotation1,...],namespaces=[annotation2,...]\". When null, only name and namespace labels are included (recommended for performance)."
  default     = null
}

variable "azure_monitor_labels_allowed" {
  type        = string
  description = "Comma-separated list of additional Kubernetes resource labels to scrape for Azure Monitor. Format: \"pods=[label1,...],namespaces=[label2,...]\". When null, only name and namespace labels are included (recommended for performance)."
  default     = null
}

variable "should_create_arc_cluster_instance" {
  type        = bool
  description = "Should create an Azure Arc Cluster Instance. Default is false."
  default     = false
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

variable "dns_prefix" {
  type        = string
  default     = null
  description = "DNS prefix for the AKS cluster. This is used to create a unique DNS name for the cluster. If not provided, a default value will be generated."
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

/*
 * Outbound Access Controls - Optional
 */

variable "default_outbound_access_enabled" {
  type        = bool
  description = "Whether to enable default outbound internet access for AKS subnets"
  default     = false
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

/*
 * Private Cluster Configuration - Optional
 */

variable "should_enable_private_cluster" {
  type        = bool
  description = "Whether to enable private cluster mode for AKS"
  default     = false
}

variable "should_enable_private_cluster_public_fqdn" {
  type        = bool
  description = "Whether to enable public FQDN for private cluster"
  default     = false
}

variable "private_dns_zone_id" {
  type        = string
  description = "ID of the private DNS zone for the private cluster. Use 'system' to have AKS manage it, 'none' for no private DNS zone, or a resource ID for custom zone"
  default     = null
}

variable "should_enable_private_endpoint" {
  type        = bool
  description = "Whether to create a private endpoint for the AKS cluster"
  default     = false
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "The ID of the subnet where the private endpoint will be created"
  default     = null
}

variable "virtual_network_id" {
  type        = string
  description = "The ID of the virtual network to link to the private DNS zone"
  default     = null
}

/*
 * Workload Identity Configuration - Optional
 */

variable "should_enable_workload_identity" {
  type        = bool
  description = "Whether to enable Azure AD Workload Identity for the cluster. Requires OIDC issuer to be enabled."
  default     = false
}

variable "should_enable_oidc_issuer" {
  type        = bool
  description = "Whether to enable the OIDC issuer URL for the cluster. Required for workload identity."
  default     = false
}

/*
 * Cluster Admin Configuration - Optional
 */

variable "cluster_admin_oid" {
  type        = string
  description = "The Object ID that will be given Azure Kubernetes Cluster Admin Role permissions on the cluster. (Otherwise, current logged in user Object ID if 'should_add_current_user_cluster_admin=true')"
  default     = null
}

variable "should_add_current_user_cluster_admin" {
  type        = bool
  description = "Whether to assign the current logged in user Azure Kubernetes Cluster Admin Role permissions on the cluster when 'cluster_admin_oid' is not provided."
  default     = true
}

variable "should_disable_local_account" {
  type        = bool
  description = "Whether to disable local admin account for the AKS cluster. Recommended for security compliance (CKV_AZURE_141)."
  default     = true
}

/*
 * AKS Command Invoke Configuration - Optional
 */

variable "aks_command_invoke_configurations" {
  type = map(object({
    command           = optional(string, null)
    file_path         = optional(string, null)
    folder_path       = optional(string, null)
    timeout_minutes   = optional(number, 30)
    target_cluster_id = optional(string, null)
  }))
  description = "Map of AKS command invoke configurations. Key is used as the configuration name/identifier."
  default     = {}
}

