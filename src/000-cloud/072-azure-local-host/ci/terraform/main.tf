// Defer computation to prevent data source lookups during plan in restricted CI environments.
// Includes logical network placeholders to pass through to component without direct provider queries.
resource "terraform_data" "defer" {
  input = {
    resource_group_name                 = var.resource_group_name
    logical_network_name                = var.logical_network_name
    logical_network_resource_group_name = var.logical_network_resource_group_name
  }
}

data "azurerm_resource_group" "rg" {
  name = terraform_data.defer.output.resource_group_name
}

module "ci" {
  source = "../../terraform"

  environment          = var.environment
  location             = var.location
  resource_prefix      = var.resource_prefix
  instance             = var.instance
  resource_group       = data.azurerm_resource_group.rg
  custom_locations_oid = var.custom_locations_oid

  logical_network_name                = terraform_data.defer.output.logical_network_name
  logical_network_resource_group_name = terraform_data.defer.output.logical_network_resource_group_name
}
