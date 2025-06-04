/**
 * # K8 Bridge Role Assignment Module
 *
 * Assigns Azure Kubernetes Service Arc Contributor Role to K8 Bridge principal.
 */

locals {
  // K8 Bridge principal ID logic - use provided ID or lookup
  k8s_bridge_principal_id = coalesce(
    var.k8s_bridge_principal_id,
    try(data.azuread_service_principal.k8_bridge[0].object_id, null)
  )
}

data "azuread_service_principal" "k8_bridge" {
  count        = var.k8s_bridge_principal_id == null ? 1 : 0
  display_name = "K8 Bridge"
}

resource "azurerm_role_assignment" "k8_bridge_role_assignment" {
  scope                = var.custom_location_id
  role_definition_name = "Azure Kubernetes Service Arc Contributor Role"
  principal_id         = local.k8s_bridge_principal_id
  principal_type       = "ServicePrincipal"
}
