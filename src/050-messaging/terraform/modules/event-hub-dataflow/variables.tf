variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
}

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc..."
}

variable "custom_location_id" {
  type        = string
  description = "The resource ID of the Custom Location."
}

variable "event_hub" {
  type = object({
    namespace_name = string
    event_hub_name = string
  })
  description = "Values for the existing Event Hub namespace and Event Hub"
}

variable "asset_name" {
  type        = string
  description = "The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud."
}

variable "aio_uami_tenant_id" {
  type        = string
  description = "Tenant ID of the User Assigned Managed Identity for the Azure IoT Operations instance"
}

variable "aio_uami_client_id" {
  type        = string
  description = "Client ID of the User Assigned Managed Identity for the Azure IoT Operations instance"
}
