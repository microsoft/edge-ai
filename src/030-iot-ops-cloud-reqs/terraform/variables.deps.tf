/*
 * Required Variables
 */

variable "aio_resource_group" {
  type = object({
    name     = string
    location = string
  })
}

variable "sse_key_vault" {
  type = object({
    id = string
  })
  description = "Azure Key Vault ID to use with Secret Sync Extension."
  default     = null
}
