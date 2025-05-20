variable "resource_group_name" {
  type        = string
  description = "The name for the resource group. If not provided, a default name will be generated using resource_prefix, environment, and instance."
  default     = null
}

variable "use_existing_resource_group" {
  type        = bool
  description = "Whether to use an existing resource group instead of creating a new one. When true, the component will look up a resource group with the specified or generated name instead of creating it."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "The tags to add to the resources."
  default     = null
}
