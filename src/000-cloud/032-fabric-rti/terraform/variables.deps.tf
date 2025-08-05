/*
 * Required Variables - Infrastructure Dependencies
 */

variable "fabric_workspace" {
  type = object({
    id           = string
    display_name = string
  })
  description = "Fabric workspace for RTI resources."
}
