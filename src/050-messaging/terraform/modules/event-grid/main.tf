/**
 * # Azure Event Grid
 *
 * Create a new Event Grid namespace and namespace topic and assign the AIO instance UAMI the EventGrid TopicSpaces Publisher role.
 */

resource "azurerm_eventgrid_namespace" "aio_eg_ns" {
  name                = "egns-${var.resource_prefix}-aio"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  capacity            = var.capacity

  topic_spaces_configuration {
    maximum_client_sessions_per_authentication_name = var.event_grid_max_client_sessions_per_auth_name
  }
}

resource "azapi_resource" "event_grid_namespace_topic_space" {
  type      = "Microsoft.EventGrid/namespaces/topicSpaces@2024-12-15-preview"
  parent_id = azurerm_eventgrid_namespace.aio_eg_ns.id
  name      = "eg-topic-${var.resource_prefix}-aio"
  body = {
    properties = {
      topicTemplates = [
        var.topic_name
      ]
    }
  }
}

resource "azurerm_role_assignment" "data_sender" {
  scope                = azapi_resource.event_grid_namespace_topic_space.id
  role_definition_name = "EventGrid TopicSpaces Publisher"
  principal_id         = var.aio_uami_principal_id
}


