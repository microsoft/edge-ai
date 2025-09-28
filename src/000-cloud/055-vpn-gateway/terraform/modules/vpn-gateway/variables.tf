variable "location" {
  type        = string
  description = "Azure region where all resources will be deployed"
}

variable "resource_group" {
  type = object({
    id       = string
    name     = string
    location = string
  })
  description = "Resource group object containing name and id"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
}

variable "environment" {
  type        = string
  description = "Environment for all resources in this module"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources"
}

variable "virtual_network" {
  type = object({
    id   = string
    name = string
  })
  description = "Virtual network object for VPN Gateway subnet creation"
}

variable "vpn_gateway_config" {
  type = object({
    sku                 = string
    generation          = string
    client_address_pool = list(string)
    protocols           = list(string)
  })
  description = "VPN Gateway configuration"
}

variable "vpn_gateway_subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the GatewaySubnet"
}

variable "default_outbound_access_enabled" {
  type        = bool
  description = "Whether to enable default outbound internet access for the VPN gateway subnet"
}

variable "should_use_azure_ad_auth" {
  type        = bool
  description = "Whether to use Azure AD authentication for VPN Gateway"
}

variable "azure_ad_config" {
  type = object({
    tenant_id = string
    audience  = string
    issuer    = string
  })
  description = "Azure AD configuration for VPN Gateway authentication"
}

variable "root_certificate_name" {
  type        = string
  description = "Name of the root certificate for VPN authentication"
}

variable "root_certificate_public_data" {
  type        = string
  description = "Public certificate data for VPN authentication"
  sensitive   = true
}


