/*
 * Optional Variables
 */

variable "vm_count" {
  type        = number
  description = "The number of host VMs to create if a multi-node cluster is needed."
  default     = 1
}

variable "vm_sku_size" {
  type        = string
  description = "Size of the VM"
  default     = "Standard_D8s_v3"
}

variable "vm_username" {
  type        = string
  description = <<-EOF
    Username used for the host VM that will be given kube-config settings on setup.
    (Otherwise, 'resource_prefix' if it exists as a user)
EOF
  default     = null
}
