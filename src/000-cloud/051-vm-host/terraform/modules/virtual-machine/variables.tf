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
  description = "Azure region where all resources will be deployed"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key to use for VM authentication"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet to deploy the VM host in"
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