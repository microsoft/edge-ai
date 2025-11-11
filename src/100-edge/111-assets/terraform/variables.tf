/**
 * # Variables for Kubernetes Assets
 *
 * This file defines variables specific to the Kubernetes assets component using
 * the namespaced Device Registry model.
 */

variable "should_create_default_asset" {
  type        = bool
  description = "Whether to create a default asset and endpoint profile. Otherwise, false."
  default     = false
}

/*
 * Required Variables
 */

variable "custom_location_id" {
  type        = string
  description = "The resource ID of the Custom Location."
}

variable "location" {
  type        = string
  description = "Azure region where all resources will be deployed."
}

/*
 * Device Configuration Variables - Optional
 */

variable "namespaced_devices" {
  type = list(object({
    name    = string
    enabled = optional(bool, true)
    endpoints = object({
      outbound = optional(object({
        assigned = object({})
      }), { assigned = {} })
      inbound = map(object({
        endpoint_type           = string
        address                 = string
        version                 = optional(string, null)
        additionalConfiguration = optional(string)
        authentication = object({
          method = string
          usernamePasswordCredentials = optional(object({
            usernameSecretName = string
            passwordSecretName = string
          }))
          x509Credentials = optional(object({
            certificateSecretName = string
          }))
        })
        trustSettings = optional(object({
          trustList = string
        }))
      }))
    })
  }))
  description = "List of namespaced devices to create. Otherwise, an empty list."
  default     = []
}

/*
 * Legacy Asset Configuration Variables - Optional
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
  description = "List of assets to create for OPC-UA. Otherwise, an empty list."
  default     = []
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

/*
 * Namespaced Asset Configuration Variables - Optional
 */

variable "should_create_default_namespaced_asset" {
  type        = bool
  description = "Whether to create default namespaced assets for testing purposes."
  default     = false
}

variable "namespaced_assets" {
  type = list(object({
    name         = string
    display_name = optional(string)
    device_ref = optional(object({
      device_name   = string
      endpoint_name = string
    }))
    asset_endpoint_profile_ref     = optional(string)
    default_datasets_configuration = optional(string)
    description                    = optional(string)
    documentation_uri              = optional(string)
    enabled                        = optional(bool, true)
    hardware_revision              = optional(string)
    manufacturer                   = optional(string)
    manufacturer_uri               = optional(string)
    model                          = optional(string)
    product_code                   = optional(string)
    serial_number                  = optional(string)
    software_revision              = optional(string)
    attributes                     = optional(map(string), {})
    datasets = optional(list(object({
      name = string
      data_points = list(object({
        data_point_configuration = optional(string)
        data_source              = string
        name                     = string
        observability_mode       = optional(string)
      }))
      dataset_configuration = optional(string)
      data_source           = optional(string)
      destinations = optional(list(object({
        target = string
        configuration = object({
          topic  = optional(string)
          retain = optional(string)
          qos    = optional(string)
        })
      })), [])
      type_ref = optional(string)
    })), [])
  }))
  description = "List of namespaced assets with enhanced configuration support"
  default     = []
}
