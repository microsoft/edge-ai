/**
 * # Azure Event Hubs
 *
 * Create a new Event Hub namespace and Event Hub and optionall assign the current AIO extension the Azure Event Hubs Data Sender role.
 */

data "azurerm_subscription" "current" {}

locals {
  resource_group_id        = "${data.azurerm_subscription.current.id}/resourceGroups/${var.resource_group_name}"
  arc_connected_cluster_id = "${local.resource_group_id}/providers/Microsoft.Kubernetes/connectedClusters/${var.connected_cluster_name}"
}

data "azurerm_resource_group" "aio_rg" {
  name = var.resource_group_name
}

data "azapi_resource" "aio_extension" {
  type      = "Microsoft.KubernetesConfiguration/extensions@2022-11-01"
  name      = var.aio_extension_name
  parent_id = local.arc_connected_cluster_id

  response_export_values = ["identity.principalId"]
}

output "aio_extension_principal_id" {
  value = data.azapi_resource.aio_extension.output
}

resource "azurerm_eventhub_namespace" "destination_event_hub_namespace" {
  name                = "${var.resource_prefix}-aio-eh-ns"
  location            = data.azurerm_resource_group.aio_rg.location
  resource_group_name = data.azurerm_resource_group.aio_rg.name
  sku                 = var.sku
  capacity            = var.capacity
}

resource "azurerm_eventhub" "destination_eh" {
  name              = "${var.resource_prefix}-aio-eh"
  namespace_id      = azurerm_eventhub_namespace.destination_event_hub_namespace.id
  partition_count   = var.partition_count
  message_retention = var.message_retention
}

resource "azurerm_role_assignment" "data_sender" {
  # In future this will be moved out of the EH module
  scope                = azurerm_eventhub_namespace.destination_event_hub_namespace.id
  role_definition_name = "Azure Event Hubs Data Sender"
  principal_id         = data.azapi_resource.aio_extension.output.identity.principalId
}
