variable "resource_group_name" {
  type        = string
  description = "Name of the pre-existing resource group in which to create resources"
}

variable "resource_group_id" {
  type        = string
  description = "ID of the resource group to create resources in"
}

variable "custom_location_id" {
  type        = string
  description = "The resource ID of the Custom Location."
}

variable "connected_cluster_location" {
  type        = string
  description = "The location of the connected cluster resource"
}

variable "connected_cluster_name" {
  type        = string
  description = "The name of the connected cluster to deploy Azure IoT Operations to"
}

variable "is_sse_standalone_enabled" {
  type        = bool
  description = "Whether the SSE Standalone setup has been applied to the Arc cluster"
}

variable "key_vault_name" {
  type        = string
  description = "The name of the Key Vault to create the SPC"
}

variable "sse_user_managed_identity_name" {
  type        = string
  description = "The name of the user managed identity to create the SPC"
}

variable "aio_namespace" {
  type        = string
  description = "Azure IoT Operations namespace"
}

variable "instance_name" {
  type        = string
  description = "The name of the Azure IoT Operations instance"
}
