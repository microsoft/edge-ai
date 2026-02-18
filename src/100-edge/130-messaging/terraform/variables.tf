/*
 * Optional Variables
 */

variable "asset_name" {
  type        = string
  description = "The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud."
  default     = "namespace-oven"
}

variable "adr_namespace" {
  type = object({
    id   = string,
    name = string
  })
  description = "Azure Device Registry namespace to use with Azure IoT Operations. Otherwise, not configured."
  default     = null
}

variable "should_create_eventgrid_dataflows" {
  type        = bool
  description = "Whether to create EventGrid dataflows in the edge messaging component"
  default     = true
}

variable "should_create_eventhub_dataflows" {
  type        = bool
  description = "Whether to create EventHub dataflows in the edge messaging component"
  default     = true
}

variable "should_create_fabric_rti_dataflows" {
  type        = bool
  description = "Whether to create fabric RTI dataflows."
  default     = false
}

variable "dataflow_graphs" {
  type = list(object({
    name                     = string
    mode                     = optional(string, "Enabled")
    request_disk_persistence = optional(string, "Disabled")
    nodes = list(object({
      nodeType = string
      name     = string
      sourceSettings = optional(object({
        endpointRef = string
        dataSources = list(string)
      }))
      graphSettings = optional(object({
        registryEndpointRef = string
        artifact            = string
        configuration = optional(list(object({
          key   = string
          value = string
        })))
      }))
      destinationSettings = optional(object({
        endpointRef     = string
        dataDestination = string
      }))
    }))
    node_connections = list(object({
      from = object({
        name = string
        schema = optional(object({
          schemaRef           = string
          serializationFormat = optional(string, "Json")
        }))
      })
      to = object({
        name = string
      })
    }))
  }))
  description = "List of dataflow graphs to create with their node configurations"
  default     = []

  validation {
    condition = alltrue([
      for graph in var.dataflow_graphs :
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", graph.name)) && length(graph.name) >= 3 && length(graph.name) <= 63
    ])
    error_message = "Dataflow graph name must be 3-63 characters, contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }

  validation {
    condition = alltrue([
      for graph in var.dataflow_graphs :
      contains(["Enabled", "Disabled"], graph.mode)
    ])
    error_message = "Dataflow graph mode must be either 'Enabled' or 'Disabled'."
  }

  validation {
    condition = alltrue([
      for graph in var.dataflow_graphs :
      contains(["Enabled", "Disabled"], graph.request_disk_persistence)
    ])
    error_message = "Dataflow graph request_disk_persistence must be either 'Enabled' or 'Disabled'."
  }

  validation {
    condition = alltrue([
      for graph in var.dataflow_graphs : alltrue([
        for node in graph.nodes :
        contains(["Source", "Graph", "Destination"], node.nodeType)
      ])
    ])
    error_message = "Node type must be one of: 'Source', 'Graph', or 'Destination'."
  }
}
