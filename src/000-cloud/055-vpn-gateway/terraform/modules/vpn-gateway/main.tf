/**
 * # VPN Gateway Implementation
 *
 * Creates VPN Gateway with Point-to-Site configuration, GatewaySubnet,
 * public IP, and private DNS zones for Azure services.
 */

locals {
  gateway_subnet_name = "GatewaySubnet" // Fixed name required by Azure
  public_ip_name      = "pip-vpngateway-${var.resource_prefix}-${var.environment}-${var.instance}"
  vpn_gateway_name    = "vng-${var.resource_prefix}-${var.environment}-${var.instance}"
  tenant_id           = try(coalesce(var.azure_ad_config.tenant_id), data.azurerm_client_config.current.tenant_id)
}

data "azurerm_client_config" "current" {
}

/*
 * VPN Gateway Subnet
 */

resource "azurerm_subnet" "gateway_subnet" {
  name                            = local.gateway_subnet_name
  resource_group_name             = var.resource_group.name
  virtual_network_name            = var.virtual_network.name
  address_prefixes                = var.vpn_gateway_subnet_address_prefixes
  default_outbound_access_enabled = var.default_outbound_access_enabled
}

/*
 * Public IP for VPN Gateway
 */

resource "azurerm_public_ip" "vpn_gateway" {
  name                = local.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

/*
 * VPN Gateway with Point-to-Site Configuration
 */

resource "azurerm_virtual_network_gateway" "vpn" {
  name                = local.vpn_gateway_name
  location            = var.location
  resource_group_name = var.resource_group.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = var.vpn_gateway_config.sku
  generation    = var.vpn_gateway_config.generation

  ip_configuration {
    name                 = "vnetGatewayConfig"
    public_ip_address_id = azurerm_public_ip.vpn_gateway.id
    subnet_id            = azurerm_subnet.gateway_subnet.id
  }

  vpn_client_configuration {
    address_space = var.vpn_gateway_config.client_address_pool

    // Certificate authentication configuration
    dynamic "root_certificate" {
      for_each = !var.should_use_azure_ad_auth ? [1] : []
      content {
        name             = var.root_certificate_name
        public_cert_data = var.root_certificate_public_data
      }
    }

    // Azure AD authentication configuration
    aad_tenant   = var.should_use_azure_ad_auth ? "https://login.microsoftonline.com/${local.tenant_id}/" : null
    aad_audience = var.should_use_azure_ad_auth ? coalesce(var.azure_ad_config.audience) : null
    aad_issuer   = var.should_use_azure_ad_auth ? coalesce(var.azure_ad_config.issuer, "https://sts.windows.net/${local.tenant_id}/") : null

    vpn_client_protocols = var.should_use_azure_ad_auth ? ["OpenVPN"] : var.vpn_gateway_config.protocols
  }

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}


