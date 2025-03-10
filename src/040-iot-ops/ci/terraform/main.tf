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
  name                = "uami-${var.resource_prefix}-${var.environment}-sse-${var.instance}"
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azurerm_user_assigned_identity" "aio" {
  name                = "uami-${var.resource_prefix}-${var.environment}-aio-${var.instance}"
  resource_group_name = data.azurerm_resource_group.aio.name
}

data "azapi_resource" "schema_registry" {
  type      = "Microsoft.DeviceRegistry/schemaRegistries@2024-09-01-preview"
  parent_id = data.azurerm_resource_group.aio.id
  name      = "sch-reg-${var.resource_prefix}-${var.environment}-${var.instance}"

  response_export_values = ["name", "id"]
}

data "azapi_resource" "arc_connected_cluster" {
  type      = "Microsoft.Kubernetes/connectedClusters@2024-01-01"
  parent_id = data.azurerm_resource_group.aio.id
  name      = "arc-${var.resource_prefix}-${var.environment}-${var.instance}"

  response_export_values = ["name", "id", "location"]
}

module "iot_ops" {
  source = "../../terraform"

  aio_resource_group         = data.azurerm_resource_group.aio
  sse_key_vault              = data.azurerm_key_vault.sse
  sse_user_assigned_identity = data.azurerm_user_assigned_identity.sse
  aio_user_assigned_identity = data.azurerm_user_assigned_identity.aio
  adr_schema_registry        = data.azapi_resource.schema_registry.output
  arc_connected_cluster      = data.azapi_resource.arc_connected_cluster.output
}
