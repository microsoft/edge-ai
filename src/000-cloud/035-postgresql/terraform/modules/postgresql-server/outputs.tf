output "postgresql_server" {
  description = "PostgreSQL Flexible Server object."
  value = {
    id   = azurerm_postgresql_flexible_server.main.id
    name = azurerm_postgresql_flexible_server.main.name
    fqdn = azurerm_postgresql_flexible_server.main.fqdn
  }
}

output "databases" {
  description = "Map of created PostgreSQL databases."
  value = {
    for k, v in azurerm_postgresql_flexible_server_database.databases : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "connection_info" {
  description = "PostgreSQL connection information."
  sensitive   = true
  value = {
    fqdn           = azurerm_postgresql_flexible_server.main.fqdn
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
}
