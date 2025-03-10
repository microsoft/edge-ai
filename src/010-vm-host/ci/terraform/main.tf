# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name                       = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    arc_onboarding_user_managed_identity_name = "id-${var.resource_prefix}-${var.environment}-arc-aio-${var.instance}"
  }
}

data "azurerm_resource_group" "aio" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_user_assigned_identity" "arc_onboarding" {
  name                = terraform_data.defer.output.arc_onboarding_user_managed_identity_name
  resource_group_name = data.azurerm_resource_group.aio.name
}

module "vm_host" {
  source = "../../terraform"

  resource_prefix                       = var.resource_prefix
  location                              = var.location
  environment                           = var.environment
  instance                              = var.instance
  aio_resource_group                    = data.azurerm_resource_group.aio
  arc_onboarding_user_assigned_identity = data.azurerm_user_assigned_identity.arc_onboarding
}
