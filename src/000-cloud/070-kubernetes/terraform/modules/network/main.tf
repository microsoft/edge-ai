/**
 * # Virtual Network Module
 *
 * Deploys virtual network resources for AKS
 */

locals {
  label_prefix_aks     = "${var.resource_prefix}-aks-${var.environment}-${var.instance}"
  label_prefix_aks_pod = "${var.resource_prefix}-aks-pod-${var.environment}-${var.instance}"
}

resource "azurerm_subnet_network_security_group_association" "snet_nsg_aks" {
  subnet_id                 = azurerm_subnet.snet_aks.id
  network_security_group_id = var.network_security_group.id
}

resource "azurerm_subnet_network_security_group_association" "snet_nsg_aks_pod" {
  subnet_id                 = azurerm_subnet.snet_aks_pod.id
  network_security_group_id = var.network_security_group.id
}

resource "azurerm_subnet" "snet_aks" {
  resource_group_name             = var.resource_group.name
  virtual_network_name            = var.virtual_network.name
  name                            = "subnet-${local.label_prefix_aks}"
  address_prefixes                = var.subnet_address_prefixes_aks
  default_outbound_access_enabled = var.default_outbound_access_enabled
}

resource "azurerm_subnet_nat_gateway_association" "snet_aks" {
  count = var.should_enable_nat_gateway ? 1 : 0

  nat_gateway_id = var.nat_gateway_id
  subnet_id      = azurerm_subnet.snet_aks.id
}

resource "azurerm_subnet" "snet_aks_pod" {
  resource_group_name             = var.resource_group.name
  virtual_network_name            = var.virtual_network.name
  name                            = "subnet-${local.label_prefix_aks_pod}"
  address_prefixes                = var.subnet_address_prefixes_aks_pod
  default_outbound_access_enabled = var.default_outbound_access_enabled

  delegation {
    name = "aks-delegation"
    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet_nat_gateway_association" "snet_aks_pod" {
  count = var.should_enable_nat_gateway ? 1 : 0

  nat_gateway_id = var.nat_gateway_id
  subnet_id      = azurerm_subnet.snet_aks_pod.id
}

resource "azurerm_subnet" "snet_aks_node_pool" {
  for_each = var.node_pools

  resource_group_name             = var.resource_group.name
  virtual_network_name            = var.virtual_network.name
  name                            = "subnet-${var.resource_prefix}-aks-${each.key}-${var.environment}-${var.instance}"
  address_prefixes                = each.value.subnet_address_prefixes
  default_outbound_access_enabled = var.default_outbound_access_enabled
}

resource "azurerm_subnet_nat_gateway_association" "snet_aks_node_pool" {
  for_each = var.should_enable_nat_gateway ? var.node_pools : {}

  nat_gateway_id = var.nat_gateway_id
  subnet_id      = azurerm_subnet.snet_aks_node_pool[each.key].id
}

resource "azurerm_subnet" "snet_aks_node_pool_pod" {
  for_each = var.node_pools

  resource_group_name             = var.resource_group.name
  virtual_network_name            = var.virtual_network.name
  name                            = "subnet-${var.resource_prefix}-aks-${each.key}-pod-${var.environment}-${var.instance}"
  address_prefixes                = each.value.pod_subnet_address_prefixes
  default_outbound_access_enabled = var.default_outbound_access_enabled

  delegation {
    name = "aks-delegation"
    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet_nat_gateway_association" "snet_aks_node_pool_pod" {
  for_each = var.should_enable_nat_gateway ? var.node_pools : {}

  nat_gateway_id = var.nat_gateway_id
  subnet_id      = azurerm_subnet.snet_aks_node_pool_pod[each.key].id
}

resource "azurerm_subnet_network_security_group_association" "snet_nsg_aks_node_pool" {
  for_each = var.node_pools

  subnet_id                 = azurerm_subnet.snet_aks_node_pool[each.key].id
  network_security_group_id = var.network_security_group.id
}

resource "azurerm_subnet_network_security_group_association" "snet_nsg_aks_node_pool_pod" {
  for_each = var.node_pools

  subnet_id                 = azurerm_subnet.snet_aks_node_pool_pod[each.key].id
  network_security_group_id = var.network_security_group.id
}
