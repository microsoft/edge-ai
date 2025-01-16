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

variable "aio_ca" {
  type = object({
    root_ca_cert_pem  = string
    ca_cert_chain_pem = string
    ca_key_pem        = string
  })
  sensitive   = true
  description = "Intermediate CA with Root CA certificate for the MQTT broker"
}

variable "customer_managed_trust_settings" {
  type = object({
    issuer_name    = string
    issuer_kind    = string
    configmap_name = string
    configmap_key  = string
  })
  description = "Settings for CustomerManaged trust resources"
}

variable "aio_namespace" {
  type        = string
  description = "Azure IoT Operations namespace"
}
