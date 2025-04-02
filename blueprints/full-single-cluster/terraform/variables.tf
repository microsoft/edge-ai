variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "capacity_id" {
  type        = string
  description = "The capacity ID for the Fabric workspace"
  default     = null
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc..."
  default     = "001"
}

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

variable "should_create_fabric_workspace" {
  type        = bool
  description = "Whether to create a Microsoft Fabric workspace"
  default     = false
}

variable "should_create_fabric_capacity" {
  type        = bool
  description = "Whether to create a Microsoft Fabric capacity"
  default     = false
}

variable "should_create_fabric_lakehouse" {
  type        = bool
  description = "Whether to create a Microsoft Fabric lakehouse"
  default     = false
}

variable "should_create_fabric_eventstream" {
  type        = bool
  description = "Whether to create a Microsoft Fabric database"
  default     = false
}

variable "should_create_anonymous_broker_listener" {
  type        = string
  description = "Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)"
  default     = false
}
