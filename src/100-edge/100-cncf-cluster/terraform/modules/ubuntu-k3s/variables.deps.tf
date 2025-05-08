/*
 * Required Variables
 */

variable "aio_resource_group" {
  type = object({
    name = string
    id   = optional(string)
  })
}

/*
 * Optional Variables
 */

variable "cluster_server_virtual_machine" {
  type = object({
    id = string
  })
}

variable "cluster_node_virtual_machines" {
  type = list(object({
    id = string
  }))
}

variable "arc_onboarding_sp" {
  type = object({
    client_id     = string
    object_id     = string
    client_secret = string
  })
  sensitive = true
}

variable "key_vault" {
  type = object({
    id        = string
    name      = string
    vault_uri = string
  })
  description = "The Key Vault object containing id, name, and vault_uri properties."
  default     = null
}
