variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc..."
  default     = "001"
}

variable "resource_group_name" {
  type        = string
  description = "The name for the resource group. (Otherwise, 'rg-{var.resource_prefix}-{var.environment}-{var.instance}')"
  default     = null
}

variable "custom_locations_name" {
  type        = string
  description = "The name of the Custom Locations resource used by Azure IoT Operations. (Otherwise, '{var.connected_cluster_name}-cl')"
  default     = null
}

variable "connected_cluster_name" {
  type        = string
  description = "The name of the Azure Arc connected cluster resource for Azure IoT Operations. (Otherwise, '{var.resource_prefix}-arc')"
  default     = null
}

variable "iot_ops_k8s_extension_name" {
  type        = string
  description = "The name of the Azure Arc Extension for Azure IoT Operations, needed to assign permissions. (Should be changed to a UAMI)"
  default     = "iot-ops"
}

variable "iot_ops_instance_name" {
  type        = string
  description = "The name of the Azure IoT Operations Instance resource. (Otherwise, '{var.connected_cluster_name}-ops-instance')"
  default     = null
}

variable "asset_name" {
  type        = string
  description = "The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud."
  default     = "oven"
}
