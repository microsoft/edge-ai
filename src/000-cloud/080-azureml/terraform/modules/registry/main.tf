/**
 * # AzureML Registry Module
 *
 * Creates an Azure Machine Learning Registry with optional private endpoint support.
 */

locals {
  registry_name = "mlr-${var.resource_prefix}-${var.environment}-${var.instance}"
}

resource "azapi_resource" "machine_learning_registry" {
  type      = "Microsoft.MachineLearningServices/registries@2025-07-01-preview"
  name      = local.registry_name
  parent_id = var.resource_group.id
  location  = var.location

  // Top-level identity per updated schema.
  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "Registry"
    properties = merge(
      {
        // publicNetworkAccess: Enabled | Disabled
        publicNetworkAccess = var.should_enable_public_network_access ? "Enabled" : "Disabled"

        // regionDetails: Provide existing ACR / Storage when supplied, otherwise empty arrays (service can create system resources if supported).
        regionDetails = [
          {
            location = var.location

            acrDetails = var.acr != null ? [
              {
                // Mapping existing ACR via armResourceId (schema nested path under systemCreatedAcrAccount.armResourceId.resourceId)
                systemCreatedAcrAccount = {
                  armResourceId = {
                    resourceId = var.acr.id
                  }
                }
              }
            ] : []

            storageAccountDetails = var.storage_account != null ? [
              {
                systemCreatedStorageAccount = {
                  armResourceId = {
                    resourceId = var.storage_account.id
                  }
                }
              }
            ] : []
          }
        ]
      },
      var.description != null ? { description = var.description } : {}
    )
  }
}

resource "azurerm_private_endpoint" "registry_pe" {
  count = var.should_enable_private_endpoint ? 1 : 0

  name                = "pe-${local.registry_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "registry-privatelink"
    private_connection_resource_id = azapi_resource.machine_learning_registry.id
    is_manual_connection           = false
    subresource_names              = ["amlregistry"]
  }
}

resource "azurerm_private_dns_a_record" "registry_endpoint" {
  count = var.should_enable_private_endpoint ? 1 : 0

  name                = local.registry_name
  zone_name           = var.api_dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.registry_pe[0].private_service_connection[0].private_ip_address]
}
