/*
 * Optional Variables
 */


variable "should_create_acr_private_endpoint" {
  type        = bool
  description = "Whether to create a private endpoint for the Azure Container Registry (default false)"
  default     = false
}

variable "sku" {
  type        = string
  description = "SKU name for the resource"
  default     = "Premium"
}

variable "subnet_address_prefixes_acr" {
  type        = list(string)
  description = "Address prefixes for the ACR subnet"
  default     = ["10.0.3.0/24"]
}

/*
 * Public Access Controls - Optional
 */

variable "allow_trusted_services" {
  type        = bool
  description = "Whether trusted Azure services can bypass registry network rules when the public endpoint is restricted"
  default     = true
}

variable "allowed_public_ip_ranges" {
  type        = list(string)
  description = "CIDR ranges permitted to reach the registry public endpoint"
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.allowed_public_ip_ranges : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", cidr))
    ])
    error_message = "Each public IP range must be provided in CIDR notation (for example, 203.0.113.24/32)."
  }
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Whether to enable the registry public endpoint alongside private connectivity"
  default     = false
}

variable "should_enable_data_endpoints" {
  type        = bool
  description = "Whether to enable dedicated data endpoints for the registry"
  default     = true
}

/*
 * Outbound Access Controls - Optional
 */

variable "default_outbound_access_enabled" {
  type        = bool
  description = "Whether to enable default outbound internet access for the ACR subnet"
  default     = false
}

variable "should_enable_nat_gateway" {
  type        = bool
  description = "Whether to associate the ACR subnet with a NAT gateway for managed outbound egress"
  default     = false
}
