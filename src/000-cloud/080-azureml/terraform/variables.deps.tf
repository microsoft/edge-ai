/*
 * Inter-component dependency variables
 */

variable "acr" {
  type = object({
    id   = optional(string)
    name = optional(string)
    sku  = optional(string)
  })
  description = "Azure Container Registry object from 060-acr component (optional)."
}

variable "application_insights" {
  type = object({
    id                  = string
    name                = string
    instrumentation_key = string
  })
  description = "Application Insights object from 020-observability component."
}

variable "compute_cluster_subnet" {
  type = object({
    id   = string
    name = optional(string)
  })
  description = "Existing subnet for the Azure ML compute cluster from networking components."
  default     = null
}

variable "key_vault" {
  type = object({
    id   = string
    name = string
  })
  description = "Key Vault object from 010-security-identity component."
}

variable "resource_group" {
  type = object({
    name     = string
    id       = optional(string)
    location = optional(string)
  })
  description = "Resource group object from 000-resource-group component."
}

variable "storage_account" {
  type = object({
    id   = string
    name = string
  })
  description = "Storage Account object from 030-data component."
}

variable "kubernetes" {
  type = object({
    id                  = string
    name                = string
    resource_group_name = string
    default_node_pool = list(object({
      name       = string
      node_count = number
      vm_size    = string
    }))
  })
  description = "The Kubernetes cluster object from 070-kubernetes component."
  default     = null
}

variable "ml_workload_identity" {
  type = object({
    id           = string
    principal_id = string
  })
  description = "AzureML workload managed identity object from security identity containing id and principal_id."
  default     = null
}
