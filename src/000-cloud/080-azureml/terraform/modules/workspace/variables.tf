/*
 * Azure Machine Learning Workspace Module Variables
 */

variable "application_insights_id" {
  type        = string
  description = "Resource ID of the Application Insights instance."
}

variable "container_registry_id" {
  type        = string
  description = "Resource ID of the Container Registry (optional)."
}

variable "ml_workload_identity" {
  type = object({
    id           = string
    principal_id = string
  })
  description = "AzureML workload managed identity object containing id and principal_id."
}

variable "description" {
  type        = string
  description = "Description of the workspace."
}

variable "environment" {
  type        = string
  description = "The environment for the deployment."
}

variable "friendly_name" {
  type        = string
  description = "Friendly display name for the workspace."
}

variable "instance" {
  type        = string
  description = "Instance identifier for the deployment."
}

variable "key_vault_id" {
  type        = string
  description = "Resource ID of the Key Vault instance."
}

variable "location" {
  type        = string
  description = "Azure region where the workspace will be created."
}

variable "name" {
  type        = string
  description = "Name of the Azure Machine Learning workspace."
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Whether to enable public network access to the workspace."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group containing the workspace."
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resource names."
}

variable "storage_account_id" {
  type        = string
  description = "Resource ID of the Storage Account for ML artifacts."
}

variable "should_assign_current_user_workspace_roles" {
  type        = bool
  description = "Whether to assign the current user Contributor role on the workspace (passed from component)."
}

variable "should_assign_workspace_managed_identity_roles" {
  type        = bool
  description = "Whether to assign the workspace system-assigned managed identity roles to access dependent Azure services (Storage, ACR, Key Vault, Application Insights)."
}

variable "current_user_object_id" {
  type        = string
  description = "Object ID of the current Azure AD user (deferred and passed from component)."
}

/*
 * Private Endpoint Configuration - Optional
 */

variable "should_enable_private_endpoint" {
  type        = bool
  description = "Whether to create a private endpoint for the Azure ML workspace"
  default     = false
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "The ID of the subnet where the private endpoint will be created"
  default     = null
}

variable "virtual_network_id" {
  type        = string
  description = "The ID of the virtual network to link to the private DNS zone"
  default     = null
}
