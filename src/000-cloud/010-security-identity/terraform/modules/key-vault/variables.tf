variable "key_vault_name" {
  type        = string
  description = "The name of the Key Vault to store secrets. If not provided, defaults to 'kv-{resource_prefix}-{environment}-{instance}'"
}

variable "key_vault_admin_principal_id" {
  description = "The Principal ID or Object ID for the admin that will have access to update secrets on the Key Vault."
  type        = string
}

variable "should_create_private_endpoint" {
  type        = bool
  description = "Whether to create a private endpoint for the Key Vault"
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "The ID of the subnet where the private endpoint will be created"
}

variable "virtual_network_id" {
  type        = string
  description = "The ID of the virtual network to link to the private DNS zone"
}

variable "should_enable_public_network_access" {
  type        = bool
  description = "Whether to enable public network access for the Key Vault"
}

variable "should_add_key_vault_role_assignment" {
  type        = bool
  description = "Whether to add role assignment to the Key Vault"
}
