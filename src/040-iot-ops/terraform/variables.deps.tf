/*
 * Required Variables
 */

variable "aio_resource_group" {
  type = object({
    name     = string
    id       = string
    location = string
  })
}

variable "sse_key_vault" {
  type = object({
    name = string
    id   = string
  })
  description = "Azure Key Vault ID to use with Secret Sync Extension."
}

variable "sse_user_assigned_identity" {
  type = object({
    id        = string
    client_id = string
  })
}

variable "aio_user_assigned_identity" {
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
