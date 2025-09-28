variable "environment" {
  type        = string
  description = "Environment for all resources in this module"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources"
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
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

variable "shared_keys" {
  type        = map(string)
  description = "Pre-shared keys mapped by site shared key reference"
  sensitive   = true
}

variable "sites" {
  type = list(object({
    name                       = string
    address_spaces             = list(string)
    shared_key_reference       = string
    connection_mode            = optional(string)
    dpd_timeout_seconds        = optional(number)
    gateway_fqdn               = optional(string)
    gateway_ip_address         = optional(string)
    ike_protocol               = optional(string)
    use_policy_based_selectors = optional(bool)
    bgp_settings = optional(object({
      asn          = number
      peer_address = string
      peer_weight  = optional(number)
    }))
    ipsec_policy = optional(object({
      dh_group            = string
      ike_encryption      = string
      ike_integrity       = string
      ipsec_encryption    = string
      ipsec_integrity     = string
      pfs_group           = string
      sa_datasize_kb      = optional(number)
      sa_lifetime_seconds = optional(number)
    }))
  }))
  description = "Site-to-site VPN connection definitions including addressing, shared key references, and optional policy tuning"
}

variable "vpn_gateway_id" {
  type        = string
  description = "ID of the Azure Virtual Network Gateway used for site-to-site connections"
}
