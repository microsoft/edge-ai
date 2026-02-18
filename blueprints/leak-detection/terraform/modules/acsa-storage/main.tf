/**
 * # ACSA Storage
 *
 * Creates a storage container for Azure Container Storage Arc (ACSA)
 * cloud-backed volumes and grants the ACSA extension identity
 * Storage Blob Data Owner access.
 */

resource "azurerm_storage_container" "media" {
  name                  = "media"
  storage_account_id    = var.storage_account_id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "acsa_blob_data_owner" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = var.acsa_extension_principal_id
  principal_type       = "ServicePrincipal"
}
