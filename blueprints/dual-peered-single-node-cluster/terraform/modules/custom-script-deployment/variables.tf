variable "should_deploy_server_central_script" {
  type        = bool
  description = "Whether to deploy the server-central.sh script to the server VM."
}

variable "should_deploy_client_technology_script" {
  type        = bool
  description = "Whether to deploy the client-technology.sh script to the client VM."
}

variable "server_vm_id" {
  type        = string
  description = "The resource ID of the server VM (Cluster A)."
}

variable "client_vm_id" {
  type        = string
  description = "The resource ID of the client VM (Cluster B)."
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

variable "cluster_a_name" {
  type        = string
  description = "The name identifier for Cluster A."
}

variable "cluster_b_name" {
  type        = string
  description = "The name identifier for Cluster B."
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
