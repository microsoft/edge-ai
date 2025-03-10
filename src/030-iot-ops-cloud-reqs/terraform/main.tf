/**
 * # Azure IoT Operations Cloud Requirements
 *
 * Sets up required cloud resources for Azure IoT Operations installation
 * including: Schema Registry, Azure Key Vault, and Roles and Permissions for
 * access to resources.
 */

module "schema_registry" {
  source = "./modules/schema-registry"

  location            = var.aio_resource_group.location
  resource_group_name = var.aio_resource_group.name
  resource_prefix     = var.resource_prefix
  environment         = var.environment
  instance            = var.instance
}

module "sse_key_vault" {
  count = var.sse_key_vault == null ? 1 : 0

  source = "./modules/sse-key-vault"

  location            = var.aio_resource_group.location
  resource_group_name = var.aio_resource_group.name
  resource_prefix     = var.resource_prefix
  environment         = var.environment
  instance            = var.instance
}

module "uami" {
  source = "./modules/uami"

  location            = var.aio_resource_group.location
  resource_group_name = var.aio_resource_group.name
  resource_prefix     = var.resource_prefix
  environment         = var.environment
  instance            = var.instance
  key_vault_id        = try(module.sse_key_vault[0].key_vault, var.sse_key_vault).id
}
