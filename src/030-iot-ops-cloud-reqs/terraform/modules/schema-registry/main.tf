/**
 * # Azure IoT Schema Registry Module
 *
 * Deploys a storage account and schema registry to be used for Azure IoT Operations deployments
 *
 */

data "azurerm_subscription" "current" {}

resource "random_string" "name" {
  length  = 10
  special = false
  upper   = false
}

locals {
  storage_account_name  = var.storage_account.name == "" ? "st${random_string.name.result}" : var.storage_account.name
  schema_container_name = "schemas"
  registry_name         = "sch-reg-${var.resource_prefix}-${var.environment}-${var.instance}"
  registry_namespace    = "sch-reg-ns-${var.resource_prefix}-${var.environment}-${var.instance}"
}

resource "azurerm_storage_account" "schema_registry_store" {
  name                            = local.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = var.storage_account.tier
  account_replication_type        = var.storage_account.replication_type
  is_hns_enabled                  = true
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "schema_container" {
  name               = local.schema_container_name
  storage_account_id = azurerm_storage_account.schema_registry_store.id
}

resource "azapi_resource" "schema_registry" {
  type      = "Microsoft.DeviceRegistry/schemaRegistries@2024-09-01-preview"
  name      = local.registry_name
  location  = var.location
  parent_id = "${data.azurerm_subscription.current.id}/resourceGroups/${var.resource_group_name}"
  identity {
    type = "SystemAssigned"
  }
  body = {
    properties = {
      namespace                  = local.registry_namespace
      storageAccountContainerUrl = "${azurerm_storage_account.schema_registry_store.primary_blob_endpoint}${azurerm_storage_container.schema_container.name}"
    }
  }
  response_export_values = ["name", "id", "identity.principalId"]
}

resource "azurerm_role_assignment" "registry_storage_contributor" {
  principal_id                     = azapi_resource.schema_registry.output.identity.principalId
  role_definition_name             = "Storage Blob Data Contributor"
  scope                            = azurerm_storage_container.schema_container.id
  skip_service_principal_aad_check = true # BUG: Role is never created for a new SP w/o this field: https://github.com/hashicorp/terraform-provider-azurerm/issues/11417
}
