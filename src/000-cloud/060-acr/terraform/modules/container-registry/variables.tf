variable "should_create_acr_private_endpoint" {
  type        = bool
  description = "Should create a private endpoint for the Azure Container Registry. Default is false."
}

variable "allow_trusted_services" {
  type        = bool
  description = "Whether trusted Azure services can bypass registry network rules"
}

variable "allowed_public_ip_ranges" {
  type        = list(string)
  description = "CIDR ranges permitted to reach the registry public endpoint"

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
}

variable "sku" {
  type        = string
  description = "SKU name for the resource"
}

variable "should_enable_data_endpoints" {
  type        = bool
  description = "Whether to enable dedicated data endpoints for the registry"
}
