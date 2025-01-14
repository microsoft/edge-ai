variable "resource_group_id" {
  type        = string
  description = "Resource group ID to scope the role assignment to"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
}
