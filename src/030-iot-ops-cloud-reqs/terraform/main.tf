/**
 * # Azure IoT Operations Cloud Requirements
 *
 * Sets up required cloud resources for Azure IoT Operations installation
 * including: Schema Registry, Azure Key Vault, and Roles and Permissions for
 * access to resources.
 */

# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name = coalesce(
      var.resource_group_name,
      "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    )
  }
}

data "azurerm_resource_group" "aio_rg" {
  name = terraform_data.defer.output.resource_group_name
}

module "schema_registry" {
  source = "./modules/schema-registry"

  location            = var.location
  resource_group_name = data.azurerm_resource_group.aio_rg.name
  resource_prefix     = var.resource_prefix
}

module "sse_key_vault" {
  source = "./modules/sse-key-vault"

  location                = var.location
  resource_group_name     = data.azurerm_resource_group.aio_rg.name
  resource_prefix         = var.resource_prefix
  existing_key_vault_name = var.existing_key_vault_name
}

module "uami" {
  source = "./modules/uami"

  location            = var.location
  resource_group_name = data.azurerm_resource_group.aio_rg.name
  resource_prefix     = var.resource_prefix
  key_vault_id        = module.sse_key_vault.key_vault.id
}
