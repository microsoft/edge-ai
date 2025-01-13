variable "resource_group_name" {
  type        = string
  description = "Name of the pre-existing resource group in which to create resources"
}

variable "resource_group_id" {
  type        = string
  description = "ID of the resource group to create resources in"
}

variable "connected_cluster_name" {
  type        = string
  description = "The name of the connected cluster to deploy Azure IoT Operations to"
}

variable "key_vault_name" {
  type        = string
  description = "The name of the existing key vault for Azure IoT Operations instance"
}

variable "sse_user_managed_identity_name" {
  type        = string
  description = "Secret Sync Extension user managed identity name"
}

variable "aio_root_ca" {
  type = object({
    cert_pem        = string
    private_key_pem = string
  })
  sensitive   = true
  description = "Root CA for the MQTT broker"
}

variable "customer_managed_trust_settings" {
  type = object({
    issuerName    = string
    issuerKind    = string
    configMapName = string
    configMapKey  = string
  })
  description = "Settings for CustomerManaged trust resources"
}

variable "aio_namespace" {
  type        = string
  description = "Azure IoT Operations namespace"
}
