/*
 * Kubernetes Cluster Configuration - required
 */

variable "custom_locations_oid" {
  type        = string
  description = "Resource ID of the custom location for the Azure Stack HCI cluster."
}

variable "logical_network_name" {
  type        = string
  description = "Name of the logical network for the Kubernetes cluster."
}

variable "logical_network_resource_group_name" {
  type        = string
  description = "Resource group name containing the logical network for the Kubernetes cluster."
}

/*
 * Kubernetes Cluster Configuration - optional
 */
variable "control_plane_ip" {
  type        = string
  description = "IP address for the Kubernetes control plane endpoint (Otherwise, dynamically assigned)."
  default     = null
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for Linux nodes (Otherwise, generated)."
  default     = null
}

variable "aad_profile" {
  type = object({
    admin_group_object_ids = optional(list(string), [])
    enable_azure_rbac      = bool
    tenant_id              = optional(string)
  })
  description = "Azure Active Directory profile configuration for the Kubernetes cluster. If enable_azure_rbac is false, admin_group_object_ids must be provided."
  default = {
    admin_group_object_ids = []
    enable_azure_rbac      = true
    tenant_id              = null
  }

  validation {
    condition     = var.aad_profile.enable_azure_rbac || length(var.aad_profile.admin_group_object_ids) > 0
    error_message = "When enable_azure_rbac is false, admin_group_object_ids must contain at least one group object ID."
  }
}

variable "control_plane_count" {
  type        = number
  description = "Number of control plane nodes (Otherwise, 1)."
  default     = 1
}

variable "control_plane_vm_size" {
  type        = string
  description = "VM size for control plane nodes (Otherwise, 'Standard_A4_v2')."
  default     = "Standard_A4_v2"
}

variable "node_pool_count" {
  type        = number
  description = "Number of worker nodes in the default node pool (Otherwise, 1)."
  default     = 1
}

variable "node_pool_vm_size" {
  type        = string
  description = "VM size for worker nodes (Otherwise, 'Standard_D8s_v3')."
  default     = "Standard_D8s_v3"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for the cluster (Otherwise, latest stable version)."
  default     = null
}

variable "pod_cidr" {
  type        = string
  description = "CIDR range for Kubernetes pods (Otherwise, '10.244.0.0/16')."
  default     = "10.244.0.0/16"
}

variable "load_balancer_count" {
  type        = number
  description = "Number of load balancers for the cluster (Otherwise, 0)."
  default     = 0
}

variable "smb_csi_driver_enabled" {
  type        = bool
  description = "Enable SMB CSI driver for persistent storage (Otherwise, false)."
  default     = false
}

variable "nfs_csi_driver_enabled" {
  type        = bool
  description = "Enable NFS CSI driver for persistent storage (Otherwise, false)."
  default     = false
}

variable "azure_hybrid_benefit" {
  type        = string
  description = "Azure Hybrid Benefit setting (Otherwise, 'NotApplicable')."
  default     = "NotApplicable"
}

variable "additional_nodepools" {
  type = list(object({
    name   = string
    count  = number
    vmSize = string
    osType = optional(string, "Linux")
    osSKU  = optional(string, "CBLMariner")
  }))
  description = "Additional node pools to create for the cluster (Otherwise, none)."
  default     = []
}
