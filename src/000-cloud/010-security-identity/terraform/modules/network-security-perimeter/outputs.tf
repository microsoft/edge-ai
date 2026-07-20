output "id" {
  description = "Resource ID of the Network Security Perimeter"
  value       = azapi_resource.main.id
}

output "profile_id" {
  description = "Resource ID of the Network Security Perimeter profile"
  value       = azapi_resource.profile.id

  depends_on = [
    azapi_resource.deployment_clients,
    azapi_resource.subscription,
  ]
}

output "propagation_trigger" {
  description = "Value that changes when the Network Security Perimeter access rules change"
  value = sha256(jsonencode({
    allowed_ip_address_prefixes = var.allowed_ip_address_prefixes
    subscription_id             = var.subscription_id
  }))
}
