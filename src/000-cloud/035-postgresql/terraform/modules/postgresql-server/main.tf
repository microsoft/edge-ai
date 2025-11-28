/**
 * # PostgreSQL Flexible Server Internal Module
 *
 * Creates Azure PostgreSQL Flexible Server with TimescaleDB support,
 * private networking, and database configurations.
 */

resource "azurerm_postgresql_flexible_server" "main" {
  name                = "psql-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = var.resource_group.name
  location            = var.location
  version             = var.postgres_version

  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  administrator_login    = var.admin_username
  administrator_password = var.admin_password

  zone       = var.zone
  sku_name   = var.sku_name
  storage_mb = var.storage_mb

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.should_enable_geo_redundant_backup

  public_network_access_enabled = false
}

resource "azurerm_postgresql_flexible_server_database" "databases" {
  for_each = var.databases

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = each.value.collation
  charset   = each.value.charset
}

resource "azurerm_postgresql_flexible_server_configuration" "timescaledb" {
  count = var.should_enable_timescaledb ? 1 : 0

  name      = "shared_preload_libraries"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "timescaledb"
}

resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  count = var.should_enable_extensions ? 1 : 0

  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = join(",", var.extensions)
}
