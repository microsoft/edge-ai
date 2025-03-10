/**
 * # Create Managed identity or Service Principal for Azure Arc cluster onboarding
 *
 * Create UAMI/SP with minimal permissions to onboard the VM to Azure Arc.
 * Used with a hands-off deployment that will embed UAMI/SP
 *
 */

locals {
  today = timestamp()

  enable_uami = lower(var.onboard_identity_type) == "uami"
  enable_sp   = lower(var.onboard_identity_type) == "sp"

  principal_id = try(azurerm_user_assigned_identity.arc_onboarding[0].principal_id, azuread_service_principal.aio_edge[0].object_id)
}

data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "arc_onboarding" {
  count               = local.enable_uami ? 1 : 0
  location            = var.location
  name                = "id-${var.resource_prefix}-${var.environment}-arc-aio-${var.instance}"
  resource_group_name = var.resource_group_name
}

resource "azuread_application" "aio_edge" {
  count        = local.enable_sp ? 1 : 0
  display_name = "sp-${var.resource_prefix}-${var.environment}-arc-aio-${var.instance}"
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal" "aio_edge" {
  count     = local.enable_sp ? 1 : 0
  client_id = azuread_application.aio_edge[0].client_id
  owners    = [data.azurerm_client_config.current.object_id]
}

resource "azuread_application_password" "aio_edge" {
  count          = local.enable_sp ? 1 : 0
  application_id = azuread_application.aio_edge[0].id
  end_date       = timeadd(local.today, "720h") # By policy the default end date is not valid in some subscriptions
  # BUG: https://github.com/hashicorp/terraform-provider-azuread/issues/661
  # Occurs sometimes on destroying the resource, retrying the destroy solves the issue
  lifecycle {
    ignore_changes = [end_date]
  }
}

resource "azurerm_role_assignment" "connected_machine_onboarding" {
  principal_id                     = local.principal_id
  role_definition_name             = "Kubernetes Cluster - Azure Arc Onboarding"
  scope                            = var.resource_group_id
  skip_service_principal_aad_check = true # BUG: Role is never created for a new SP w/o this field: https://github.com/hashicorp/terraform-provider-azurerm/issues/11417
  depends_on                       = [azuread_application_password.aio_edge]
}
