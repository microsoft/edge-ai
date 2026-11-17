/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
    id   = optional(string)
  })
  description = "Resource group object containing name and id where resources will be deployed"
}

/*
 * Optional Variables
 */

variable "cluster_server_machine" {
  type = object({
    id       = string
    location = string
  })
  default = null
}

variable "cluster_node_machine" {
  type = list(object({
    id       = string
    location = string
  }))
  default = null
}

variable "cluster_node_machine_count" {
  type        = number
  description = "Number of cluster node machines referenced by cluster_node_machine when deploying scripts"
  default     = null
}

variable "arc_onboarding_principal_ids" {
  type        = list(string)
  description = "The Principal IDs for the identity or service principal that will be used for onboarding the cluster to Arc"
  default     = null
}

variable "arc_onboarding_identity" {
  type = object({
    id           = string
    name         = string
    principal_id = string
    client_id    = string
    tenant_id    = string
  })
  description = "The User Assigned Managed Identity that will be used for onboarding the cluster to Arc"
  default     = null
}

variable "arc_onboarding_sp" {
  type = object({
    client_id     = string
    object_id     = string
    client_secret = string
  })
  sensitive = true
  default   = null
}

variable "key_vault" {
  type = object({
    id        = string
    name      = string
    vault_uri = string
  })
  description = "The Key Vault object containing id, name, and vault_uri properties"
  default     = null
}

variable "private_key_pem" {
  type        = string
  description = "Private key for onboarding"
  sensitive   = true
  default     = null
}

