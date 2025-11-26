/**
 * # Azure Managed Redis Component
 *
 * Provisions Azure Managed Redis cache with optional private endpoint networking.
 * Supports Microsoft Entra ID authentication and customer-managed key encryption.
 */

locals {
  redis_name = "redis-${var.resource_prefix}-${var.environment}-${var.instance}"
}

/*
 * Azure Managed Redis Cache
 */

module "managed_redis" {
  count  = var.should_deploy_redis ? 1 : 0
  source = "./modules/managed-redis"

  // Core Configuration
  location            = var.location
  name                = local.redis_name
  resource_group_name = var.resource_group.name

  // Redis Configuration
  access_keys_authentication_enabled = var.access_keys_authentication_enabled
  clustering_policy                  = var.clustering_policy
  customer_managed_key               = var.customer_managed_key
  should_enable_high_availability    = var.should_enable_high_availability
  sku_name                           = var.sku_name

  // Identity
  managed_identity_id = try(var.managed_identity.id, null)

  // Private Endpoint
  private_endpoint_subnet_id     = try(var.private_endpoint_subnet.id, null)
  should_create_private_dns_zone = var.should_create_private_dns_zone
  should_enable_private_endpoint = var.should_enable_private_endpoint
  virtual_network_id             = try(var.virtual_network.id, null)
}

/*
 * Deferred Output for Dependency Management
 */

resource "terraform_data" "defer" {
  input = try(module.managed_redis[0], null)
}
