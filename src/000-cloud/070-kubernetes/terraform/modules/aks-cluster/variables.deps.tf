/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name = string
  })
  description = "Resource group object containing name and id where resources will be deployed"
}

variable "snet_aks" {
  description = "Subnet for the AKS vnet."
  type = object({
    id = string
  })
}

variable "snet_aks_pod" {
  description = "Subnet for the AKS pod vnet."
  type = object({
    id = string
  })
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
  description = "AKS user-assigned identity for custom private DNS zone scenarios. Required when using custom private DNS zones."
  default     = null
}

variable "log_analytics_workspace" {
  type = object({
    id = string
  })
  description = "Log Analytics workspace object for Microsoft Defender configuration"
  default     = null
}

variable "metrics_data_collection_rule" {
  type = object({
    id = string
  })
  description = "Metrics data collection rule object from observability component for custom Azure Monitor workspace association"
  default     = null
}

variable "logs_data_collection_rule" {
  type = object({
    id = string
  })
  description = "Logs data collection rule object from observability component for custom Azure Monitor workspace association"
  default     = null
}

