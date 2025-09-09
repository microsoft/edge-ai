/*
 * Cluster A Configuration
 */

variable "cluster_a_custom_location_id" {
  type        = string
  description = "The custom location ID for Cluster A."
}

variable "cluster_a_key_vault" {
  type = object({
    name = string
  })
  description = "The Key Vault for Cluster A."
}

variable "cluster_a_location" {
  type        = string
  description = "The Azure location for Cluster A resources."
}

variable "cluster_a_name" {
  type        = string
  description = "The name identifier for Cluster A"
}

variable "cluster_a_resource_group" {
  type = object({
    id = string
  })
  description = "The resource group for Cluster A."
}

variable "cluster_a_secret_sync_identity" {
  type = object({
    client_id = string
  })
  description = "The secret sync identity for Cluster A."
}

/*
 * Cluster B Configuration
 */

variable "cluster_b_custom_location_id" {
  type        = string
  description = "The custom location ID for Cluster B."
}

variable "cluster_b_key_vault" {
  type = object({
    name = string
  })
  description = "The Key Vault for Cluster B."
}

variable "cluster_b_location" {
  type        = string
  description = "The Azure location for Cluster B resources."
}

variable "cluster_b_name" {
  type        = string
  description = "The name identifier for Cluster B"
}

variable "cluster_b_resource_group" {
  type = object({
    id = string
  })
  description = "The resource group for Cluster B."
}

variable "cluster_b_secret_sync_identity" {
  type = object({
    client_id = string
  })
  description = "The secret sync identity for Cluster B."
}

/*
 * Certificate Sync Configuration
 */
variable "site_client_secret_name" {
  type        = string
  description = "The name of the Kubernetes secret containing the client certificate and key"
}

variable "enterprise_broker_tls_cert_secret_name" {
  type        = string
  description = "The name of the Kubernetes secret containing the broker tls certificate"
}

variable "cluster_a_synced_certificates_secret_name" {
  type        = string
  description = "The name of the Kubernetes secret where certificates will be synced from Key Vault for Cluster A."
  default     = "certificates-sync-a"
}

variable "cluster_b_synced_certificates_secret_name" {
  type        = string
  description = "The name of the Kubernetes secret where certificates will be synced from Key Vault for Cluster B."
  default     = "certificates-sync-b"
}
