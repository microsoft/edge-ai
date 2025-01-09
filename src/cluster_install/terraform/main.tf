### Create or use existing Resource Group ###

# Check if the resource group already exists
data "azurerm_resource_group" "existing" {
  name     = var.existing_resource_group_name
  provider = azurerm
  count    = var.existing_resource_group_name != "" ? 1 : 0
}

# Create the resource group if it doesn't exist
resource "azurerm_resource_group" "new" {
  name     = "${var.resource_prefix}-aio-edge-rg"
  location = var.location
  count    = length(data.azurerm_resource_group.existing) == 0 ? 1 : 0
}

# Use the resource group
locals {
  resource_group_id   = length(data.azurerm_resource_group.existing) > 0 ? data.azurerm_resource_group.existing[0].id : azurerm_resource_group.new[0].id
  resource_group_name = length(data.azurerm_resource_group.existing) > 0 ? data.azurerm_resource_group.existing[0].name : azurerm_resource_group.new[0].name
}

### Create Service Principal for Azure Arc ###
module "arc_service_principal" {
  source            = "./modules/arc_service_principal"
  resource_prefix   = var.resource_prefix
  resource_group_id = local.resource_group_id

  count = var.use_service_principal_for_arc_onboarding_instead_of_managed_identity ? 1 : 0
}

module "arc_managed_identity" {
  source              = "./modules/arc_managed_identity"
  location            = var.location
  resource_group_name = local.resource_group_name
  resource_prefix     = var.resource_prefix
  resource_group_id   = local.resource_group_id

  count = var.use_service_principal_for_arc_onboarding_instead_of_managed_identity ? 0 : 1
}

locals {
  service_principal_client_id             = length(module.arc_service_principal) > 0 ? module.arc_service_principal[0].sp_client_id : ""
  service_principal_secret                = length(module.arc_service_principal) > 0 ? module.arc_service_principal[0].sp_client_secret : ""
  arc_onboarding_user_managed_identity_id = length(module.arc_managed_identity) > 0 ? module.arc_managed_identity[0].arc_onboarding_user_managed_identity_id : ""
}

### Create Virtual Edge Device ###

module "edge_device" {
  source = "./modules/edge_device"

  environment                          = var.environment
  resource_prefix                      = var.resource_prefix
  location                             = var.location
  resource_group_name                  = local.resource_group_name
  vm_sku_size                          = var.vm_sku_size
  vm_username                          = var.vm_username
  add_current_entra_user_cluster_admin = var.add_current_entra_user_cluster_admin
  custom_locations_oid                 = var.custom_locations_oid

  arc_sp_client_id                        = local.service_principal_client_id
  arc_sp_secret                           = local.service_principal_secret
  arc_onboarding_user_managed_identity_id = local.arc_onboarding_user_managed_identity_id
}

module "aio_schema_registry" {
  source              = "./modules/aio_schema_registry"
  location            = var.location
  resource_group_name = local.resource_group_name
  resource_prefix     = var.resource_prefix
}

module "aio" {
  source                     = "./modules/azure_iot_operations"
  resource_group_name        = local.resource_group_name
  connected_cluster_location = var.location
  connected_cluster_name     = module.edge_device.connected_cluster_name
  schema_registry_id         = module.aio_schema_registry.registry_id
  depends_on                 = [module.edge_device]
}
