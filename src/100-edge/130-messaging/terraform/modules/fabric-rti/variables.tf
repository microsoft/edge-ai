variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module."
}

variable "environment" {
  type        = string
  description = "Environment for all resources in this module."
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources."
}

variable "custom_location_id" {
  type        = string
  description = "The custom location ID for Azure IoT Operations."
}

variable "asset_name" {
  type        = string
  description = "The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud."
}
