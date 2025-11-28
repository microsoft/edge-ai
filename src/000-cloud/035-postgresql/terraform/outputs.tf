/*
 * Networking Outputs
 */

output "postgres_subnet" {
  description = "The delegated subnet for PostgreSQL Flexible Server."
  value       = try(module.network[0].postgres_subnet, null)
}

/*
 * PostgreSQL Server Outputs
 */

output "postgresql_server" {
  description = "PostgreSQL Flexible Server object with id, name, and fqdn."
  value       = module.postgresql_server.postgresql_server
}

output "databases" {
  description = "Map of created PostgreSQL databases with id and name."
  value       = module.postgresql_server.databases
}

output "connection_info" {
  description = "PostgreSQL connection information including credentials."
  sensitive   = true
  value       = module.postgresql_server.connection_info
}

/*
 * Networking Outputs
 */

output "private_dns_zone_id" {
  description = "Private DNS zone ID if created."
  value       = local.private_dns_zone_id
}

/*
 * Key Vault Secret Outputs
 */

output "admin_username_secret" {
  description = "Key Vault secret reference for admin username."
  value = try({
    id   = azurerm_key_vault_secret.admin_username[0].id
    name = azurerm_key_vault_secret.admin_username[0].name
  }, null)
}

output "admin_password_secret" {
  description = "Key Vault secret reference for admin password."
  value = try({
    id   = azurerm_key_vault_secret.admin_password[0].id
    name = azurerm_key_vault_secret.admin_password[0].name
  }, null)
}
