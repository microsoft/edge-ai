variable "should_create_acr_private_endpoint" {
  type        = bool
  description = "Should create a private endpoint for the Azure Container Registry. Default is false."
}

variable "sku" {
  type        = string
  description = "SKU name for the resource"
}
