variable "default_outbound_access_enabled" {
  type        = bool
  description = "Whether to enable default outbound internet access for the ACR subnet"
}

variable "nat_gateway_id" {
  type        = string
  description = "NAT gateway resource id for associating the ACR subnet"
}

variable "should_enable_nat_gateway" {
  type        = bool
  description = "Whether to associate the ACR subnet with a NAT gateway for managed egress"
}

variable "should_create_acr_private_endpoint" {
  type        = bool
  description = "Should create a private endpoint for the Azure Container Registry. Default is false."
}

variable "subnet_address_prefixes_acr" {
  type        = list(string)
  description = "Address prefixes for the ACR subnet"
}
