/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name     = string
    id       = string
    location = string
  })
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
    id = string
  })
}

variable "adr_schema_registry" {
  type = object({
    id = string
  })
}

variable "arc_connected_cluster" {
  type = object({
    name     = string
    id       = string
    location = string
  })
}
