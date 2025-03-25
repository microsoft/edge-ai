variable "arc_onboarding_identity_id" {
  type        = string
  description = "ID of the user assigned identity for Arc onboarding"
  default     = null
}

variable "label_prefix" {
  type        = string
  description = "Prefix to be used for all resource names"
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name for all resources in this module"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key to use for VM authentication"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet to attach the VM to"
}

variable "vm_index" {
  type        = number
  description = "Index of the VM for deployment of multiple VMs"
}

variable "vm_sku_size" {
  type        = string
  description = "Size of the VM"
  default     = "Standard_D8s_v3"
}

variable "vm_username" {
  type        = string
  description = "Username for the VM admin account"
}