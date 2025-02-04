# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "azmon" {
  name = terraform_data.defer.output.resource_group_name
}

module "observability" {
  source = "../../terraform"

  resource_prefix      = var.resource_prefix
  environment          = var.environment
  instance             = var.instance
  azmon_resource_group = data.azurerm_resource_group.azmon
}
