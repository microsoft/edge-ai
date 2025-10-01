output "certificate_name" {
  description = "The name of the root certificate"
  value       = local.certificate_name
}

output "public_certificate_data" {
  description = "The public certificate data for VPN Gateway configuration"
  value = (
    var.should_generate_ca ? base64encode(tls_self_signed_cert.vpn_ca[0].cert_pem) :
    data.azurerm_key_vault_secret.existing_cert[0].value
  )
  sensitive = true
}

output "certificate_source" {
  description = "The source of the certificate for debugging"
  value       = var.should_generate_ca ? "auto-generate" : "key-vault"
}

output "certificate_subject" {
  description = "The certificate subject information"
  value = var.should_generate_ca ? {
    common_name         = var.certificate_subject.common_name
    organization        = var.certificate_subject.organization
    organizational_unit = var.certificate_subject.organizational_unit
    country             = var.certificate_subject.country
    province            = var.certificate_subject.province
    locality            = var.certificate_subject.locality
  } : null
}
