variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
}

variable "custom_location_id" {
  type        = string
  description = "The id of the custom location to deploy Azure IoT Operations to"
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
  description = "The name of the Event Hub namespace"
}

variable "aio_uami_tenant_id" {
  type        = string
  description = "Tenant ID of the User Assigned Managed Identity for the Azure IoT Operations instance"
}

variable "aio_uami_client_id" {
  type        = string
  description = "Client ID of the User Assigned Managed Identity for the Azure IoT Operations instance"
}
