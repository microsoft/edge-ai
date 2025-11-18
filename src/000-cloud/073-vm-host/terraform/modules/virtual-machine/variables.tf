variable "admin_password" {
  type        = string
  description = "Admin password for VM authentication. Can be null for SSH key-only authentication."
  sensitive   = true
}

variable "arc_onboarding_identity_id" {
  type        = string
  description = "ID of the User Assigned Managed Identity for Arc onboarding. Can be null for VMs without Arc connectivity"
  default     = null
}

variable "label_prefix" {
  type        = string
  description = "Prefix to be used for all resource names"
}

variable "location" {
  type        = string
  description = "Azure region where all resources will be deployed"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "should_create_public_ip" {
  type        = bool
  description = "Whether to create a public IP address for the VM"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM authentication. Can be null for Azure AD-only authentication"
  default     = null
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet to deploy the VM in"
}

variable "vm_eviction_policy" {
  type        = string
  description = "Eviction policy for Spot VMs: Deallocate or Delete"
}

variable "vm_index" {
  type        = number
  description = "Index of the VM for deployment of multiple VMs"
}

variable "vm_max_bid_price" {
  type        = number
  description = "Maximum price per hour in USD for Spot VM. -1 for no price-based eviction"
}

variable "vm_priority" {
  type        = string
  description = "VM priority: Regular or Spot"
}

variable "vm_sku_size" {
  type        = string
  description = "Size of the VM"
}

variable "vm_username" {
  type        = string
  description = "Username for the VM admin account"
}
