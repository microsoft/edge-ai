/*
 * Required Variables - Infrastructure Dependencies
 */

variable "aio_instance" {
  type = object({
    id = string
  })
  description = "The Azure IoT Operations instance."
}

variable "aio_dataflow_profile" {
  type = object({
    id = string
  })
  description = "The AIO dataflow profile."
}

variable "aio_identity" {
  type = object({
    id           = string
    principal_id = string
    tenant_id    = string
    client_id    = string
  })
  description = "Azure IoT Operations managed identity for Fabric workspace access."
}

variable "fabric_eventstream_endpoint" {
  type = object({
    bootstrap_server = string
    topic_name       = string
    endpoint_type    = string
  })
  description = "Fabric RTI connection details from EventStream."
}

variable "fabric_workspace" {
  type = object({
    id           = string
    display_name = string
  })
  description = "Fabric workspace for RTI resources."
}
