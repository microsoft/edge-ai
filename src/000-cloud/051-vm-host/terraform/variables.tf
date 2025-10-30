/*
 * VM Configuration - Optional
 */

variable "host_machine_count" {
  type        = number
  description = "The number of host VMs to create if a multi-node cluster is needed"
  default     = 1
}

variable "vm_sku_size" {
  type        = string
  description = "Size of the VM"
  default     = "Standard_D8s_v3"
}

variable "vm_username" {
  type        = string
  description = "Username for the VM admin account"
  default     = null
}

/*
 * Spot Pricing Configuration - Optional
 */

variable "vm_priority" {
  type        = string
  description = "VM priority: Regular (production, guaranteed capacity) or Spot (cost-optimized, can be evicted with 30s notice). Spot VMs offer up to 90% cost savings"
  default     = "Regular"
  validation {
    condition     = contains(["Regular", "Spot"], var.vm_priority)
    error_message = "VM priority must be either 'Regular' or 'Spot'."
  }
}

variable "vm_eviction_policy" {
  type        = string
  description = "Eviction policy for Spot VMs: Deallocate (VM stopped, disk retained, can restart) or Delete (VM and disks removed, no storage charges). Only used when vm_priority is Spot"
  default     = "Delete"
  validation {
    condition     = contains(["Deallocate", "Delete"], var.vm_eviction_policy)
    error_message = "Eviction policy must be either 'Deallocate' or 'Delete'."
  }
}

variable "vm_max_bid_price" {
  type        = number
  description = "Maximum price per hour in USD for Spot VM. Set to -1 (default) for no price-based eviction - VM will not be evicted for price reasons. Custom values support up to 5 decimal places (e.g., 0.98765). Only used when vm_priority is Spot"
  default     = -1
  validation {
    condition     = var.vm_max_bid_price == -1 || var.vm_max_bid_price > 0
    error_message = "Max bid price must be -1 or a positive number."
  }
}

/*
 * Authentication Fallback - Optional
 */

variable "should_create_ssh_key" {
  type        = bool
  description = "Generate SSH key pair for VM fallback access. Defaults to true to ensure emergency access when Azure AD authentication is unavailable."
  default     = true
}

variable "should_use_password_auth" {
  type        = bool
  description = "Use password authentication for VM access. When enabled, a random secure password will be generated and stored in Terraform state."
  default     = false
}

/*
 * Network Configuration - Optional
 */

variable "should_create_public_ip" {
  type        = bool
  description = "Create public IP address for VM. Set to false for private VNet scenarios using Azure Bastion or VPN connectivity."
  default     = true
}

/*
 * Azure AD RBAC Assignments - Optional
 */

variable "should_assign_current_user_vm_admin" {
  type        = bool
  description = "Whether to assign the current Azure AD user the Virtual Machine Administrator Login role (sudo access). Requires Microsoft Graph provider permissions"
  default     = true
}

variable "vm_admin_principals" {
  type        = map(string)
  description = "Map of Azure AD principals for Virtual Machine Administrator Login role (sudo access). Keys are descriptive identifiers (e.g., 'user@company.com'), values are principal object IDs."
  default     = {}
}

variable "vm_user_principals" {
  type        = map(string)
  description = "Map of Azure AD principals for Virtual Machine User Login role (standard access). Keys are descriptive identifiers (e.g., 'user@company.com'), values are principal object IDs."
  default     = {}
}
