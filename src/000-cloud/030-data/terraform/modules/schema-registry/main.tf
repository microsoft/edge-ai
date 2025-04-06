/**
 * # Azure Device Registry Schema Registry
 *
 * Responsible for creating a Blob Container for the schema, ADR Schema Registry, and a
 * Storage Blob Data Contributor Role Assignment.
 *
 */

locals {
  schema_container_name = "schemas"
  registry_name         = "sr-${var.resource_prefix}-${var.environment}-${var.instance}"
  registry_namespace    = "srns-${var.resource_prefix}-${var.environment}-${var.instance}"
}

/*
 * Blob Container
 */

resource "azurerm_storage_container" "schema_container" {
  name               = local.schema_container_name
  storage_account_id = var.storage_account.id
}

/*
 * Schema Registry
 */

resource "azapi_resource" "schema_registry" {
  type      = "Microsoft.DeviceRegistry/schemaRegistries@2024-09-01-preview"
  parent_id = var.resource_group.id
  name      = local.registry_name
  location  = var.location

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      namespace                  = local.registry_namespace
      storageAccountContainerUrl = "${var.storage_account.primary_blob_endpoint}${azurerm_storage_container.schema_container.name}"
    }
  }

  response_export_values = ["name", "id", "identity.principalId"]
}

/*
 * Role Assignment
 */

resource "azurerm_role_assignment" "registry_storage_contributor" {
  principal_id         = azapi_resource.schema_registry.output.identity.principalId
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_container.schema_container.id
  // BUG: Role is never created for a new SP w/o this field: https://github.com/hashicorp/terraform-provider-azurerm/issues/11417
  skip_service_principal_aad_check = true
}
