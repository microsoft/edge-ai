/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
  })
  description = "Resource group object containing name and id"
}

variable "virtual_network" {
  type = object({
    id   = string
    name = string
  })
  description = "Virtual network object containing id and name"
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
}

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
}

variable "resolver_subnet_address_prefix" {
  type        = string
  description = "Address prefix for the Private Resolver subnet (e.g., '10.0.254.0/28')"
}

variable "default_outbound_access_enabled" {
  type        = bool
  description = "Whether to enable default outbound internet access for the Private Resolver subnet"
}

variable "should_enable_nat_gateway" {
  type        = bool
  description = "Whether NAT gateway association should be enabled for the resolver subnet"
}

variable "nat_gateway_id" {
  type        = string
  description = "NAT gateway resource ID for associating the resolver subnet. Only used when should_enable_nat_gateway is true"
}
