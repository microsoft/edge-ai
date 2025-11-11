/*
 * Akri Connector Configuration - Optional
 */

variable "should_enable_akri_rest_connector" {
  type        = bool
  default     = false
  description = "Deploy Akri REST HTTP Connector template to the IoT Operations instance."
}

variable "should_enable_akri_media_connector" {
  type        = bool
  default     = false
  description = "Deploy Akri Media Connector template to the IoT Operations instance."
}

variable "should_enable_akri_onvif_connector" {
  type        = bool
  default     = false
  description = "Deploy Akri ONVIF Connector template to the IoT Operations instance."
}

variable "should_enable_akri_sse_connector" {
  type        = bool
  default     = false
  description = "Deploy Akri SSE Connector template to the IoT Operations instance."
}

variable "custom_akri_connectors" {
  type = list(object({
    name = string
    type = string // "rest", "media", "onvif", "sse", "custom"

    // Custom Connector Fields (required when type = "custom")
    custom_endpoint_type    = optional(string) // e.g., "Contoso.Modbus", "Acme.CustomProtocol"
    custom_image_name       = optional(string) // e.g., "my_acr.azurecr.io/custom-connector"
    custom_endpoint_version = optional(string, "1.0")

    // Runtime Configuration (defaults applied based on connector type)
    registry          = optional(string) // Defaults: mcr.microsoft.com for built-in types
    image_tag         = optional(string) // Defaults: 0.5.1 for built-in types, latest for custom
    replicas          = optional(number, 1)
    image_pull_policy = optional(string) // Default: IfNotPresent

    // Diagnostics
    log_level = optional(string) // Default: info (lowercase: trace, debug, info, warning, error, critical)

    // MQTT Override (uses shared config if not provided)
    mqtt_config = optional(object({
      host                   = string
      audience               = string
      ca_configmap           = string
      keep_alive_seconds     = optional(number, 60)
      max_inflight_messages  = optional(number, 100)
      session_expiry_seconds = optional(number, 600)
    }))

    // Optional Advanced Fields
    aio_min_version = optional(string)
    aio_max_version = optional(string)
    allocation = optional(object({
      policy      = string // "Bucketized"
      bucket_size = number // 1-100
    }))
    additional_configuration = optional(map(string))
    secrets = optional(list(object({
      secret_alias = string
      secret_key   = string
      secret_ref   = string
    })))
    trust_settings = optional(object({
      trust_list_secret_ref = string
    }))
  }))

  default     = []
  description = <<-EOT
    List of custom Akri connector templates with user-defined endpoint types and container images.
    Supports built-in types (rest, media, onvif, sse) or custom types with custom_endpoint_type and custom_image_name.
    Built-in connectors default to mcr.microsoft.com/azureiotoperations/akri-connectors/connector_type:0.5.1.
  EOT

  validation {
    condition = alltrue([
      for conn in var.custom_akri_connectors :
      contains(["rest", "media", "onvif", "sse", "custom"], conn.type)
    ])
    error_message = "Connector type must be one of: rest, media, onvif, sse, custom."
  }

  validation {
    condition = alltrue([
      for conn in var.custom_akri_connectors :
      conn.type != "custom" || (conn.custom_endpoint_type != null && conn.custom_image_name != null)
    ])
    error_message = "Custom connector types must provide custom_endpoint_type and custom_image_name."
  }

  validation {
    condition = alltrue([
      for conn in var.custom_akri_connectors :
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", conn.name))
    ])
    error_message = "Connector name must contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }

  validation {
    condition = alltrue([
      for conn in var.custom_akri_connectors :
      contains(["trace", "debug", "info", "warning", "error", "critical"], lower(coalesce(conn.log_level, "info")))
    ])
    error_message = "Log level must be one of: trace, debug, info, warning, error, critical (case insensitive)."
  }

  validation {
    condition = alltrue([
      for conn in var.custom_akri_connectors :
      coalesce(conn.replicas, 1) >= 1 && coalesce(conn.replicas, 1) <= 10
    ])
    error_message = "Connector replicas must be between 1 and 10."
  }
}
