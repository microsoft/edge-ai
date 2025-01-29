variable "resource_group" {
  type = object({
    id   = string
    name = string
  })
  description = "Name and ID of the pre-existing resource group in which to create resources"
}
variable "custom_location_id" {
  type        = string
  description = "The resource ID of the Custom Location."
}

variable "connected_cluster_location" {
  type        = string
  description = "The location of the connected cluster resource"
}

variable "connected_cluster_name" {
  type        = string
  description = "The name of the connected cluster to deploy Azure IoT Operations to"
}

variable "enable_instance_secret_sync" {
  type        = bool
  description = "Whether to enable secret sync on the Azure IoT Operations instance"
}

variable "key_vault" {
  type = object({
    name = string
    id   = string
  })
  description = "The name and id of the existing key vault for Azure IoT Operations instance"
}

variable "sse_user_managed_identity" {
  type = object({
    id        = string
    client_id = string
  })
  description = "Secret Sync Extension user managed identity id and client id"
}
variable "aio_namespace" {
  type        = string
  description = "Azure IoT Operations namespace"
}

variable "aio_user_managed_identity_id" {
  type        = string
  description = "ID of the User Assigned Managed Identity for the Azure IoT Operations instance"

}
