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

/*
 * Network Security Perimeter - Optional
 */

variable "should_use_network_security_perimeter" {
  type        = bool
  description = "Whether to create a Network Security Perimeter that allows the detected deployment client IP for supported PaaS resources"
  default     = false
}

variable "network_security_perimeter_allowed_ip_address_prefixes" {
  type        = list(string)
  description = "Additional IPv4 or IPv6 CIDR prefixes allowed through the Network Security Perimeter; the detected deployment client IP is added automatically"
  default     = []
}

/*
 * Existing Networking Parameters - Optional
 */

variable "use_existing_virtual_network" {
  type        = bool
  description = "Whether to reference an existing virtual network, subnet, and network security group instead of creating new ones"
  default     = false
}

variable "existing_resource_group_name" {
  type        = string
  description = "Resource group name containing the existing virtual network when use_existing_virtual_network is true. Otherwise, the resource_group input's name"
  default     = null
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network to create or reference. Otherwise, 'vnet-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet to create or reference. Otherwise, 'snet-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "network_security_group_name" {
  type        = string
  description = "Name of the network security group to create or reference. Otherwise, 'nsg-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

