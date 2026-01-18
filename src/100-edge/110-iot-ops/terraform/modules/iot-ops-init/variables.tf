variable "arc_connected_cluster_id" {
  type        = string
  description = "The resource ID of the connected cluster to deploy Azure IoT Operations Platform to"
}

variable "secret_sync_controller" {
  type = object({
    version = string
    train   = string
  })
}

variable "resource_group" {
  type = object({
    id   = string
    name = string
  })
  description = "Resource group object containing name and id where resources will be deployed"
}

variable "connected_cluster_name" {
  type        = string
  description = "The name of the connected cluster to deploy Azure IoT Operations to"
}

variable "secret_sync_identity" {
  type = object({
    id        = string
    client_id = string
  })
  description = "Secret Sync Extension user managed identity id and client id"
}

variable "enable_instance_secret_sync" {
  type        = bool
  description = "Whether to enable secret sync on the Azure IoT Operations instance"
}

variable "aio_namespace" {
  type        = string
  description = "Azure IoT Operations namespace"
}

variable "aio_user_managed_identity_id" {
  type        = string
  description = "ID of the User Assigned Managed Identity for the Azure IoT Operations instance"
}
