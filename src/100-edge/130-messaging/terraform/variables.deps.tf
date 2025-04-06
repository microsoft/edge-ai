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

variable "event_hub" {
  description = "Values for the existing Event Hub namespace and Event Hub"
  type = object({
    namespace_name = string
    event_hub_name = string
  })
  default = null
}

variable "event_grid" {
  description = "Values for the existing Event Grid"
  type = object({
    topic_name = string
    endpoint   = string
  })
  default = null
}
