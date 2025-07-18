output "server_central_script_deployment" {
  description = "The server central script deployment extension."
  value       = try(azurerm_virtual_machine_extension.enterprise_deployment, null)
}

output "client_technology_script_deployment" {
  description = "The client technology script deployment extension."
  value       = try(azurerm_virtual_machine_extension.site_deployment, null)
}
