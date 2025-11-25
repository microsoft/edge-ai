/*
 * Resource Dependencies - Required
 */

variable "resource_group" {
  description = "Resource group object containing name and id."
  type = object({
    name = string
  })
}

variable "virtual_network" {
  description = "Virtual network object containing name and id."
  type = object({
    name = string
    id   = string
  })
}

/*
 * Core Variables - Required
 */

variable "environment" {
  description = "Environment for all resources in this module: dev, test, or prod."
  type        = string
}

variable "instance" {
  description = "Instance identifier for naming resources: 001, 002, etc."
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for all resources in this module."
  type        = string
}

/*
 * Networking Configuration - Required
 */

variable "subnet_address_prefixes" {
  description = "Address prefixes for the PostgreSQL delegated subnet."
  type        = list(string)
}

/*
 * Networking Configuration - Optional
 */

variable "default_outbound_access_enabled" {
  description = "Whether to enable default outbound internet access for PostgreSQL subnet."
  type        = bool
}

variable "network_security_group" {
  description = "Network security group object to associate with PostgreSQL subnet."
  type = object({
    id = string
  })
}

variable "nat_gateway" {
  description = "NAT gateway object from networking component for managed outbound access."
  type = object({
    id   = string
    name = string
  })
}

variable "should_enable_nat_gateway" {
  description = "Whether to associate PostgreSQL subnet with a NAT gateway for managed egress."
  type        = bool
}

variable "should_create_private_dns_zone" {
  description = "Whether to create private DNS zone for PostgreSQL."
  type        = bool
}
