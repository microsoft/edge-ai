/*
 * Required Variables - Infrastructure Dependencies
 */

variable "fabric_workspace" {
  type = object({
    id           = string
    display_name = string
  })
  description = "Fabric workspace for RTI resources. Required when fabric_eventstream_endpoint is provided."
}
