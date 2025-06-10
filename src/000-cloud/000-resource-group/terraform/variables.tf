variable "resource_group_name" {
  type        = string
  description = "The name for the resource group. If not provided, a default name will be generated using resource_prefix, environment, and instance."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "The tags to add to the resources."
  default     = null
}
