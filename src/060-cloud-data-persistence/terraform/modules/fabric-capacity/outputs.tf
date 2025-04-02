output "capacity_id" {
  description = "The ID of the Fabric capacity"
  value       = var.create_capacity ? azurerm_fabric_capacity.this[0].id : var.capacity_id
}

output "capacity_name" {
  description = "The name of the Fabric capacity"
  value       = var.create_capacity ? azurerm_fabric_capacity.this[0].name : var.name
}

output "capacity_sku" {
  description = "The SKU of the Fabric capacity"
  value       = var.create_capacity ? azurerm_fabric_capacity.this[0].sku : null
}
