/*
 * Fabric Component Outputs
 */

output "fabric_capacity" {
  description = "The Microsoft Fabric capacity details."
  value       = module.cloud_fabric.fabric_capacity
}

output "fabric_eventhouse" {
  description = "The Microsoft Fabric eventhouse details."
  value       = module.cloud_fabric.fabric_eventhouse
}

output "fabric_lakehouse" {
  description = "The Microsoft Fabric lakehouse details."
  value       = module.cloud_fabric.fabric_lakehouse
}

output "fabric_workspace" {
  description = "The Microsoft Fabric workspace details."
  value       = module.cloud_fabric.fabric_workspace
}

/*
 * Resource Group Output
 */

output "resource_group" {
  description = "The resource group for the fabric resources."
  value       = data.azurerm_resource_group.existing
}
