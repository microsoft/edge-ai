/**
 * # Generate AIO CA
 *
 * Generates a Root CA and Intermediate CA for use with Azure IoT Operations (AIO).
 *
 */


# Generate Root CA private key
resource "tls_private_key" "root_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
  rsa_bits    = 4096
}

# Generate Root CA self-signed certificate
resource "tls_self_signed_cert" "root_ca" {
  private_key_pem = tls_private_key.root_ca.private_key_pem
  subject {
    common_name = "AIO Root CA"
  }
  validity_period_hours = 87600
  is_ca_certificate     = true
  set_authority_key_id  = true
  set_subject_key_id    = true
  allowed_uses          = ["cert_signing"]
}

# Generate Intermediate CA private key
resource "tls_private_key" "intermediate_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
  rsa_bits    = 4096
}

# Generate Intermediate CA certificate signing request (CSR)
resource "tls_cert_request" "intermediate_ca" {
  private_key_pem = tls_private_key.intermediate_ca.private_key_pem
  subject {
    common_name = "AIO Intermediate CA"
  }
}

# Sign the Intermediate CA CSR with the Root CA private key to generate the Intermediate CA certificate
resource "tls_locally_signed_cert" "intermediate_ca" {
  cert_request_pem      = tls_cert_request.intermediate_ca.cert_request_pem
  ca_cert_pem           = tls_self_signed_cert.root_ca.cert_pem
  ca_private_key_pem    = tls_private_key.root_ca.private_key_pem
  validity_period_hours = 8760
  is_ca_certificate     = true
  allowed_uses          = ["cert_signing"]
}
