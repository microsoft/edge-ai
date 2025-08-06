variable "should_create_acr_private_endpoint" {
  type        = bool
  description = "Should create a private endpoint for the Azure Container Registry. Default is false."
}

variable "subnet_address_prefixes_acr" {
  type        = list(string)
  description = "Address prefixes for the ACR subnet."
}
