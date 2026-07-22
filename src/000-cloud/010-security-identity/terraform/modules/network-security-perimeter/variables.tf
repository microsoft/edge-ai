variable "allowed_ip_address_prefixes" {
  description = "IPv4 or IPv6 CIDR prefixes allowed to access resources associated with the perimeter"
  type        = list(string)
}

variable "environment" {
  description = "Environment for all resources in this module: dev, test, or prod"
  type        = string
}

variable "instance" {
  description = "Instance identifier for naming resources: 001, 002, etc"
  type        = string
}

variable "location" {
  description = "Azure region where all resources will be deployed"
  type        = string
}

variable "resource_group_id" {
  description = "Resource ID of the resource group where the perimeter is deployed"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for all resources in this module"
  type        = string
}

variable "subscription_id" {
  description = "Subscription ID allowed to access resources associated with the perimeter"
  type        = string
}
