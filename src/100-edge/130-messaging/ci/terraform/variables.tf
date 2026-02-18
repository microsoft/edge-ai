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
 * Fabric RTI Variables - Optional
 */

variable "fabric_eventstream_endpoint" {
  type = object({
    bootstrap_server = string
    topic_name       = string
    endpoint_type    = string
  })
  description = "Fabric RTI connection details from EventStream. If provided, creates a Fabric RTI dataflow endpoint."
  default     = null
}

variable "fabric_workspace" {
  type = object({
    id           = string
    display_name = string
  })
  description = "Fabric workspace for RTI resources. Required when fabric_eventstream_endpoint is provided."
  default     = null
}

/*
 * Dataflow Graphs Variables - Optional
 */

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


