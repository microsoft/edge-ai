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
  description = "Certificate data to write to Key Vault. Can come from terraform-certificate-generation module or external source."
  sensitive   = true
}

variable "cluster_a_name" {
  type        = string
  description = "The name identifier for Cluster A"
}

variable "cluster_b_name" {
  type        = string
  description = "The name identifier for Cluster B"
}

variable "cluster_a_key_vault_id" {
  type        = string
  description = "Resource ID of the Key Vault for cluster A."
}

variable "cluster_b_key_vault_id" {
  type        = string
  description = "Resource ID of the Key Vault for cluster B."
}
