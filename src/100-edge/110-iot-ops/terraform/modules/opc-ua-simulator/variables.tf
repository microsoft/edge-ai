variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "resource_group" {
  type = object({
    id   = string
    name = string
  })
  description = "Name and ID of the pre-existing resource group in which to create resources"
}

variable "connected_cluster_name" {
  type        = string
  description = "The name of the connected cluster to deploy Azure IoT Operations to"
}

variable "custom_location_id" {
  type        = string
  description = "The resource ID of the Custom Location."
}

variable "should_enable_opc_sim_asset_discovery" {
  type        = bool
  description = "Whether to enable the Asset Discovery preview feature for OPC UA simulator. This will add the value of `{\"runAssetDiscovery\":true}` to the additionalConfiguration for the Asset Endpoint Profile."
}

variable "opc_sim_additional_config_string" {
  type        = string
  description = "Custom additionalConfiguration string for the Asset Endpoint Profile. If provided, this takes precedence over should_enable_opc_sim_asset_discovery setting."
}
