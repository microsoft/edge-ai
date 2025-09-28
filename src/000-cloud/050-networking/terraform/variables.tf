/*
 * Virtual Network Configuration - Optional
 */

variable "virtual_network_config" {
  type = object({
    address_space         = string
    subnet_address_prefix = string
  })
  description = "Configuration for the virtual network including address space and subnet prefix"
  default = {
    address_space         = "10.0.0.0/16"
    subnet_address_prefix = "10.0.1.0/24"
  }
  validation {
    condition     = can(cidrhost(var.virtual_network_config.address_space, 0)) && can(cidrhost(var.virtual_network_config.subnet_address_prefix, 0))
    error_message = "Both address_space and subnet_address_prefix must be valid CIDR blocks."
  }
}

/*
 * Private Resolver Configuration - Optional
 */

variable "should_enable_private_resolver" {
  type        = bool
  description = "Whether to enable Azure Private Resolver for VPN client DNS resolution of private endpoints"
  default     = false
}

variable "resolver_subnet_address_prefix" {
  type        = string
  description = "Address prefix for the Private Resolver subnet (Must be /28 or larger and not overlap with other subnets)"
  default     = "10.0.9.0/28"
  validation {
    condition     = can(cidrhost(var.resolver_subnet_address_prefix, 0))
    error_message = "The resolver_subnet_address_prefix must be a valid CIDR block."
  }
}

/*
 * Outbound Access Controls - Optional
 */

variable "default_outbound_access_enabled" {
  type        = bool
  description = "Whether to enable default outbound internet access for subnets created by this component"
  default     = false
}

variable "should_enable_nat_gateway" {
  type        = bool
  description = "Whether to enable managed NAT gateway support for component subnets when default outbound access is disabled"
  default     = true
}

/*
 * NAT Gateway Configuration - Optional
 */

variable "nat_gateway_idle_timeout_minutes" {
  type        = number
  description = "Idle timeout in minutes for NAT gateway connections"
  default     = 4
  validation {
    condition     = var.nat_gateway_idle_timeout_minutes >= 4 && var.nat_gateway_idle_timeout_minutes <= 240
    error_message = "Idle timeout must be between 4 and 240 minutes"
  }
}

variable "nat_gateway_public_ip_count" {
  type        = number
  description = "Number of public IP addresses to associate with the NAT gateway (example: 2)"
  default     = 1
  validation {
    condition     = var.nat_gateway_public_ip_count >= 1 && var.nat_gateway_public_ip_count <= 16
    error_message = "Public IP count must be between 1 and 16"
  }
}

variable "nat_gateway_zones" {
  type        = list(string)
  description = "Availability zones for NAT gateway resources when zone-redundancy is required (example: ['1','2'])"
  default     = []
}

