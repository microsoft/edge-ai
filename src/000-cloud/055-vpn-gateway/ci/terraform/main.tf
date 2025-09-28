resource "terraform_data" "defer" {
  input = {
    resource_group_name  = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    virtual_network_name = "vnet-${var.resource_prefix}-${var.environment}-${var.instance}"
    key_vault_name       = "kv-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "aio" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_virtual_network" "main" {
  name                = terraform_data.defer.output.virtual_network_name
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azurerm_key_vault" "main" {
  count = !var.should_use_azure_ad_auth ? 1 : 0

  name                = terraform_data.defer.output.key_vault_name
  resource_group_name = data.azurerm_resource_group.aio.name
}

module "ci" {
  source = "../../terraform"

  resource_prefix    = var.resource_prefix
  environment        = var.environment
  instance           = var.instance
  location           = var.location
  aio_resource_group = data.azurerm_resource_group.aio
  virtual_network = {
    id   = data.azurerm_virtual_network.main.id
    name = data.azurerm_virtual_network.main.name
  }
  key_vault = !var.should_use_azure_ad_auth ? {
    id        = data.azurerm_key_vault.main[0].id
    name      = data.azurerm_key_vault.main[0].name
    vault_uri = data.azurerm_key_vault.main[0].vault_uri
  } : null
  should_use_azure_ad_auth = var.should_use_azure_ad_auth
  azure_ad_config          = var.azure_ad_config
}
