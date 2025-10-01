/*
 * VPN Gateway Configuration - Optional
 */

variable "vpn_gateway_config" {
  type = object({
    sku                 = optional(string, "VpnGw1")
    generation          = optional(string, "Generation1")
    client_address_pool = optional(list(string), ["192.168.200.0/24"])
    protocols           = optional(list(string), ["OpenVPN", "IkeV2"])
  })
  description = "VPN Gateway configuration including SKU, generation, client address pool, and supported protocols"
  default     = {}
}

/*
 * Authentication Configuration - Optional
 */

variable "should_use_azure_ad_auth" {
  type        = bool
  description = "Whether to use Azure AD authentication for VPN Gateway. When true, uses Azure AD authentication. When false, uses certificate authentication"
  default     = true
}

variable "azure_ad_config" {
  type = object({
    tenant_id = optional(string)
    audience  = optional(string, "c632b3df-fb67-4d84-bdcf-b95ad541b5c8")
    issuer    = optional(string)
  })
  description = "Azure AD configuration for VPN Gateway authentication. tenant_id is required when should_use_azure_ad_auth is true. audience defaults to Microsoft-registered app. issuer will default to `https://sts.windows.net/{tenant_id}/` when not provided"
  default     = {}
}

variable "vpn_gateway_subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the GatewaySubnet. Must be /27 or larger"
  default     = ["10.0.2.0/27"]
}

/*
 * Outbound Access Controls - Optional
 */

variable "default_outbound_access_enabled" {
  type        = bool
  description = "Whether to enable default outbound internet access for the VPN gateway subnet"
  default     = false
}

/*
 * Certificate Management Configuration - Optional
 */

variable "should_generate_ca" {
  type        = bool
  description = "Whether to generate a new CA certificate. When false, uses existing certificate from Key Vault. Only used when should_use_azure_ad_auth is false"
  default     = true
}

variable "existing_certificate_name" {
  type        = string
  description = "Name of existing certificate in Key Vault when should_generate_ca is false. Required when should_generate_ca is false and should_use_azure_ad_auth is false"
  default     = null
  validation {
    condition = (
      var.should_use_azure_ad_auth ||
      var.should_generate_ca ||
      (!var.should_generate_ca && !var.should_use_azure_ad_auth && try(length(var.existing_certificate_name), 0) > 0)
    )
    error_message = "existing_certificate_name is required when should_generate_ca is false and should_use_azure_ad_auth is false."
  }
}

variable "certificate_validity_days" {
  type        = number
  description = "Validity period in days for auto-generated certificates. Only used when should_generate_ca is true and should_use_azure_ad_auth is false"
  default     = 365
}

variable "certificate_subject" {
  type = object({
    common_name         = optional(string, "VPN Gateway Root Certificate")
    organization        = optional(string, "Edge AI Accelerator")
    organizational_unit = optional(string, "IT")
    country             = optional(string, "US")
    province            = optional(string, "WA")
    locality            = optional(string, "Redmond")
  })
  description = "Certificate subject information for auto-generated certificates. Only used when should_generate_ca is true and should_use_azure_ad_auth is false"
  default     = {}
}

/*
 * Site-to-Site Configuration - Optional
 */

variable "vpn_site_connections" {
  type = list(object({
    name                       = string
    address_spaces             = list(string)
    shared_key_reference       = string
    connection_mode            = optional(string, "Default")
    dpd_timeout_seconds        = optional(number)
    gateway_fqdn               = optional(string)
    gateway_ip_address         = optional(string)
    ike_protocol               = optional(string, "IKEv2")
    use_policy_based_selectors = optional(bool, false)
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
  description = "Site-to-site VPN site definitions including on-premises device addressing and optional IPsec or BGP settings. Address spaces must not overlap with Azure VNets"
  default     = []
}

variable "vpn_site_default_ipsec_policy" {
  type = object({
    dh_group            = string
    ike_encryption      = string
    ike_integrity       = string
    ipsec_encryption    = string
    ipsec_integrity     = string
    pfs_group           = string
    sa_datasize_kb      = optional(number)
    sa_lifetime_seconds = optional(number)
  })
  description = "Fallback IPsec configuration applied to site connections when they omit an ipsec_policy override"
  default     = null
}

variable "vpn_site_shared_keys" {
  type        = map(string)
  description = "Pre-shared keys for site connections keyed by shared_key_reference. Store values in secure secret management systems"
  default     = {}
  sensitive   = true
}


