variable "resource_group_name" {
  type        = string
  description = "The name for the resource group."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "The tags to add to the resources."
  default     = null
}
