variable "label_prefix" {
  type        = string
  description = "Prefix to be used for all resource names"
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name for all resources in this module"
}