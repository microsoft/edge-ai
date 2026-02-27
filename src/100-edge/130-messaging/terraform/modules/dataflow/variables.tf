/*
 * Dataflow Dependency Parameters
 */

variable "aio_dataflow_profile" {
  type = object({
    id = string
  })
  description = "The AIO dataflow profile object"
}

variable "custom_location" {
  type = object({
    id = string
  })
  description = "The custom location object"
}

/*
 * Dataflow Parameters
 */

variable "dataflows" {
  type = list(object({
    name                     = string
    mode                     = optional(string)
    request_disk_persistence = optional(string)
    operations = list(object({
      operationType = string
      name          = optional(string)
      sourceSettings = optional(object({
        endpointRef         = string
        assetRef            = optional(string)
        serializationFormat = optional(string)
        schemaRef           = optional(string)
        dataSources         = list(string)
      }))
      builtInTransformationSettings = optional(object({
        serializationFormat = optional(string)
        schemaRef           = optional(string)
        datasets = optional(list(object({
          key         = string
          description = optional(string)
          schemaRef   = optional(string)
          inputs      = list(string)
          expression  = string
        })))
        filter = optional(list(object({
          type        = optional(string)
          description = optional(string)
          inputs      = list(string)
          expression  = string
        })))
        map = optional(list(object({
          type        = optional(string)
          description = optional(string)
          inputs      = list(string)
          expression  = optional(string)
          output      = string
        })))
      }))
      destinationSettings = optional(object({
        endpointRef     = string
        dataDestination = string
      }))
    }))
  }))
  description = "List of dataflows to create with their operation configurations"

  validation {
    condition = alltrue([
      for df in var.dataflows :
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", df.name)) && length(df.name) >= 3 && length(df.name) <= 63
    ])
    error_message = "Dataflow name must be 3-63 characters, contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }

  validation {
    condition = alltrue([
      for df in var.dataflows :
      contains(["Enabled", "Disabled"], df.mode)
    ])
    error_message = "Dataflow mode must be either 'Enabled' or 'Disabled'."
  }

  validation {
    condition = alltrue([
      for df in var.dataflows :
      contains(["Enabled", "Disabled"], df.request_disk_persistence)
    ])
    error_message = "Dataflow request_disk_persistence must be either 'Enabled' or 'Disabled'."
  }

  validation {
    condition = alltrue([
      for df in var.dataflows : alltrue([
        for op in df.operations :
        contains(["Source", "Destination", "BuiltInTransformation"], op.operationType)
      ])
    ])
    error_message = "Operation type must be one of: 'Source', 'Destination', or 'BuiltInTransformation'."
  }

  validation {
    condition = alltrue([
      for df in var.dataflows : alltrue([
        for op in df.operations :
        op.operationType != "Source" || op.sourceSettings != null
      ])
    ])
    error_message = "Source operations must include sourceSettings."
  }

  validation {
    condition = alltrue([
      for df in var.dataflows : alltrue([
        for op in df.operations :
        op.operationType != "Destination" || op.destinationSettings != null
      ])
    ])
    error_message = "Destination operations must include destinationSettings."
  }
}
