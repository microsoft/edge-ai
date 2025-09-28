/*
 * Required Variables
 */

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

/*
 * Optional Variables - General
 */

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
  default     = "001"
}

/*
 * Optional Variables - CNCF Cluster
 */

variable "should_get_custom_locations_oid" {
  type        = bool
  description = <<-EOF
  Whether to get Custom Locations Object ID using Terraform's azuread provider. (Otherwise, provided by
  'custom_locations_oid' or `az connectedk8s enable-features` for custom-locations on cluster setup if not provided.)
  EOF
  default     = true
}

variable "custom_locations_oid" {
  type        = string
  description = <<-EOF
  The object id of the Custom Locations Entra ID application for your tenant.
  If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.
  
  ```sh
  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
  ```
  EOF
  default     = null
}

variable "should_add_current_user_cluster_admin" {
  type        = bool
  description = "Gives the current logged in user cluster-admin permissions with the new cluster."
  default     = true
}

variable "should_enable_private_endpoints" {
  type        = bool
  description = "Whether to enable private endpoints for Key Vault and Storage Account"
  default     = false
}
