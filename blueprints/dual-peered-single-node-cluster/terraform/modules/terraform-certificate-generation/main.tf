/**
 * # Terraform Certificate Generation Module
 *
 * This module generates TLS certificates using Terraform's native TLS provider
 * instead of executing the Step CLI script. It creates the same certificate
 * hierarchy as the certs.sh script: Root CA, Intermediate CA, and Leaf certificates
 * for both server and client authentication.
 */

# Server Certificate Chain
# ======================

# Server Root CA Private Key
resource "tls_private_key" "server_root_ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Server Root CA Certificate
resource "tls_self_signed_cert" "server_root_ca" {
  private_key_pem = tls_private_key.server_root_ca.private_key_pem

  subject {
    common_name  = "AIO Root CA"
    organization = "Azure IoT Operations"
  }

  validity_period_hours = 8760 * 10 # 10 years

  is_ca_certificate = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

# Server Intermediate CA Private Key
resource "tls_private_key" "server_intermediate_ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Server Intermediate CA Certificate Request
resource "tls_cert_request" "server_intermediate_ca" {
  private_key_pem = tls_private_key.server_intermediate_ca.private_key_pem

  subject {
    common_name  = "AIO Intermediate CA 1"
    organization = "Azure IoT Operations"
  }
}

# Server Intermediate CA Certificate (signed by Root CA)
resource "tls_locally_signed_cert" "server_intermediate_ca" {
  cert_request_pem   = tls_cert_request.server_intermediate_ca.cert_request_pem
  ca_private_key_pem = tls_private_key.server_root_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.server_root_ca.cert_pem

  validity_period_hours = 8760 * 5 # 5 years

  is_ca_certificate = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

# Server Leaf Certificate Private Key
resource "tls_private_key" "server_leaf" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Server Leaf Certificate Request
resource "tls_cert_request" "server_leaf" {
  private_key_pem = tls_private_key.server_leaf.private_key_pem

  subject {
    common_name  = "mqtts-endpoint"
    organization = "Azure IoT Operations"
  }

  dns_names    = ["mqtts-endpoint", "localhost"]
  ip_addresses = [var.server_vm_private_ip, "127.0.0.1"]
}

# Server Leaf Certificate (signed by Intermediate CA)
resource "tls_locally_signed_cert" "server_leaf" {
  cert_request_pem   = tls_cert_request.server_leaf.cert_request_pem
  ca_private_key_pem = tls_private_key.server_intermediate_ca.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.server_intermediate_ca.cert_pem

  validity_period_hours = 2400 # 100 days (same as certs.sh)

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Client Certificate Chain
# ========================

# Client Root CA Private Key
resource "tls_private_key" "client_root_ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Client Root CA Certificate
resource "tls_self_signed_cert" "client_root_ca" {
  private_key_pem = tls_private_key.client_root_ca.private_key_pem

  subject {
    common_name  = "Client Root CA"
    organization = "Azure IoT Operations"
  }

  validity_period_hours = 8760 * 10 # 10 years

  is_ca_certificate = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

# Client Intermediate CA Private Key
resource "tls_private_key" "client_intermediate_ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Client Intermediate CA Certificate Request
resource "tls_cert_request" "client_intermediate_ca" {
  private_key_pem = tls_private_key.client_intermediate_ca.private_key_pem

  subject {
    common_name  = "Client Intermediate CA 1"
    organization = "Azure IoT Operations"
  }
}

# Client Intermediate CA Certificate (signed by Client Root CA)
resource "tls_locally_signed_cert" "client_intermediate_ca" {
  cert_request_pem   = tls_cert_request.client_intermediate_ca.cert_request_pem
  ca_private_key_pem = tls_private_key.client_root_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.client_root_ca.cert_pem

  validity_period_hours = 8760 * 5 # 5 years

  is_ca_certificate = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

# Client Leaf Certificate Private Key
resource "tls_private_key" "client_leaf" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Client Leaf Certificate Request
resource "tls_cert_request" "client_leaf" {
  private_key_pem = tls_private_key.client_leaf.private_key_pem

  subject {
    common_name  = "client"
    organization = "Azure IoT Operations"
  }
}

# Client Leaf Certificate (signed by Client Intermediate CA)
resource "tls_locally_signed_cert" "client_leaf" {
  cert_request_pem   = tls_cert_request.client_leaf.cert_request_pem
  ca_private_key_pem = tls_private_key.client_intermediate_ca.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.client_intermediate_ca.cert_pem

  validity_period_hours = 2400 # 100 days (same as certs.sh)

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

# Certificate Bundle Creation (equivalent to --bundle flag in step CLI)
# ====================================================================

# Server certificate bundle (leaf + intermediate + root)
locals {
  server_cert_bundle = "${tls_locally_signed_cert.server_leaf.cert_pem}${tls_locally_signed_cert.server_intermediate_ca.cert_pem}${tls_self_signed_cert.server_root_ca.cert_pem}"
  client_cert_bundle = "${tls_locally_signed_cert.client_leaf.cert_pem}${tls_locally_signed_cert.client_intermediate_ca.cert_pem}${tls_self_signed_cert.client_root_ca.cert_pem}"
}

# Write certificates to files (equivalent to the output files from certs.sh)
# ==========================================================================

resource "local_file" "server_root_ca_cert" {
  content  = tls_self_signed_cert.server_root_ca.cert_pem
  filename = "${var.certs_output_directory}/server-root-ca.crt"
}

resource "local_file" "server_root_ca_key" {
  content  = tls_private_key.server_root_ca.private_key_pem
  filename = "${var.certs_output_directory}/server-root-ca.key"
}

resource "local_file" "server_intermediate_ca_cert" {
  content  = tls_locally_signed_cert.server_intermediate_ca.cert_pem
  filename = "${var.certs_output_directory}/server-intermediate-ca.crt"
}

resource "local_file" "server_intermediate_ca_key" {
  content  = tls_private_key.server_intermediate_ca.private_key_pem
  filename = "${var.certs_output_directory}/server-intermediate-ca.key"
}

resource "local_file" "server_leaf_cert" {
  content  = local.server_cert_bundle
  filename = "${var.certs_output_directory}/server-leaf-ca.crt"
}

resource "local_file" "server_leaf_key" {
  content  = tls_private_key.server_leaf.private_key_pem
  filename = "${var.certs_output_directory}/server-leaf-ca.key"
}

resource "local_file" "client_root_ca_cert" {
  content  = tls_self_signed_cert.client_root_ca.cert_pem
  filename = "${var.certs_output_directory}/client-root-ca.crt"
}

resource "local_file" "client_root_ca_key" {
  content  = tls_private_key.client_root_ca.private_key_pem
  filename = "${var.certs_output_directory}/client-root-ca.key"
}

resource "local_file" "client_intermediate_ca_cert" {
  content  = tls_locally_signed_cert.client_intermediate_ca.cert_pem
  filename = "${var.certs_output_directory}/client-intermediate-ca.crt"
}

resource "local_file" "client_intermediate_ca_key" {
  content  = tls_private_key.client_intermediate_ca.private_key_pem
  filename = "${var.certs_output_directory}/client-intermediate-ca.key"
}

resource "local_file" "client_leaf_cert" {
  content  = local.client_cert_bundle
  filename = "${var.certs_output_directory}/client-leaf-ca.crt"
}

resource "local_file" "client_leaf_key" {
  content  = tls_private_key.client_leaf.private_key_pem
  filename = "${var.certs_output_directory}/client-leaf-ca.key"
}
