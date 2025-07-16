/*
 * Certificate Generation Outputs
 */

output "server_root_ca_cert" {
  description = "Server Root CA certificate."
  value       = tls_self_signed_cert.server_root_ca.cert_pem
  sensitive   = false
}

output "server_intermediate_ca_cert" {
  description = "Server Intermediate CA certificate."
  value       = tls_locally_signed_cert.server_intermediate_ca.cert_pem
  sensitive   = false
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

output "client_intermediate_ca_cert" {
  description = "Client Intermediate CA certificate."
  value       = tls_locally_signed_cert.client_intermediate_ca.cert_pem
  sensitive   = false
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

output "certificate_files" {
  description = "List of certificate files created by this module."
  value = [
    local_file.server_root_ca_cert.filename,
    local_file.server_root_ca_key.filename,
    local_file.server_intermediate_ca_cert.filename,
    local_file.server_intermediate_ca_key.filename,
    local_file.server_leaf_cert.filename,
    local_file.server_leaf_key.filename,
    local_file.client_root_ca_cert.filename,
    local_file.client_root_ca_key.filename,
    local_file.client_intermediate_ca_cert.filename,
    local_file.client_intermediate_ca_key.filename,
    local_file.client_leaf_cert.filename,
    local_file.client_leaf_key.filename,
  ]
  sensitive = false
}

output "certificate_dependency" {
  description = "Dependency marker for certificate generation completion."
  value       = "terraform-certificates-generated"
}
