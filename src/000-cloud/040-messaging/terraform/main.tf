/**
 * # Messaging
 *
 * Sets up messaging infrastructure and includes deploying a sample
 * Azure IoT Operations Dataflow to send and receive data from edge to cloud.
 */

module "eventhub" {
  count = var.should_create_eventhub ? 1 : 0

  source = "./modules/eventhub"

  environment           = var.environment
  resource_prefix       = var.resource_prefix
  instance              = var.instance
  resource_group_name   = var.resource_group.name
  location              = var.resource_group.location
  aio_uami_principal_id = var.aio_identity.principal_id
  capacity              = var.eventhub_capacity
  eventhubs             = var.eventhubs
}

module "eventgrid" {
  count = var.should_create_eventgrid ? 1 : 0

  source = "./modules/eventgrid"

  resource_prefix       = var.resource_prefix
  environment           = var.environment
  instance              = var.instance
  resource_group_name   = var.resource_group.name
  location              = var.resource_group.location
  aio_uami_principal_id = var.aio_identity.principal_id

  # Pass custom configuration parameters
  capacity                                    = var.eventgrid_capacity
  eventgrid_max_client_sessions_per_auth_name = var.eventgrid_max_client_sessions
  topic_name                                  = var.eventgrid_topic_name
}

module "app_service_plan" {
  count = var.should_create_azure_functions ? 1 : 0

  source = "./modules/app-service-plan"

  resource_prefix     = var.resource_prefix
  environment         = var.environment
  instance            = var.instance
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location

  # Pass custom configuration parameters
  os_type  = var.app_service_plan_os_type
  sku_name = var.app_service_plan_sku_name
  tags     = var.tags
}

module "azure_functions" {
  count = var.should_create_azure_functions ? 1 : 0

  source = "./modules/azure-functions"

  resource_prefix     = var.resource_prefix
  environment         = var.environment
  instance            = var.instance
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location

  app_service_plan = module.app_service_plan[0].app_service_plan

  # Pass custom configuration parameters
  app_settings             = var.function_app_settings
  cors_allowed_origins     = var.function_cors_allowed_origins
  cors_support_credentials = var.function_cors_support_credentials
  node_version             = var.function_node_version
  tags                     = var.tags
}
