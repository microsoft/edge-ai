/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name     = string
    id       = string
    location = string
  })
  description = "Resource group object containing name and id where resources will be deployed"
}

variable "secret_sync_key_vault" {
  type = object({
    name = string
    id   = string
  })
  description = "Azure Key Vault ID to use with Secret Sync Extension."
}

variable "secret_sync_identity" {
  type = object({
    id           = string
    client_id    = string
    principal_id = string
  })
}

variable "aio_identity" {
  type = object({
    id        = string
    client_id = string
    tenant_id = string
  })
  description = "Azure IoT Operations managed identity for workspace access"
}

variable "adr_schema_registry" {
  type = object({
    id = string
  })
}

variable "adr_namespace" {
  type = object({
    id = string
  })
  description = "Azure Device Registry namespace to use with Azure IoT Operations. Otherwise, not configured."
}

variable "arc_connected_cluster" {
  type = object({
    name     = string
    id       = string
    location = string
  })
}
