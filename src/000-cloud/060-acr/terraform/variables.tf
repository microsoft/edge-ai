/*
 * Optional Variables
 */


variable "should_create_acr_private_endpoint" {
  type        = bool
  description = "Should create a private endpoint for the Azure Container Registry. Default is false."
  default     = false
}

variable "sku" {
  type        = string
  description = "SKU for the Azure Container Registry. Options are Basic, Standard, Premium. Default is Premium because of the need for private endpoints."
  default     = "Premium"
}

variable "subnet_address_prefixes_acr" {
  type        = list(string)
  description = "Address prefixes for the ACR subnet."
  default     = ["10.0.2.0/24"]
}
