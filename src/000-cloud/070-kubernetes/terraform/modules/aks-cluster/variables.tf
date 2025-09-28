
variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod."
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

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module."
}

variable "location" {
  type        = string
  description = "Location for all resources in this module."
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc."
}

variable "node_count" {
  type        = number
  description = "Number of nodes for the agent pool in the AKS cluster."
}

variable "node_vm_size" {
  type        = string
  description = "VM size for the agent pool in the AKS cluster. Default is Standard_D8ds_v5."
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix for the AKS cluster. This is used to create a unique DNS name for the cluster. If not provided, a default value will be generated."
}

variable "enable_auto_scaling" {
  type        = bool
  description = "Should enable auto-scaler for the default node pool."
}

variable "min_count" {
  type        = number
  description = "The minimum number of nodes which should exist in the default node pool."
}

variable "max_count" {
  type        = number
  description = "The maximum number of nodes which should exist in the default node pool."
}

variable "node_pools" {
  type = map(object({
    node_count          = optional(number, null)
    vm_size             = string
    vnet_subnet_id      = string
    pod_subnet_id       = string
    node_taints         = optional(list(string), [])
    enable_auto_scaling = optional(bool, false)
    min_count           = optional(number, null)
    max_count           = optional(number, null)
    priority            = optional(string, "Regular")
    zones               = optional(list(string), null)
    eviction_policy     = optional(string)
    gpu_driver          = optional(string, null)
  }))
  description = "Additional node pools for the AKS cluster. Map key is used as the node pool name."
}

/*
 * Private Cluster Configuration - Optional
 */

variable "should_enable_private_cluster" {
  type        = bool
  description = "Whether to enable private cluster mode for AKS"
}

variable "should_enable_private_cluster_public_fqdn" {
  type        = bool
  description = "Whether to enable public FQDN for private cluster"
}

variable "private_dns_zone_id" {
  type        = string
  description = "ID of the private DNS zone for the private cluster. Use 'system' to have AKS manage it, 'none' for no private DNS zone, or a resource ID for custom zone"
}

variable "should_enable_private_endpoint" {
  type        = bool
  description = "Whether to create a private endpoint for the AKS cluster"
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "The ID of the subnet where the private endpoint will be created"
}

variable "virtual_network_id" {
  type        = string
  description = "The ID of the virtual network to link to the private DNS zone"
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
  description = "The Object ID that will be given Azure Kubernetes Cluster Admin Role permissions on the cluster."
  default     = null
}

variable "should_assign_cluster_admin" {
  type        = bool
  description = "Whether to assign Azure Kubernetes Cluster Admin Role permissions on the cluster."
}

