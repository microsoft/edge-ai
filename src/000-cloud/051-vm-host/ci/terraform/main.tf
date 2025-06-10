# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name                       = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    arc_onboarding_user_managed_identity_name = "id-${var.resource_prefix}-arc-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "aio" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_user_assigned_identity" "arc_onboarding" {
  name                = terraform_data.defer.output.arc_onboarding_user_managed_identity_name
  resource_group_name = data.azurerm_resource_group.aio.name
}

module "virtual_network" {
  source = "../../../050-networking/terraform"

  environment     = var.environment
  instance        = var.instance
  location        = var.location
  resource_prefix = var.resource_prefix
  resource_group  = data.azurerm_resource_group.aio
}

module "ci" {
  source = "../../terraform"

  resource_prefix         = var.resource_prefix
  location                = var.location
  environment             = var.environment
  instance                = var.instance
  resource_group          = data.azurerm_resource_group.aio
  subnet_id               = module.virtual_network.subnet_id
  arc_onboarding_identity = data.azurerm_user_assigned_identity.arc_onboarding
}
