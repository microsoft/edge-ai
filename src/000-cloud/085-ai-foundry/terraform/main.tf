/**
 * # Microsoft Foundry
 *
 * Creates Microsoft Foundry infrastructure with accounts, projects, and model deployments
 * for AI development and deployment scenarios. Uses AzAPI provider for full API support.
 */

locals {
  ai_foundry_name = coalesce(var.ai_foundry_name, "aif-${var.resource_prefix}-${var.environment}-${var.instance}")

  // Customer-managed key encryption configuration
  encryption_config = var.should_enable_cmk_encryption && var.key_vault != null ? {
    keySource = "Microsoft.KeyVault"
    keyVaultProperties = {
      keyVaultUri      = var.key_vault.vault_uri
      keyName          = var.key_vault.key_name
      keyVersion       = try(var.key_vault.key_version, null)
      identityClientId = var.cmk_identity_client_id
    }
  } : null
}

resource "azapi_resource" "ai_foundry" {
  type                      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name                      = local.ai_foundry_name
  location                  = var.location
  parent_id                 = var.resource_group.id
  schema_validation_enabled = false
  tags                      = var.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "AIServices"
    sku = {
      name = var.sku
    }
    properties = merge(
      {
        allowProjectManagement = true
        customSubDomainName    = local.ai_foundry_name
        publicNetworkAccess    = var.should_enable_public_network_access ? "Enabled" : "Disabled"
        disableLocalAuth       = !var.should_enable_local_auth
        networkAcls = {
          defaultAction = "Allow"
        }
      },
      local.encryption_config != null ? { encryption = local.encryption_config } : {}
    )
  }

  response_export_values = ["identity.principalId", "properties.endpoint"]
}

resource "azapi_resource" "project" {
  for_each = var.ai_projects

  type                      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name                      = each.value.name
  location                  = var.location
  parent_id                 = azapi_resource.ai_foundry.id
  schema_validation_enabled = false
  tags                      = var.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    sku = {
      name = each.value.sku
    }
    properties = {
      displayName = each.value.display_name
      description = each.value.description
    }
  }

  response_export_values = ["identity.principalId", "properties.internalId"]
}

resource "azurerm_private_endpoint" "ai_foundry" {
  count = var.should_enable_private_endpoint ? 1 : 0

  name                = "pe-${local.ai_foundry_name}"
  location            = var.location
  resource_group_name = var.resource_group.name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${local.ai_foundry_name}"
    private_connection_resource_id = azapi_resource.ai_foundry.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = length(var.private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }

  depends_on = [azapi_resource.ai_foundry]
}

resource "azapi_resource" "rai_policy" {
  for_each = var.rai_policies

  type                      = "Microsoft.CognitiveServices/accounts/raiPolicies@2024-10-01"
  name                      = each.value.name
  parent_id                 = azapi_resource.ai_foundry.id
  schema_validation_enabled = false

  body = {
    properties = merge(
      {
        basePolicyName = each.value.base_policy_name
        mode           = each.value.mode
      },
      length(each.value.content_filters) > 0 ? {
        contentFilters = [
          for filter in each.value.content_filters : {
            name              = filter.name
            enabled           = filter.enabled
            blocking          = filter.blocking
            severityThreshold = filter.severity_threshold
            source            = filter.source
          }
        ]
      } : {}
    )
  }

  depends_on = [azapi_resource.ai_foundry]
}

resource "azapi_resource" "deployment" {
  for_each = var.model_deployments

  type                      = "Microsoft.CognitiveServices/accounts/deployments@2025-06-01"
  name                      = each.value.name
  parent_id                 = azapi_resource.ai_foundry.id
  schema_validation_enabled = false

  body = {
    sku = {
      name     = each.value.scale.type
      capacity = each.value.scale.capacity
    }
    properties = merge(
      {
        model = {
          format  = each.value.model.format
          name    = each.value.model.name
          version = each.value.model.version
        }
        versionUpgradeOption = each.value.version_upgrade_option
      },
      each.value.rai_policy_name != null ? { raiPolicyName = each.value.rai_policy_name } : {}
    )
  }

  depends_on = [azapi_resource.ai_foundry, azapi_resource.rai_policy]
}
