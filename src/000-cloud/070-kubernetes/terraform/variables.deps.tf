/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
    id   = string
  })
  description = "Resource group object containing name and id where resources will be deployed"
}

variable "network_security_group" {
  type = object({
    id   = string
    name = string
  })
  description = "Network security group object containing id and name for NSG rule associations"
}

variable "virtual_network" {
  type = object({
    name = string
    id   = string
  })
}

variable "nat_gateway" {
  type = object({
    id   = string
    name = string
  })
  description = "NAT gateway object from networking component for managed outbound access"
  default     = null
}

variable "acr" {
  type = object({
    id = string
  })
  description = "Azure Container Registry"
}

variable "aks_identity" {
  type = object({
    id           = string
    name         = string
    principal_id = string
    client_id    = string
    tenant_id    = string
  })
  description = "AKS user-assigned identity for custom private DNS zone scenarios."
  default     = null
}

variable "log_analytics_workspace" {
  type = object({
    id                 = string
    name               = string
    workspace_id       = string
    primary_shared_key = string
  })
  description = "Log Analytics workspace object for Microsoft Defender configuration."
  default     = null
}

variable "metrics_data_collection_rule" {
  type = object({
    id = string
  })
  description = "Metrics data collection rule object from observability component for custom Azure Monitor workspace association"
  default     = null
}


