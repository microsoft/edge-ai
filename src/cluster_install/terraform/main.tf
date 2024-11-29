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
  count  = var.arc_sp_client_id == "" && var.arc_sp_secret == "" ? 1 : 0
  source = "./modules/arc_service_principal"

  resource_prefix   = var.resource_prefix
  resource_group_id = local.resource_group_id
}

locals {
  service_principal_client_id = length(module.arc_service_principal) > 0 ? module.arc_service_principal[0].sp_client_id : var.arc_sp_client_id
  service_principal_secret    = length(module.arc_service_principal) > 0 ? module.arc_service_principal[0].sp_client_secret : var.arc_sp_secret
}

### Create Virtual Edge Device ###

module "edge_device" {
  source = "./modules/edge_device"

  environment                           = var.environment
  resource_prefix                       = var.resource_prefix
  location                              = var.location
  resource_group_name                   = local.resource_group_name
  arc_sp_client_id                      = local.service_principal_client_id
  arc_sp_secret                         = local.service_principal_secret
  vm_sku_size                           = var.vm_sku_size
  vm_username                           = var.vm_username
  add_current_entra_user_cluster_admin  = var.add_current_entra_user_cluster_admin
}
