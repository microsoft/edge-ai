/**
 * # Video Capture Query Blueprint
 *
 * Deploys cloud infrastructure for continuous video recording and time-based query capabilities.
 * This blueprint orchestrates storage account, lifecycle policies, and Azure Functions for the Video Query API.
 */

module "cloud_resource_group" {
  source = "../../../src/000-cloud/000-resource-group/terraform"

  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance
  tags            = var.tags
}

module "cloud_data" {
  source = "../../../src/000-cloud/030-data/terraform"

  depends_on = [module.cloud_resource_group]

  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance
  resource_group  = module.cloud_resource_group.resource_group

  // Azure Functions requires HNS disabled
  storage_account_is_hns_enabled = false

  // Keep public network access disabled for local/managed-identity scenarios.
  should_enable_public_network_access = false

  // Disable schema registry and ADR namespace for video-only blueprint
  should_create_schema_registry = false
  should_create_adr_namespace   = false

  // Disable data lake for video-only blueprint
  should_create_data_lake = false
}

module "cloud_messaging" {
  source = "../../../src/000-cloud/040-messaging/terraform"

  depends_on = [module.cloud_data]

  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance
  resource_group  = module.cloud_resource_group.resource_group
  aio_identity    = null

  // Enable Azure Functions for Video Query API
  should_create_azure_functions = true

  // Disable Event Grid and Event Hubs for video-only blueprint
  should_create_eventgrid = false
  should_create_eventhub  = false

  // Use Python for the Video Query Azure Function
  function_node_version   = null
  function_python_version = "3.11"

  function_app_settings = {
    FUNCTIONS_WORKER_RUNTIME   = "python"
    STORAGE_ACCOUNT_NAME       = module.cloud_data.storage_account.name
    TEMP_VIDEOS_CONTAINER      = "temp-videos"
    VIDEO_RECORDINGS_CONTAINER = "video-recordings"
    SAS_EXPIRY_HOURS           = "24"
  }
}

resource "azurerm_role_assignment" "video_query_storage_blob_data_contributor" {
  scope                = module.cloud_data.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.cloud_messaging.function_app.principal_id
}
