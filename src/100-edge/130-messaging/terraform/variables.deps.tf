/*
 * Required Variables
 */

variable "aio_identity" {
  type = object({
    id           = string
    principal_id = string
    tenant_id    = string
    client_id    = string
  })
}

variable "aio_custom_locations" {
  type = object({
    name = string
    id   = string
  })
}

variable "aio_instance" {
  type = object({
    id = string
  })
}

variable "aio_dataflow_profile" {
  type = object({
    id = string
  })
}

/*
 * Optional
 */

variable "eventhub" {
  description = "Values for the existing Event Hub namespace and Event Hub"
  type = object({
    namespace_name = string
    eventhub_name  = string
  })
  default = null
}

variable "eventgrid" {
  description = "Values for the existing Event Grid"
  type = object({
    topic_name = string
    endpoint   = string
  })
  default = null
}

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
