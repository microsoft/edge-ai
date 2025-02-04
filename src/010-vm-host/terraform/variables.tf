/*
 * Optional Variables
 */

variable "vm_username" {
  type        = string
  description = "Name for the VM user to create on the target VM. If left empty, a random user name will be generated"
  default     = null
}

variable "vm_sku_size" {
  type        = string
  description = "Size of the VM"
  default     = "Standard_D8s_v3"
}
