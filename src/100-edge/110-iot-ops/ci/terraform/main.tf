# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "aio" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_key_vault" "sse" {
  name                = "kv-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azurerm_user_assigned_identity" "sse" {
  name                = "id-${var.resource_prefix}-sse-${var.environment}-${var.instance}"
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azurerm_user_assigned_identity" "aio" {
  name                = "id-${var.resource_prefix}-aio-${var.environment}-${var.instance}"
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azapi_resource" "schema_registry" {
  type      = "Microsoft.DeviceRegistry/schemaRegistries@2025-07-01-preview"
  parent_id = data.azurerm_resource_group.aio.id
  name      = "sr-${var.resource_prefix}-${var.environment}-${var.instance}"

  response_export_values = ["name", "id"]
}

data "azapi_resource" "arc_connected_cluster" {
  type      = "Microsoft.Kubernetes/connectedClusters@2024-01-01"
  parent_id = data.azurerm_resource_group.aio.id
  name      = "arck-${var.resource_prefix}-${var.environment}-${var.instance}"

  response_export_values = ["name", "id", "location"]
}

data "azapi_resource" "adr_namespace" {
  type      = "Microsoft.DeviceRegistry/namespaces@2025-07-01-preview"
  parent_id = data.azurerm_resource_group.aio.id
  name      = "adrns-${var.resource_prefix}-${var.environment}-${var.instance}"

  response_export_values = ["name", "id"]
}

module "ci" {
  source = "../../terraform"

  resource_group        = data.azurerm_resource_group.aio
  secret_sync_key_vault = data.azurerm_key_vault.sse
  secret_sync_identity  = data.azurerm_user_assigned_identity.sse
  aio_identity          = data.azurerm_user_assigned_identity.aio
  adr_schema_registry   = data.azapi_resource.schema_registry.output
  arc_connected_cluster = data.azapi_resource.arc_connected_cluster.output
  adr_namespace         = data.azapi_resource.adr_namespace.output
}
