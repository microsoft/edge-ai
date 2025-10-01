/**
 * # Variables for CI - Kubernetes Assets
 *
 * This file defines variables for the CI environment.
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

variable "should_create_default_asset" {
  type        = bool
  description = "Whether to create a default asset. Otherwise, false."
  default     = false
}

variable "namespaced_devices" {
  type = list(object({
    name = string
    endpoints = object({
      outbound = optional(object({
        assigned = object({})
      }), { assigned = {} })
      inbound = map(object({
        endpoint_type = string
        address       = string
        version       = optional(string, "1.0")
        authentication = object({
          method = string
        })
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
    device_ref = object({
      device_name   = string
      endpoint_name = string
    })
    description       = optional(string)
    documentation_uri = optional(string)
    enabled           = optional(bool, true)
    hardware_revision = optional(string)
    manufacturer      = optional(string)
    manufacturer_uri  = optional(string)
    model             = optional(string)
    product_code      = optional(string)
    serial_number     = optional(string)
    software_revision = optional(string)
    attributes        = optional(map(string), {})
    datasets = optional(list(object({
      name = string
      data_points = list(object({
        name                     = string
        data_source              = string
        data_point_configuration = optional(string)
      }))
      destinations = optional(list(object({
        target = string
        configuration = object({
          topic  = optional(string)
          retain = optional(string)
          qos    = optional(string)
        })
      })), [])
    })), [])
    default_datasets_configuration = optional(string)
    default_events_configuration   = optional(string)
  }))
  description = "List of namespaced assets to create. Otherwise, an empty list."
  default     = []
}

