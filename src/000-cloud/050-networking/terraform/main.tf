/**
 * # Virtual Network
 *
 * Creates a virtual network with subnets and associated network security groups for Azure resources.
 * This component provides the foundational networking infrastructure for cloud resources.
 */

data "azurerm_client_config" "current" {}

data "external" "deployment_client_ip" {
  count = var.should_use_network_security_perimeter ? 1 : 0

  program = ["bash", "-c", <<-EOT
    set -euo pipefail
    for endpoint in \
      "https://api64.ipify.org" \
      "https://ifconfig.me/ip" \
      "https://icanhazip.com"; do
      if public_ip=$(curl --fail --silent --retry 2 --max-time 10 "$${endpoint}"); then
        printf '{"ip":"%s"}\n' "$${public_ip}"
        exit 0
      fi
    done
    printf 'Unable to detect the deployment client public IP address\n' >&2
    exit 1
  EOT
  ]
}

locals {
  // Resource naming following Azure naming conventions; overridable to reference existing resources
  network_security_group_name  = coalesce(var.network_security_group_name, "nsg-${var.resource_prefix}-${var.environment}-${var.instance}")
  subnet_name                  = coalesce(var.subnet_name, "snet-${var.resource_prefix}-${var.environment}-${var.instance}")
  virtual_network_name         = coalesce(var.virtual_network_name, "vnet-${var.resource_prefix}-${var.environment}-${var.instance}")
  existing_resource_group_name = coalesce(var.existing_resource_group_name, var.resource_group.name)

  deployment_client_ip                = var.should_use_network_security_perimeter ? trimspace(data.external.deployment_client_ip[0].result.ip) : null
  deployment_client_ip_address_prefix = var.should_use_network_security_perimeter ? "${local.deployment_client_ip}${strcontains(local.deployment_client_ip, ":") ? "/128" : "/32"}" : null
  network_security_perimeter_allowed_ip_address_prefixes = var.should_use_network_security_perimeter ? distinct(concat(
    var.network_security_perimeter_allowed_ip_address_prefixes,
    [local.deployment_client_ip_address_prefix]
  )) : []
}

check "deployment_client_ip" {
  assert {
    condition     = !var.should_use_network_security_perimeter || can(cidrhost(local.deployment_client_ip_address_prefix, 0))
    error_message = "The deployment client's public IP address could not be detected as a valid IPv4 or IPv6 address"
  }
}

resource "azurerm_network_security_group" "main" {
  count = var.use_existing_virtual_network ? 0 : 1

  name                = local.network_security_group_name
  location            = var.location
  resource_group_name = var.resource_group.name

  tags = {
    "azd-env-name" = var.environment
  }
}

data "azurerm_network_security_group" "existing" {
  count = var.use_existing_virtual_network ? 1 : 0

  name                = local.network_security_group_name
  resource_group_name = local.existing_resource_group_name
}

resource "azurerm_virtual_network" "main" {
  count = var.use_existing_virtual_network ? 0 : 1

  name                = local.virtual_network_name
  location            = var.location
  resource_group_name = var.resource_group.name
  address_space       = [var.virtual_network_config.address_space]

  tags = {
    "azd-env-name" = var.environment
  }
}

data "azurerm_virtual_network" "existing" {
  count = var.use_existing_virtual_network ? 1 : 0

  name                = local.virtual_network_name
  resource_group_name = local.existing_resource_group_name
}

resource "azurerm_subnet" "main" {
  count = var.use_existing_virtual_network ? 0 : 1

  name                            = local.subnet_name
  resource_group_name             = var.resource_group.name
  virtual_network_name            = azurerm_virtual_network.main[0].name
  address_prefixes                = [var.virtual_network_config.subnet_address_prefix]
  default_outbound_access_enabled = var.default_outbound_access_enabled
}

data "azurerm_subnet" "existing" {
  count = var.use_existing_virtual_network ? 1 : 0

  name                 = local.subnet_name
  virtual_network_name = local.virtual_network_name
  resource_group_name  = local.existing_resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "main" {
  count = var.use_existing_virtual_network ? 0 : 1

  subnet_id                 = azurerm_subnet.main[0].id
  network_security_group_id = azurerm_network_security_group.main[0].id
}

module "nat_gateway" {
  count = !var.use_existing_virtual_network && var.should_enable_nat_gateway ? 1 : 0

  source = "./modules/nat-gateway"

  resource_group          = var.resource_group
  location                = var.location
  environment             = var.environment
  resource_prefix         = var.resource_prefix
  instance                = var.instance
  public_ip_count         = var.nat_gateway_public_ip_count
  availability_zones      = var.nat_gateway_zones
  idle_timeout_in_minutes = var.nat_gateway_idle_timeout_minutes
}

resource "azurerm_subnet_nat_gateway_association" "main" {
  count = !var.use_existing_virtual_network && var.should_enable_nat_gateway ? 1 : 0

  nat_gateway_id = module.nat_gateway[0].nat_gateway.id
  subnet_id      = azurerm_subnet.main[0].id
}

module "private_resolver" {
  count = !var.use_existing_virtual_network && var.should_enable_private_resolver ? 1 : 0

  source = "./modules/private-resolver"

  resource_group                  = var.resource_group
  virtual_network                 = azurerm_virtual_network.main[0]
  location                        = var.location
  resource_prefix                 = var.resource_prefix
  environment                     = var.environment
  instance                        = var.instance
  default_outbound_access_enabled = var.default_outbound_access_enabled
  resolver_subnet_address_prefix  = var.resolver_subnet_address_prefix
  should_enable_nat_gateway       = var.should_enable_nat_gateway
  nat_gateway_id                  = module.nat_gateway[0].nat_gateway.id
}

resource "azurerm_virtual_network_dns_servers" "main" {
  count = !var.use_existing_virtual_network && var.should_enable_private_resolver ? 1 : 0

  virtual_network_id = azurerm_virtual_network.main[0].id
  dns_servers        = [module.private_resolver[0].dns_server_ip]
}

module "network_security_perimeter" {
  count = var.should_use_network_security_perimeter ? 1 : 0

  source = "./modules/network-security-perimeter"

  allowed_ip_address_prefixes = local.network_security_perimeter_allowed_ip_address_prefixes
  environment                 = var.environment
  instance                    = var.instance
  location                    = var.location
  resource_group_id           = var.resource_group.id
  resource_prefix             = var.resource_prefix
  subscription_id             = data.azurerm_client_config.current.subscription_id
}
