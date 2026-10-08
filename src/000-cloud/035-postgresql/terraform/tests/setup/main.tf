terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
  }
  required_version = ">= 1.12.0, < 2.0"
}

locals {
  subscription_id_part = "/subscriptions/00000000-0000-0000-0000-000000000000"
  resource_prefix      = "a${random_string.prefix.id}"
  resource_group_name  = "rg-${local.resource_prefix}"
  resource_group_id    = "${local.subscription_id_part}/resourceGroups/${local.resource_group_name}"
  virtual_network_name = "vnet-${local.resource_prefix}"
  virtual_network_id   = "${local.resource_group_id}/providers/Microsoft.Network/virtualNetworks/${local.virtual_network_name}"
  key_vault_name       = "kv-${local.resource_prefix}"
  location             = "eastus2"
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
}

resource "random_password" "admin_password" {
  length  = 20
  special = true
}

output "resource_prefix" {
  value = local.resource_prefix
}

output "location" {
  value = local.location
}

output "resource_group" {
  value = {
    name = local.resource_group_name
    id   = local.resource_group_id
  }
}

output "virtual_network" {
  value = {
    name = local.virtual_network_name
    id   = local.virtual_network_id
  }
}

output "delegated_subnet_id" {
  value = "${local.virtual_network_id}/subnets/snet-postgres-${local.resource_prefix}"
}

output "network_security_group" {
  value = {
    id = "${local.resource_group_id}/providers/Microsoft.Network/networkSecurityGroups/nsg-${local.resource_prefix}"
  }
}

output "key_vault" {
  value = {
    name = local.key_vault_name
    id   = "${local.resource_group_id}/providers/Microsoft.KeyVault/vaults/${local.key_vault_name}"
  }
}

output "admin_password" {
  value     = random_password.admin_password.result
  sensitive = true
}
