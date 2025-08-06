/*
 * Certificate Generation Outputs
 */

output "server_root_ca_cert" {
  description = "Server Root CA certificate."
  value       = tls_self_signed_cert.server_root_ca.cert_pem
  sensitive   = false
}

output "server_root_ca_key" {
  description = "Server Root CA private key."
  value       = tls_private_key.server_root_ca.private_key_pem
  sensitive   = true
}

output "server_intermediate_ca_cert" {
  description = "Server Intermediate CA certificate."
  value       = tls_locally_signed_cert.server_intermediate_ca.cert_pem
  sensitive   = false
}

output "server_intermediate_ca_key" {
  description = "Server Intermediate CA private key."
  value       = tls_private_key.server_intermediate_ca.private_key_pem
  sensitive   = true
}

output "server_leaf_cert" {
  description = "Server leaf certificate (bundled with chain)."
  value       = local.server_cert_bundle
  sensitive   = false
}

output "server_leaf_key" {
  description = "Server leaf certificate private key."
  value       = tls_private_key.server_leaf.private_key_pem
  sensitive   = true
}

output "client_root_ca_cert" {
  description = "Client Root CA certificate."
  value       = tls_self_signed_cert.client_root_ca.cert_pem
  sensitive   = false
}

output "client_root_ca_key" {
  description = "Client Root CA private key."
  value       = tls_private_key.client_root_ca.private_key_pem
  sensitive   = true
}

output "client_intermediate_ca_cert" {
  description = "Client Intermediate CA certificate."
  value       = tls_locally_signed_cert.client_intermediate_ca.cert_pem
  sensitive   = false
}

output "client_intermediate_ca_key" {
  description = "Client Intermediate CA private key."
  value       = tls_private_key.client_intermediate_ca.private_key_pem
  sensitive   = true
}

output "client_leaf_cert" {
  description = "Client leaf certificate (bundled with chain)."
  value       = local.client_cert_bundle
  sensitive   = false
}

output "client_leaf_key" {
  description = "Client leaf certificate private key."
  value       = tls_private_key.client_leaf.private_key_pem
  sensitive   = true
}

/*
 * Clustered Certificate Output
 */

output "certificates" {
  description = "All generated certificates and keys in a single object."
  value = {
    server_root_ca_cert         = tls_self_signed_cert.server_root_ca.cert_pem
    server_root_ca_key          = tls_private_key.server_root_ca.private_key_pem
    server_intermediate_ca_cert = tls_locally_signed_cert.server_intermediate_ca.cert_pem
    server_intermediate_ca_key  = tls_private_key.server_intermediate_ca.private_key_pem
    server_leaf_cert            = local.server_cert_bundle
    server_leaf_key             = tls_private_key.server_leaf.private_key_pem
    client_root_ca_cert         = tls_self_signed_cert.client_root_ca.cert_pem
    client_root_ca_key          = tls_private_key.client_root_ca.private_key_pem
    client_intermediate_ca_cert = tls_locally_signed_cert.client_intermediate_ca.cert_pem
    client_intermediate_ca_key  = tls_private_key.client_intermediate_ca.private_key_pem
    client_leaf_cert            = local.client_cert_bundle
    client_leaf_key             = tls_private_key.client_leaf.private_key_pem
  }
  sensitive = true
}
