/*
 * Inter-component dependency variables
 */

variable "acr" {
  type = object({
    id = optional(string)
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
  validation {
    condition     = (!var.should_assign_ml_workload_identity_roles) || (var.ml_workload_identity != null)
    error_message = "ml_workload_identity must be provided when should_assign_ml_workload_identity_roles is true."
  }
}

variable "network_security_group" {
  type = object({
    id = string
  })
  description = "Network security group from 050-networking component."
  default     = null
  validation {
    condition     = (!var.should_associate_network_security_group) || (var.network_security_group != null)
    error_message = "network_security_group must be provided when should_associate_network_security_group is true."
  }
}

variable "virtual_network" {
  type = object({
    id   = string
    name = string
  })
  description = "Virtual network from 050-networking component."
  default     = null
}

variable "nat_gateway" {
  type = object({
    id   = string
    name = string
  })
  description = "NAT gateway object from the networking component for managed outbound access."
  default     = null
  validation {
    condition     = (!var.should_enable_nat_gateway) || (var.nat_gateway != null)
    error_message = "nat_gateway must be provided when should_enable_nat_gateway is true."
  }
}
