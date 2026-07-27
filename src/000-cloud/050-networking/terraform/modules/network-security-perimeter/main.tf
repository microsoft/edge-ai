resource "azapi_resource" "main" {
  type      = "Microsoft.Network/networkSecurityPerimeters@2025-01-01"
  name      = "nsp-${var.resource_prefix}-${var.environment}-${var.instance}"
  parent_id = var.resource_group_id
  location  = var.location

  body = {
    properties = {}
  }
}

resource "azapi_resource" "profile" {
  type      = "Microsoft.Network/networkSecurityPerimeters/profiles@2025-01-01"
  name      = "defaultprofile"
  parent_id = azapi_resource.main.id

  body = {
    properties = {}
  }
}

resource "azapi_resource" "deployment_clients" {
  count = length(var.allowed_ip_address_prefixes) > 0 ? 1 : 0

  type      = "Microsoft.Network/networkSecurityPerimeters/profiles/accessRules@2025-01-01"
  name      = "allow-deployment-clients"
  parent_id = azapi_resource.profile.id

  body = {
    properties = {
      direction       = "Inbound"
      addressPrefixes = var.allowed_ip_address_prefixes
    }
  }
}

resource "azapi_resource" "subscription" {
  type      = "Microsoft.Network/networkSecurityPerimeters/profiles/accessRules@2025-01-01"
  name      = "allow-current-subscription"
  parent_id = azapi_resource.profile.id

  body = {
    properties = {
      direction = "Inbound"
      subscriptions = [
        {
          id = "/subscriptions/${var.subscription_id}"
        }
      ]
    }
  }
}
