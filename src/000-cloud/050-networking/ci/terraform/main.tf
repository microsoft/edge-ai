resource "terraform_data" "defer" {
  input = {
    resource_group_name = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "main" {
  name = terraform_data.defer.output.resource_group_name
}

module "ci" {
  source = "../../terraform"

  environment     = var.environment
  instance        = var.instance
  location        = var.location
  resource_prefix = var.resource_prefix
  resource_group  = data.azurerm_resource_group.main
}
