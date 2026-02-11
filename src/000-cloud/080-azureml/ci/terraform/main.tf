# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "existing" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_application_insights" "existing" {
  name                = "appi-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_key_vault" "existing" {
  name                = "kv-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_storage_account" "existing" {
  name                = "st${var.resource_prefix}${var.environment}${var.instance}"
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_container_registry" "existing" {
  name                = "acr${var.resource_prefix}${var.environment}${var.instance}"
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_virtual_network" "existing" {
  name                = "vnet-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_network_security_group" "existing" {
  name                = "nsg-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = data.azurerm_resource_group.existing.name
}

module "ci" {
  source = "../../terraform"

  resource_prefix = var.resource_prefix
  environment     = var.environment
  instance        = var.instance
  location        = var.location
  resource_group  = data.azurerm_resource_group.existing

  application_insights = data.azurerm_application_insights.existing
  key_vault            = data.azurerm_key_vault.existing
  storage_account      = data.azurerm_storage_account.existing

  acr                    = data.azurerm_container_registry.existing
  network_security_group = data.azurerm_network_security_group.existing
  virtual_network        = data.azurerm_virtual_network.existing
}
