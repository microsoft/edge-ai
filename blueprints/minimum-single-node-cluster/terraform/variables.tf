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

/*
 * Optional Variables
 */

variable "should_create_anonymous_broker_listener" {
  type        = bool
  description = "Whether to enable an insecure anonymous AIO MQ Broker Listener. Should only be used for dev or test environments"
  default     = false
}

variable "vm_sku_size" {
  type = string
  // Minimize resource usage - set smaller VM size
  description = "Size of the VM"
  default     = "Standard_D4_v4"
}

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
    default_streams_configuration  = optional(string)
    default_events_configuration   = optional(string)
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
        data_point_configuration  = optional(string)
        data_source               = string
        name                      = string
        observability_mode        = optional(string)
        rest_sampling_interval_ms = optional(number)
        rest_mqtt_topic           = optional(string)
        rest_include_state_store  = optional(bool)
        rest_state_store_key      = optional(string)
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
    streams = optional(list(object({
      name                 = string
      stream_configuration = optional(string)
      type_ref             = optional(string)
      destinations = optional(list(object({
        target = string
        configuration = object({
          topic  = optional(string)
          retain = optional(string)
          qos    = optional(string)
        })
      })), [])
    })), [])
    event_groups = optional(list(object({
      name                      = string
      data_source               = optional(string)
      event_group_configuration = optional(string)
      type_ref                  = optional(string)
      default_destinations = optional(list(object({
        target = string
        configuration = object({
          topic  = optional(string)
          retain = optional(string)
          qos    = optional(string)
        })
      })), [])
      events = list(object({
        name                = string
        data_source         = string
        event_configuration = optional(string)
        type_ref            = optional(string)
        destinations = optional(list(object({
          target = string
          configuration = object({
            topic  = optional(string)
            retain = optional(string)
            qos    = optional(string)
          })
        })), [])
      }))
    })), [])
    management_groups = optional(list(object({
      name                           = string
      data_source                    = optional(string)
      management_group_configuration = optional(string)
      type_ref                       = optional(string)
      default_topic                  = optional(string)
      default_timeout_in_seconds     = optional(number, 100)
      actions = list(object({
        name                 = string
        action_type          = string
        target_uri           = string
        topic                = optional(string)
        timeout_in_seconds   = optional(number)
        action_configuration = optional(string)
        type_ref             = optional(string)
      }))
    })), [])
  }))
  description = "List of namespaced assets with enhanced configuration support"
  default     = []

  validation {
    condition = alltrue([
      for asset in var.namespaced_assets : alltrue([
        for group in coalesce(asset.management_groups, []) : alltrue([
          for action in group.actions : contains(["Call", "Read", "Write"], action.action_type)
        ])
      ])
    ])
    error_message = "All management action types must be one of: Call, Read, or Write."
  }
}

