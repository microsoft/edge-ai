/**
 * # Variables for Kubernetes Assets
 *
 * This file defines variables specific to the Kubernetes assets component.
 */

/*
 * Required Variables
 */

variable "custom_location_id" {
  type        = string
  description = "The resource ID of the Custom Location"
}

variable "location" {
  type        = string
  description = "Azure region where all resources will be deployed"
}

/*
 * Asset Configuration Variables - Optional
 */

variable "asset_endpoint_profiles" {
  type = list(object({
    endpoint_profile_type             = optional(string)
    method                            = optional(string)
    name                              = string
    opc_additional_config_string      = optional(string)
    should_enable_opc_asset_discovery = optional(bool)
    target_address                    = string
  }))
  description = "List of asset endpoint profiles to create. Otherwise, an empty list."
  default     = []
}

variable "assets" {
  type = list(object({
    asset_endpoint_profile_ref = string
    datasets = optional(list(object({
      data_points = list(object({
        data_point_configuration = optional(string)
        data_source              = string
        name                     = string
        observability_mode       = optional(string)
      }))
      name = string
    })), [])
    default_datasets_configuration = optional(string)
    description                    = optional(string)
    display_name                   = optional(string)
    documentation_uri              = optional(string)
    enabled                        = optional(bool)
    hardware_revision              = optional(string)
    manufacturer                   = optional(string)
    manufacturer_uri               = optional(string)
    model                          = optional(string)
    name                           = string
    product_code                   = optional(string)
    serial_number                  = optional(string)
    software_revision              = optional(string)
  }))
  description = "List of assets to create. Otherwise, an empty list."
  default     = []
}

/*
 * Feature Flag Variables - Optional
 */

variable "should_create_default_asset" {
  type        = bool
  description = "Whether to create a default asset. Otherwise, false."
  default     = false
}

/*
 * Identity Variables - Optional
 */

variable "k8s_bridge_principal_id" {
  type        = string
  default     = null
  description = <<-EOT
Optional. The principal ID of the K8 Bridge for Azure IoT Operations.
Required only if enable_asset_discovery=true and automatic retrieval fails.
If null and enable_asset_discovery=true, will be automatically retrieved using the service principal data source.

Can be retrieved manually using:

  az ad sp list --display-name \"K8 Bridge\" --query \"[0].appId\" -o tsv
EOT
}
