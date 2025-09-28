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
 * Outbound Access Controls - Optional
 */

variable "default_outbound_access_enabled" {
  type        = bool
  description = "Whether to enable default outbound internet access for the ACR subnet"
  default     = false
}
