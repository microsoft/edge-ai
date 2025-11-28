output "postgres_subnet" {
  description = "The delegated subnet created for PostgreSQL Flexible Server."
  value = {
    id   = azurerm_subnet.postgres.id
    name = azurerm_subnet.postgres.name
  }
}

output "private_dns_zone_id" {
  description = "Private DNS zone ID if created."
  value       = try(azurerm_private_dns_zone.postgres[0].id, null)
}
