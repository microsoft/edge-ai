/* All Variables Required - No Defaults */

variable "access_keys_authentication_enabled" {
  description = "Whether to enable access key authentication"
  type        = bool
}

variable "clustering_policy" {
  description = "Redis clustering policy"
  type        = string
}

variable "customer_managed_key" {
  description = "Customer-managed key configuration for encryption at rest"
  type = object({
    key_vault_key_id          = string
    user_assigned_identity_id = string
  })
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
}

variable "managed_identity_id" {
  description = "User-assigned managed identity ID for Entra ID authentication"
  type        = string
}

variable "name" {
  description = "Name of the Azure Managed Redis cache"
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint deployment"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "should_create_private_dns_zone" {
  description = "Whether to create a new private DNS zone"
  type        = bool
}

variable "should_enable_high_availability" {
  description = "Whether to enable high availability mode"
  type        = bool
}

variable "should_enable_private_endpoint" {
  description = "Whether to create a private endpoint"
  type        = bool
}

variable "sku_name" {
  description = "Azure Managed Redis SKU name"
  type        = string
}

variable "virtual_network_id" {
  description = "Virtual network ID for private DNS zone linking"
  type        = string
}
