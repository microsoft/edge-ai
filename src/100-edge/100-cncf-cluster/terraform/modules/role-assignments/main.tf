/**
 * # Key Vault Role Assignment
 *
 * Assigns Azure RBAC roles for Key Vault access
 */

/*
 * Role Assignments
 */

resource "azurerm_role_assignment" "connected_machine_onboarding" {
  count = length(var.arc_onboarding_principal_ids)

  scope                = var.resource_group.id
  role_definition_name = "Kubernetes Cluster - Azure Arc Onboarding"
  principal_id         = var.arc_onboarding_principal_ids[count.index]
  // BUG: Role is never created for a new SP w/o this field: https://github.com/hashicorp/terraform-provider-azurerm/issues/11417
  skip_service_principal_aad_check = true
}

// Assign Secrets Officer role at vault level
resource "azurerm_role_assignment" "secrets_officer" {
  count = var.should_upload_to_key_vault ? length(var.arc_onboarding_principal_ids) : 0

  scope                = var.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.arc_onboarding_principal_ids[count.index]
  // BUG: Role is never created for a new SP w/o this field: https://github.com/hashicorp/terraform-provider-azurerm/issues/11417
  skip_service_principal_aad_check = true
}

// Assign Key Vault Reader role at vault level for listing secrets
resource "azurerm_role_assignment" "key_vault_reader" {
  count = var.should_upload_to_key_vault ? length(var.arc_onboarding_principal_ids) : 0

  scope                = var.key_vault.id
  role_definition_name = "Key Vault Reader"
  principal_id         = var.arc_onboarding_principal_ids[count.index]
  // BUG: Role is never created for a new SP w/o this field: https://github.com/hashicorp/terraform-provider-azurerm/issues/11417
  skip_service_principal_aad_check = true
}
