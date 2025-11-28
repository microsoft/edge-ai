// Defer computation to prevent `data` objects from querying for state on `terraform plan`.
// Needed for testing and build system compatibility.
resource "terraform_data" "defer" {
  input = {
    resource_group_name = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    vnet_name           = "vnet-${var.resource_prefix}-${var.environment}-${var.instance}"
    subnet_name         = "snet-postgres-${var.resource_prefix}-${var.environment}"
    key_vault_name      = "kv-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "aio" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_virtual_network" "aio" {
  name                = terraform_data.defer.output.vnet_name
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azurerm_subnet" "postgres" {
  name                 = terraform_data.defer.output.subnet_name
  virtual_network_name = data.azurerm_virtual_network.aio.name
  resource_group_name  = data.azurerm_resource_group.aio.name
}

data "azurerm_key_vault" "this" {
  name                = terraform_data.defer.output.key_vault_name
  resource_group_name = data.azurerm_resource_group.aio.name
}

module "ci" {
  source = "../../terraform"

  resource_prefix = var.resource_prefix
  environment     = var.environment
  instance        = var.instance
  location        = var.location

  resource_group      = data.azurerm_resource_group.aio
  delegated_subnet_id = data.azurerm_subnet.postgres.id
  virtual_network     = data.azurerm_virtual_network.aio

  key_vault = data.azurerm_key_vault.this
}
