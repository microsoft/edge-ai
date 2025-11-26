/**
 * # Certificate Management for VPN Gateway
 *
 * Manages root certificates for VPN Gateway Point-to-Site authentication.
 * Supports auto-generation with TLS provider, existing certificate retrieval,
 * and Key Vault storage for secure certificate management.
 */

locals {
  certificate_name = "vpn-root-cert-${var.resource_prefix}-${var.environment}-${var.instance}"
}

/*
 * Auto-generated Certificate with TLS Provider
 */

resource "tls_private_key" "vpn_ca" {
  count = var.should_generate_ca ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "vpn_ca" {
  count = var.should_generate_ca ? 1 : 0

  private_key_pem = tls_private_key.vpn_ca[0].private_key_pem

  subject {
    common_name         = var.certificate_subject.common_name
    organization        = var.certificate_subject.organization
    organizational_unit = var.certificate_subject.organizational_unit
    country             = var.certificate_subject.country
    province            = var.certificate_subject.province
    locality            = var.certificate_subject.locality
  }

  validity_period_hours = var.certificate_validity_days * 24
  is_ca_certificate     = true

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "cert_signing",
    "crl_signing",
  ]
}

/*
 * Key Vault Storage for Auto-generated Certificates
 */

resource "azurerm_key_vault_secret" "vpn_root_cert" {
  count = var.should_generate_ca && var.key_vault != null ? 1 : 0

  name         = "vpn-root-certificate-public"
  value        = base64encode(tls_self_signed_cert.vpn_ca[0].cert_pem)
  key_vault_id = var.key_vault.id
  content_type = "application/x-pem-file"

  tags = {
    certificate-type = "vpn-root-ca"
    environment      = var.environment
    auto-generated   = "true"
    resource-prefix  = var.resource_prefix
    instance         = var.instance
  }
}

resource "azurerm_key_vault_secret" "vpn_root_key" {
  count = var.should_generate_ca && var.key_vault != null ? 1 : 0

  name         = "vpn-root-certificate-private-key"
  value        = tls_private_key.vpn_ca[0].private_key_pem
  key_vault_id = var.key_vault.id
  content_type = "application/x-pem-file"

  tags = {
    certificate-type = "vpn-root-ca-key"
    environment      = var.environment
    auto-generated   = "true"
    resource-prefix  = var.resource_prefix
    instance         = var.instance
  }
}

/*
 * Key Vault Certificate Retrieval
 */

data "azurerm_key_vault_secret" "existing_cert" {
  count = !var.should_generate_ca ? 1 : 0

  name         = var.existing_certificate_name
  key_vault_id = var.key_vault.id
}
