terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
  }
  required_version = ">= 1.9.8, < 2.0"
}

provider "azurerm" {
  features {}
}

locals {
  location                    = "eastus2"
  subscription_id             = "00000000-0000-0000-0000-000000000000"
  subscription_id_part        = "/subscriptions/${local.subscription_id}"
  resource_prefix             = "a${random_string.prefix.id}"
  environment                 = "dev"
  instance                    = "001"
  label_prefix                = "${local.resource_prefix}-aio-${local.environment}-${local.instance}"
  resource_group_name         = "rg-${local.resource_prefix}"
  resource_group_id           = "${local.subscription_id_part}/resourceGroups/${local.resource_group_name}"
  network_security_group_name = "nsg-${local.label_prefix}"
  virtual_network_name        = "vnet-${local.label_prefix}"
  virtual_network_id          = "${local.resource_group_id}/providers/Microsoft.Network/virtualNetworks/${local.virtual_network_name}"
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_resource_group" "test" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_network_security_group" "test" {
  name                = local.network_security_group_name
  location            = local.location
  resource_group_name = azurerm_resource_group.test.name
}

output "resource_prefix" {
  value = local.resource_prefix
}

output "environment" {
  value = local.environment
}

output "location" {
  value = local.location
}

output "instance" {
  value = local.instance
}

output "resource_group" {
  value = {
    name     = azurerm_resource_group.test.name
    id       = azurerm_resource_group.test.id
    location = azurerm_resource_group.test.location
  }
}

output "network_security_group" {
  value = {
    id   = azurerm_network_security_group.test.id
    name = azurerm_network_security_group.test.name
  }
}

output "virtual_network" {
  value = {
    name = local.virtual_network_name
    id   = local.virtual_network_id
  }
}

output "acr" {
  value = {
    name = local.virtual_network_name
    id   = local.virtual_network_id
  }
}
