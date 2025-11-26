/*
 * Required Variables
 */

variable "snet_azureml" {
  description = "Subnet for the Azure ML compute cluster."
  type = object({
    id   = string
    name = optional(string)
  })
}
