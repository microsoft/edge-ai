variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
}

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
}

variable "custom_location_id" {
  type        = string
  description = "The resource ID of the Custom Location"
}

variable "asset_name" {
  type        = string
  description = "The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud."
}
