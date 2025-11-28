/**
 * # PostgreSQL Flexible Server Component
 *
 * Deploys Azure PostgreSQL Flexible Server with TimescaleDB support,
 * private networking, and optional geo-redundant backups.
 */

locals {
  delegated_subnet_id = try(coalesce(var.delegated_subnet_id), module.network[0].postgres_subnet.id, null)

  // Determine private DNS zone ID - must be known before server creation
  private_dns_zone_id = try(coalesce(var.private_dns_zone.id), module.network[0].private_dns_zone_id, null)

  databases = var.databases != null ? var.databases : {
    defaultdb = {
      collation = "en_US.utf8"
      charset   = "utf8"
    }
  }

  // Credential resolution - prefer user-provided, fallback to generated
  admin_password_resolved = coalesce(
    var.admin_password,
    try(random_password.admin_password[0].result, null)
  )
}

module "network" {
  count  = var.should_create_delegated_subnet ? 1 : 0
  source = "./modules/network"

  // Resource dependencies first
  resource_group         = var.resource_group
  virtual_network        = var.virtual_network
  network_security_group = var.network_security_group

  // Core parameters next
  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance

  // Networking configuration
  subnet_address_prefixes         = var.subnet_address_prefixes
  default_outbound_access_enabled = var.default_outbound_access_enabled
  should_enable_nat_gateway       = var.should_enable_nat_gateway
  nat_gateway                     = var.nat_gateway
  should_create_private_dns_zone  = var.should_create_private_dns_zone
}

// Generate random password for PostgreSQL authentication when enabled
resource "random_password" "admin_password" {
  count = var.should_generate_admin_password ? 1 : 0

  length  = 20
  special = true
}

/*
 * Key Vault Secrets for Credentials
 */

resource "azurerm_key_vault_secret" "admin_username" {
  count = var.should_store_credentials_in_key_vault ? 1 : 0

  name         = "psql-${var.resource_prefix}-${var.environment}-${var.instance}-admin-username"
  value        = var.admin_username
  key_vault_id = var.key_vault.id
}

resource "azurerm_key_vault_secret" "admin_password" {
  count = var.should_store_credentials_in_key_vault ? 1 : 0

  name         = "psql-${var.resource_prefix}-${var.environment}-${var.instance}-admin-password"
  value        = local.admin_password_resolved
  key_vault_id = var.key_vault.id
}

module "postgresql_server" {
  source = "./modules/postgresql-server"

  resource_group  = var.resource_group
  location        = var.location
  resource_prefix = var.resource_prefix
  environment     = var.environment
  instance        = var.instance

  postgres_version    = var.postgres_version
  zone                = var.zone
  sku_name            = var.sku_name
  storage_mb          = var.storage_mb
  delegated_subnet_id = local.delegated_subnet_id
  private_dns_zone_id = local.private_dns_zone_id

  admin_username = var.admin_username
  admin_password = local.admin_password_resolved

  databases = local.databases

  should_enable_extensions  = var.should_enable_extensions
  should_enable_timescaledb = var.should_enable_timescaledb
  extensions                = var.extensions

  backup_retention_days              = var.backup_retention_days
  should_enable_geo_redundant_backup = var.should_enable_geo_redundant_backup

  depends_on = [module.network]
}
