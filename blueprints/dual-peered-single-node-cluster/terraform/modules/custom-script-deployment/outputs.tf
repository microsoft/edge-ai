output "server_central_script_deployment" {
  description = "The server central script deployment extension."
  value       = try(azurerm_virtual_machine_extension.server_central_deployment[0], null)
}

output "client_technology_script_deployment" {
  description = "The client technology script deployment extension."
  value       = try(azurerm_virtual_machine_extension.client_technology_deployment[0], null)
}
