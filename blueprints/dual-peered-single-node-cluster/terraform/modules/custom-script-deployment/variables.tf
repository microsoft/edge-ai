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

variable "certificates" {
  type = object({
    server_root_ca_cert         = string
    server_root_ca_key          = string
    server_intermediate_ca_cert = string
    server_intermediate_ca_key  = string
    server_leaf_cert            = string
    server_leaf_key             = string
    client_root_ca_cert         = string
    client_root_ca_key          = string
    client_intermediate_ca_cert = string
    client_intermediate_ca_key  = string
    client_leaf_cert            = string
    client_leaf_key             = string
  })
  description = "Certificate data to use in scripts. Can come from terraform-certificate-generation module or external source."
  sensitive   = true
  default     = null
}

variable "cluster_config_ca" {
  type        = string
  description = "The CA certificate for cluster configuration."
  default     = ""
}
