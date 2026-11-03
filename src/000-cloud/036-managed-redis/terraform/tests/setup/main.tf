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
  location             = "eastus2"
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
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
    id = local.virtual_network_id
  }
}

output "private_endpoint_subnet" {
  value = {
    id = "${local.virtual_network_id}/subnets/snet-pe-${local.resource_prefix}"
  }
}

output "managed_identity" {
  value = {
    id = "${local.resource_group_id}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-${local.resource_prefix}"
  }
}
