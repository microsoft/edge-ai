/*
 * Virtual Network Configuration - Optional
 */

variable "virtual_network_config" {
  type = object({
    address_space         = string
    subnet_address_prefix = string
  })
  description = "Configuration for the virtual network including address space and subnet prefix."
  default = {
    address_space         = "10.0.0.0/16"
    subnet_address_prefix = "10.0.2.0/24"
  }
  validation {
    condition     = can(cidrhost(var.virtual_network_config.address_space, 0)) && can(cidrhost(var.virtual_network_config.subnet_address_prefix, 0))
    error_message = "Both address_space and subnet_address_prefix must be valid CIDR blocks."
  }
}
