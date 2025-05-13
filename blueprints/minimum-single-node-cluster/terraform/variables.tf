/**
 * # Minimum Single Node Cluster Blueprint Variables
 *
 * Variables for the minimum-single-node-cluster blueprint.
 * Only includes essential variables required for a minimal deployment.
 */

/*
 * Core Variables - Required
 */

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

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc..."
  default     = "001"
}

/*
 * Custom Locations - Required for Azure IoT Operations
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

/*
 * Optional Variables
 */

variable "should_create_anonymous_broker_listener" {
  type        = string
  description = "Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)"
  default     = false
}

variable "vm_sku_size" {
  type        = string
  description = "Size of the VM"
  // Minimize resource usage - set smaller VM size
  default = "Standard_D4_v3"
}
