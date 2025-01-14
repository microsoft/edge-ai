/**
 * # Create Managed identity for Azure Arc cluster onboarding
 *
 * Create MI with minimal permissions to onboard the VM to Azure Arc
 * Meant to make it easier to get the Virtual edge device up and running and not for production use
 *
 */

resource "azurerm_user_assigned_identity" "arc_onboarding" {
  location            = var.location
  name                = "${var.resource_prefix}-arc-aio-mi"
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "connected_machine_onboarding" {
  principal_id         = azurerm_user_assigned_identity.arc_onboarding.principal_id
  role_definition_name = "Kubernetes Cluster - Azure Arc Onboarding"
  scope                = var.resource_group_id
}
