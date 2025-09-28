variable "key_vault" {
  type = object({
    id        = string
    name      = string
    vault_uri = string
  })
  description = "Key Vault object for certificate storage"
  default     = null
}

variable "should_generate_ca" {
  type        = bool
  description = "Whether to generate a new CA certificate. When false, uses existing certificate from Key Vault"
}

variable "existing_certificate_name" {
  type        = string
  description = "Name of existing certificate in Key Vault when should_generate_ca is false"
  default     = null
}

variable "certificate_validity_days" {
  type        = number
  description = "Validity period in days for auto-generated certificates"
  default     = 365
}

variable "certificate_subject" {
  type = object({
    common_name         = string
    organization        = string
    organizational_unit = string
    country             = string
    province            = string
    locality            = string
  })
  description = "Certificate subject information for auto-generated certificates"
  default = {
    common_name         = "VPN Gateway Root Certificate"
    organization        = "Edge AI Accelerator"
    organizational_unit = "IT"
    country             = "US"
    province            = "WA"
    locality            = "Redmond"
  }
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
