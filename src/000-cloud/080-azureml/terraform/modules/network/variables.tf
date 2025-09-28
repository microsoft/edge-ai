/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
  })
  description = "Resource group object containing name and id where resources will be deployed."
}

variable "network_security_group" {
  type = object({
    id = string
  })
  description = "Network security group to apply to the subnets."
}

variable "virtual_network" {
  type = object({
    name = string
  })
  description = "Virtual network where subnets will be created."
}

variable "default_outbound_access_enabled" {
  type        = bool
  description = "Whether to enable default outbound internet access for Azure ML subnets"
}

/*
 * Core Variables
 */

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod."
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc."
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module."
}

/*
 * Optional Variables
 */

variable "subnet_address_prefixes_azureml" {
  type        = list(string)
  description = "Address prefixes for the Azure ML compute cluster subnet."
}

variable "nat_gateway_id" {
  type        = string
  description = "NAT gateway resource id for associating the Azure ML subnet"
}
