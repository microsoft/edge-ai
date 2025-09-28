/*
 * Workspace Outputs
 */

output "principal_id" {
  description = "The Principal ID of the System Assigned Managed Service Identity."
  value       = azurerm_machine_learning_workspace.this.identity[0].principal_id
}

output "workspace" {
  description = "Azure Machine Learning workspace object."
  value = {
    id                  = azurerm_machine_learning_workspace.this.id
    name                = azurerm_machine_learning_workspace.this.name
    location            = azurerm_machine_learning_workspace.this.location
    resource_group_name = azurerm_machine_learning_workspace.this.resource_group_name
    workspace_id        = azurerm_machine_learning_workspace.this.workspace_id
    discovery_url       = azurerm_machine_learning_workspace.this.discovery_url
  }
}

output "workspace_id" {
  description = "The immutable resource ID of the workspace."
  value       = azurerm_machine_learning_workspace.this.workspace_id
}

output "workspace_name" {
  description = "The name of the workspace."
  value       = azurerm_machine_learning_workspace.this.name
}

output "private_endpoint" {
  description = "The private endpoint resource for Azure ML workspace."
  value = var.should_enable_private_endpoint ? {
    id                   = azurerm_private_endpoint.azureml_pe[0].id
    name                 = azurerm_private_endpoint.azureml_pe[0].name
    private_ip_address   = azurerm_private_endpoint.azureml_pe[0].private_service_connection[0].private_ip_address
    network_interface_id = azurerm_private_endpoint.azureml_pe[0].network_interface[0].id
    custom_dns_configs   = azurerm_private_endpoint.azureml_pe[0].custom_dns_configs
  } : null
}

output "private_dns_zones" {
  description = "Map of private DNS zones created for AzureML services"
  value = var.should_enable_private_endpoint ? {
    for zone_name, zone in azurerm_private_dns_zone.azureml_zones :
    zone_name => {
      id   = zone.id
      name = zone.name
    }
  } : {}
}

output "workspace_discovery_url" {
  description = "AzureML workspace discovery URL"
  value       = azurerm_machine_learning_workspace.this.discovery_url
}
