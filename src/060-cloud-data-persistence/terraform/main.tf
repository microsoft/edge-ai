# Azure Storage Account and Container Terraform Configuration

locals {
  # Define tags here with individual variables
  tags = {
    Environment = var.environment
    Instance    = var.instance
    component   = "storage"
  }

  # Generate consistent resource names using prefix convention
  fabric_workspace_name   = "${var.resource_prefix}-fabric-ws-${var.environment}-${var.instance}"
  fabric_lakehouse_name   = "${var.resource_prefix}fabriclh${var.environment}${var.instance}"
  fabric_eventstream_name = "${var.resource_prefix}-fabric-es-${var.environment}-${var.instance}"
  fabric_capacity_name    = "${var.resource_prefix}fabriccap${var.environment}${var.instance}"

  # Use either the created workspace ID or the provided existing workspace ID
  workspace_id = var.should_create_fabric_workspace ? module.fabric_workspace[0].workspace_id : var.existing_fabric_workspace_id
}

# Add data source for current client config
data "azurerm_client_config" "current" {}

# Storage Account
module "storage_account" {
  source = "./modules/storage-account"

  account_tier                         = var.storage_account_tier
  account_replication_type             = var.storage_account_replication
  account_kind                         = var.storage_account_kind
  blob_soft_delete_retention_days      = var.blob_soft_delete_retention_days
  container_soft_delete_retention_days = var.container_soft_delete_retention_days
  environment                          = var.environment
  instance                             = var.instance
  location                             = var.location
  private_endpoint_subnet_id           = var.private_endpoint_subnet_id
  resource_group_name                  = var.resource_group.name
  resource_prefix                      = var.resource_prefix
  should_enable_private_endpoint       = var.should_enable_private_endpoint
  tags                                 = local.tags
}

# Create the data lake and pass the storage account details
module "data_lake" {
  count  = var.should_create_data_lake ? 1 : 0
  source = "./modules/data-lake"

  container_access_type                   = var.container_access_type
  data_lake_blob_container_name           = var.data_lake_blob_container_name
  data_lake_filesystem_name               = var.data_lake_filesystem_name
  data_lake_data_owner_principal_id       = coalesce(var.data_lake_data_owner_principal_id, data.azurerm_client_config.current.object_id)
  data_lake_data_contributor_principal_id = var.data_lake_data_contributor_principal_id
  file_share_name                         = var.file_share_name
  file_share_quota_gb                     = var.file_share_quota_gb
  should_create_data_lake_file_share      = var.should_create_data_lake_file_share
  storage_account_id                      = module.storage_account.id
}

# Fabric capacity module
module "fabric_capacity" {
  source = "./modules/fabric-capacity"

  create_capacity     = var.should_create_fabric_capacity
  capacity_id         = var.fabric_capacity_id
  name                = local.fabric_capacity_name
  resource_group_name = var.resource_group.name
  location            = var.location
  sku                 = var.fabric_capacity_sku
  admin_members       = var.fabric_capacity_admins
  tags                = local.tags
}

# Microsoft Fabric Workspace
module "fabric_workspace" {
  count  = var.should_create_fabric_workspace ? 1 : 0
  source = "./modules/fabric-workspace"

  workspace_display_name = local.fabric_workspace_name
  workspace_description  = var.workspace_description
  capacity_id            = var.capacity_id
}

# Microsoft Fabric Lakehouse
module "fabric_lakehouse" {
  count  = var.should_create_fabric_lakehouse ? 1 : 0
  source = "./modules/fabric-lakehouse"

  lakehouse_display_name = local.fabric_lakehouse_name
  lakehouse_description  = var.lakehouse_description
  workspace_id           = local.workspace_id
}

# Microsoft Fabric EventStream
module "fabric_eventstream" {
  count  = var.should_create_fabric_eventstream ? 1 : 0
  source = "./modules/fabric-eventstream"

  eventstream_display_name = local.fabric_eventstream_name
  eventstream_description  = var.eventstream_description
  workspace_id             = local.workspace_id
  lakehouse_id             = module.fabric_lakehouse[0].lakehouse_id
  eventhub_endpoint        = var.eventhub_endpoint
}
