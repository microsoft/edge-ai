/*
 * Required Variables
 */

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for NAT gateway resources when zone-redundancy is required (example: ['1','2'])"
}

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "idle_timeout_in_minutes" {
  type        = number
  description = "Idle timeout in minutes for connections through the NAT gateway"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "public_ip_count" {
  type        = number
  description = "Number of public IP addresses to associate with the NAT gateway"
}

variable "resource_group" {
  type = object({
    id   = string
    name = string
  })
  description = "Resource group object containing name and id"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
}
