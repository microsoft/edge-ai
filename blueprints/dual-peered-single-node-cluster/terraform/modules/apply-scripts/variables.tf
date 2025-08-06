variable "aio_namespace" {
  type        = string
  description = "Azure IoT Operations namespace"
}

variable "enterprise_client_ca_configmap_name" {
  type        = string
  description = "The name of the Kubernetes configmap containing the client CA certificate"
}

variable "site_tls_ca_configmap_name" {
  type        = string
  description = "The name of the Kubernetes configmap containing the TLS CA certificate"
}

variable "enterprise_synced_certificates_secret_name" {
  type        = string
  description = "The name of the Kubernetes secret containing certificates synced from Key Vault for the enterprise cluster (Cluster A)."
  default     = "certificates-sync-a"
}

variable "site_synced_certificates_secret_name" {
  type        = string
  description = "The name of the Kubernetes secret containing certificates synced from Key Vault for the site cluster (Cluster B)."
  default     = "certificates-sync-b"
}

variable "arc_connected_cluster_a" {
  type = object({
    name = string
  })
}

variable "arc_connected_cluster_b" {
  type = object({
    name = string
  })
}



variable "cluster_a_resource_group" {
  type = object({
    name = string
  })
  description = "The resource group for Cluster A."
}

variable "cluster_b_resource_group" {
  type = object({
    name = string
  })
  description = "The resource group for Cluster B."
}

variable "cluster_a_secret_sync_identity" {
  type = object({
    client_id = string
  })
  description = "The secret sync identity for Cluster A."
}

variable "cluster_b_secret_sync_identity" {
  type = object({
    client_id = string
  })
  description = "The secret sync identity for Cluster B."
}

variable "cluster_a_key_vault" {
  type = object({
    name = string
  })
  description = "The Key Vault for Cluster A."
}

variable "cluster_b_key_vault" {
  type = object({
    name = string
  })
  description = "The Key Vault for Cluster B."
}
