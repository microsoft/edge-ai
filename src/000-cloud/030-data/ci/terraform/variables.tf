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

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
  default     = "001"
}

/*
 * Schema Parameters - Optional
 */

variable "schemas" {
  type = list(object({
    name         = string
    display_name = optional(string)
    description  = optional(string)
    format       = optional(string, "JsonSchema/draft-07")
    type         = optional(string, "MessageSchema")
    versions = map(object({
      description = string
      content     = string
    }))
  }))
  description = "List of schemas to create in the schema registry with their versions"
  default = [
    {
      name         = "temperature-schema"
      display_name = "Temperature Schema"
      description  = "Schema for temperature sensor data"
      format       = "JsonSchema/draft-07"
      type         = "MessageSchema"
      versions = {
        "1" = {
          description = "Initial version"
          content     = "{\"$schema\":\"http://json-schema.org/draft-07/schema#\",\"name\":\"temperature-schema\",\"type\":\"object\",\"properties\":{\"temperature\":{\"type\":\"object\",\"properties\":{\"value\":{\"type\":\"number\"},\"unit\":{\"type\":\"string\"}},\"required\":[\"value\",\"unit\"]}},\"required\":[\"temperature\"]}"
        }
      }
    }
  ]

  validation {
    condition = alltrue([
      for schema in var.schemas :
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", schema.name)) && length(schema.name) >= 3 && length(schema.name) <= 63
    ])
    error_message = "Schema name must be 3-63 characters, contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }

  validation {
    condition = alltrue([
      for schema in var.schemas :
      length(schema.versions) > 0
    ])
    error_message = "Each schema must have at least one version defined."
  }
}
