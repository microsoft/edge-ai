/*
 * Required Variables
 */

variable "key_vault" {
  type = object({
    id        = string
    name      = string
    vault_uri = string
  })
  description = "The Key Vault object containing id, name, and vault_uri properties"
}

variable "resource_group" {
  type = object({
    id = string
  })
  description = "Resource group object containing name and id where resources will be deployed"
}
