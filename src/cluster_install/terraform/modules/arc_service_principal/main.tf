/**
 * # Create Service Principal for Azure Arc
 *
 * Create SP with minimal permissions to onboard the VM to Azure Arc
 * Meant to make it easier to get the Virtual edge device up and running and not for production use
 *
 */

data "azurerm_client_config" "current" {}

locals {
  today = timestamp()
}

resource "azuread_application" "aio_edge" {
  display_name = "${var.resource_prefix}-arc-aio-sp"
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal" "aio_edge" {
  client_id = azuread_application.aio_edge.client_id
  owners    = [data.azurerm_client_config.current.object_id]
}

resource "azuread_application_password" "aio_edge" {
  application_id = azuread_application.aio_edge.id
  end_date       = timeadd(local.today, "720h") # By policy the default end date is not valid in some subscriptions
  # BUG: https://github.com/hashicorp/terraform-provider-azuread/issues/661
  # Occurs sometimes on destroying the resource, retrying the destroy solves the issue
  lifecycle {
    ignore_changes = [end_date]
  }
}

resource "azurerm_role_assignment" "connected_machine_onboarding" {
  principal_id                     = azuread_service_principal.aio_edge.object_id
  role_definition_name             = "Kubernetes Cluster - Azure Arc Onboarding"
  scope                            = var.resource_group_id
  skip_service_principal_aad_check = true # BUG: Role is never created for a new SP w/o this field: https://github.com/hashicorp/terraform-provider-azurerm/issues/11417
  depends_on                       = [azuread_application_password.aio_edge]
}
