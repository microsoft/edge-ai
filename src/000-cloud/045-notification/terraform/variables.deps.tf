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

variable "eventhub_namespace" {
  type = object({
    id   = string
    name = string
  })
  description = "Event Hub namespace for Logic App trigger connectivity and role assignment"
}

variable "key_vault" {
  type = object({
    id        = string
    name      = string
    vault_uri = string
  })
  description = "Key Vault containing the Teams webhook URL secret"
}
