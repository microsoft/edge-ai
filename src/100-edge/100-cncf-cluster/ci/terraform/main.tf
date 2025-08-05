# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name       = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    arc_onboard_identity_name = "id-${var.resource_prefix}-arc-${var.environment}-${var.instance}"
    key_vault_name            = "kv-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "aio" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_virtual_machine" "aio" {
  name                = "vm-${var.resource_prefix}-aio-${var.environment}-${var.instance}-0"
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azurerm_user_assigned_identity" "arc" {
  name                = terraform_data.defer.output.arc_onboard_identity_name
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azurerm_key_vault" "aio" {
  name                = terraform_data.defer.output.key_vault_name
  resource_group_name = data.azurerm_resource_group.aio.name
}

module "ci" {
  source = "../../terraform"

  environment                           = var.environment
  instance                              = var.instance
  resource_prefix                       = var.resource_prefix
  custom_locations_oid                  = var.custom_locations_oid
  resource_group                        = data.azurerm_resource_group.aio
  cluster_server_machine                = data.azurerm_virtual_machine.aio
  should_get_custom_locations_oid       = var.should_get_custom_locations_oid
  should_add_current_user_cluster_admin = var.should_add_current_user_cluster_admin
  arc_onboarding_identity               = data.azurerm_user_assigned_identity.arc
  key_vault                             = data.azurerm_key_vault.aio

  // Script deployment from Key Vault parameters
  should_use_script_from_secrets_for_deploy = var.should_use_script_from_secrets_for_deploy
  key_vault_script_secret_prefix            = var.key_vault_script_secret_prefix
}
