variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "resource_prefix" {
  type = string
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
  description = "Prefix for all resources in this module"
}

variable "location" {
  type        = string
  description = "Azure region where all resources will be deployed"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
  default     = "001"
}

variable "use_existing_resource_group" {
  type        = bool
  description = "Whether to use an existing resource group instead of creating a new one. When true, the component will look up a resource group with the specified or generated name instead of creating it."
  default     = false
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = null
}

variable "should_create_aks" {
  type        = bool
  description = "Should create Azure Kubernetes Service. Default is false."
  default     = false
}

/*
 * AKS Cluster Configuration
 */

variable "node_count" {
  type        = number
  description = "Number of nodes for the agent pool in the AKS cluster."
  default     = 1
}

variable "node_vm_size" {
  type        = string
  description = "VM size for the agent pool in the AKS cluster. Default is Standard_D8ds_v5."
  default     = "Standard_D8ds_v5"
}

variable "enable_auto_scaling" {
  type        = bool
  description = "Should enable auto-scaler for the default node pool."
  default     = false
}

variable "min_count" {
  type        = number
  description = "The minimum number of nodes which should exist in the default node pool. Valid values are between 0 and 1000."
  default     = null
}

variable "max_count" {
  type        = number
  description = "The maximum number of nodes which should exist in the default node pool. Valid values are between 0 and 1000."
  default     = null
}

variable "dns_prefix" {
  type        = string
  default     = null
  description = "DNS prefix for the AKS cluster. This is used to create a unique DNS name for the cluster. If not provided, a default value will be generated."
}

variable "subnet_address_prefixes_aks" {
  type        = list(string)
  description = "Address prefixes for the AKS subnet."
  default     = ["10.0.4.0/24"]
}

variable "subnet_address_prefixes_aks_pod" {
  type        = list(string)
  description = "Address prefixes for the AKS pod subnet."
  default     = ["10.0.5.0/24"]
}

variable "node_pools" {
  type = map(object({
    node_count                  = number
    vm_size                     = string
    subnet_address_prefixes     = list(string)
    pod_subnet_address_prefixes = list(string)
    node_taints                 = optional(list(string), [])
    enable_auto_scaling         = optional(bool, false)
    min_count                   = optional(number, null)
    max_count                   = optional(number, null)
  }))
  description = "Additional node pools for the AKS cluster. Map key is used as the node pool name."
  default     = {}
}

variable "should_enable_private_endpoints" {
  type        = bool
  description = "Whether to enable private endpoints for Key Vault and Storage Account"
  default     = false
}

/*
 * Outbound Access Configuration
 */

variable "should_enable_managed_outbound_access" {
  type        = bool
  description = "Whether to enable managed outbound egress via NAT gateway instead of platform default internet access"
  default     = true
}

variable "nat_gateway_idle_timeout_minutes" {
  type        = number
  description = "Idle timeout in minutes for NAT gateway connections"
  default     = 4
  validation {
    condition     = var.nat_gateway_idle_timeout_minutes >= 4 && var.nat_gateway_idle_timeout_minutes <= 240
    error_message = "Idle timeout must be between 4 and 240 minutes"
  }
}

variable "nat_gateway_public_ip_count" {
  type        = number
  description = "Number of public IP addresses to associate with the NAT gateway (example: 2)"
  default     = 1
  validation {
    condition     = var.nat_gateway_public_ip_count >= 1 && var.nat_gateway_public_ip_count <= 16
    error_message = "Public IP count must be between 1 and 16"
  }
}

variable "nat_gateway_zones" {
  type        = list(string)
  description = "Availability zones for NAT gateway resources when zone-redundancy is required (example: ['1','2'])"
  default     = []
}

variable "should_create_azure_functions" {
  type        = bool
  description = "Whether to create the Azure Functions resources including App Service Plan"
  default     = false
}
