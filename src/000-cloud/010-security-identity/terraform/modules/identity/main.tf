/**
 * # User Assigned Managed Identities for Azure IoT Operations
 *
 * Create User Assigned Managed Identities for Azure IoT Operations and assign roles to them
 *
 */

locals {
  today                       = timestamp()
  should_enable_sp_onboarding = var.onboard_identity_type == "sp"
  should_enable_id_onboarding = var.onboard_identity_type == "id"
}

data "azurerm_client_config" "current" {}

/*
 * Service Principal
 */

resource "azuread_application" "aio_edge" {
  count = local.should_enable_sp_onboarding ? 1 : 0

  display_name = "sp-${var.resource_prefix}-arc-${var.environment}-${var.instance}"
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal" "aio_edge" {
  count = local.should_enable_sp_onboarding ? 1 : 0

  client_id = azuread_application.aio_edge[0].client_id
  owners    = [data.azurerm_client_config.current.object_id]
}

resource "azuread_application_password" "aio_edge" {
  count = local.should_enable_sp_onboarding ? 1 : 0

  application_id = azuread_application.aio_edge[0].id
  end_date       = timeadd(local.today, "720h") // By policy the default end date is not valid in some subscriptions
  // BUG: https://github.com/hashicorp/terraform-provider-azuread/issues/661
  // Occurs sometimes on destroying the resource, retrying the destroy solves the issue
  lifecycle {
    ignore_changes = [end_date]
  }
}

/*
 * User Assigned Managed Identity
 */

resource "azurerm_user_assigned_identity" "arc_onboarding" {
  count = local.should_enable_id_onboarding ? 1 : 0

  location            = var.location
  name                = "id-${var.resource_prefix}-arc-${var.environment}-${var.instance}"
  resource_group_name = var.resource_group.name
}

resource "azurerm_user_assigned_identity" "user_managed_identity_secret_sync" {
  location            = var.location
  name                = "id-${var.resource_prefix}-sse-${var.environment}-${var.instance}"
  resource_group_name = var.resource_group.name
}

resource "azurerm_user_assigned_identity" "user_managed_identity_aio" {
  location            = var.location
  name                = "id-${var.resource_prefix}-aio-${var.environment}-${var.instance}"
  resource_group_name = var.resource_group.name
}
