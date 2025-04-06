output "aio_ca" {
  value = {
    root_ca_cert_pem  = tls_self_signed_cert.root_ca.cert_pem
    ca_cert_chain_pem = "${tls_locally_signed_cert.intermediate_ca.cert_pem}${tls_self_signed_cert.root_ca.cert_pem}"
    ca_key_pem        = tls_private_key.intermediate_ca.private_key_pem
  }
}
