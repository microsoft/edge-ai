/**
 * # K8 Bridge Role Assignment Module
 *
 * Assigns Azure Kubernetes Service Arc Contributor Role to K8 Bridge principal.
 */

locals {
  // K8 Bridge principal ID lookup logic
  k8s_bridge_principal_id = var.k8s_bridge_principal_id == null ? (
    try(coalesce(var.k8s_bridge_principal_id, data.azuread_service_principal.k8_bridge[0].object_id), "")
  ) : null
}

resource "azurerm_role_assignment" "k8_bridge_role_assignment" {
  scope                = var.custom_location_id
  role_definition_name = "Azure Kubernetes Service Arc Contributor Role"
  principal_id         = local.k8s_bridge_principal_id
  principal_type       = "ServicePrincipal"
}

data "azuread_service_principal" "k8_bridge" {
  count = var.k8s_bridge_principal_id == null ? 1 : 0
  // K8 Bridge
  display_name = "K8 Bridge"
}
