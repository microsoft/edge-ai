variable "storage_account_id" {
  type        = string
  description = "The resource ID of the storage account for ACSA cloud-backed volumes"
}

variable "acsa_extension_principal_id" {
  type        = string
  description = "The principal ID of the ACSA extension's system-assigned managed identity"
}

