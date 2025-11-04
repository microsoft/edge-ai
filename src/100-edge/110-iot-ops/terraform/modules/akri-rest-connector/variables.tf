/*
 * Required Variables
 */

variable "aio_instance_id" {
  type        = string
  description = "Azure IoT Operations instance ID where the connector template will be deployed."
}

variable "custom_location_id" {
  type        = string
  description = "Custom location ID for the Azure IoT Operations deployment."
}

/*
 * Common Variables passed from parent module
 */

variable "environment" {
  type        = string
  description = "The deployment environment (e.g., dev, staging, prod)."
  default     = "dev"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resource names."
  default     = "aio"
}

variable "location" {
  type        = string
  description = "The Azure region where resources are deployed."
  default     = "eastus2"
}

/*
 * Connector Configuration
 */

variable "akri_rest_connector_config" {
  type = object({
    template_name        = optional(string, "rest-http-connector")
    image_tag            = optional(string, "latest")
    log_level            = optional(string, "Info")
    replicas             = optional(number, 1)
    mqtt_broker_host     = optional(string, "aio-mq-dmqtt-frontend:8883")
    mqtt_broker_audience = optional(string, "aio-mq")
    mqtt_ca_configmap    = optional(string, "aio-ca-trust-bundle-test-only")
  })
  default     = {}
  description = "Configuration for the Akri REST HTTP Connector template"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", coalesce(var.akri_rest_connector_config.template_name, "rest-http-connector")))
    error_message = "Connector template name must contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }

  validation {
    condition     = contains(["Trace", "Debug", "Info", "Warning", "Error", "Critical"], coalesce(var.akri_rest_connector_config.log_level, "Info"))
    error_message = "Log level must be one of: Trace, Debug, Info, Warning, Error, Critical."
  }

  validation {
    condition     = coalesce(var.akri_rest_connector_config.replicas, 1) >= 1 && coalesce(var.akri_rest_connector_config.replicas, 1) <= 10
    error_message = "Connector replicas must be between 1 and 10."
  }
}
