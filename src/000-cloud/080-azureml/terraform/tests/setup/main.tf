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
    name     = local.resource_group_name
    id       = local.resource_group_id
    location = local.location
  }
}

output "application_insights" {
  value = {
    name                = "appi-${local.resource_prefix}"
    id                  = "${local.resource_group_id}/providers/Microsoft.Insights/components/appi-${local.resource_prefix}"
    instrumentation_key = "00000000-0000-0000-0000-000000000001"
  }
}

output "key_vault" {
  value = {
    name = "kv-${local.resource_prefix}"
    id   = "${local.resource_group_id}/providers/Microsoft.KeyVault/vaults/kv-${local.resource_prefix}"
  }
}

output "storage_account" {
  value = {
    name = "st${local.resource_prefix}"
    id   = "${local.resource_group_id}/providers/Microsoft.Storage/storageAccounts/st${local.resource_prefix}"
  }
}

output "acr" {
  value = {
    id = "${local.resource_group_id}/providers/Microsoft.ContainerRegistry/registries/acr${local.resource_prefix}"
  }
}

output "virtual_network" {
  value = {
    name = "vnet-${local.resource_prefix}"
    id   = "${local.resource_group_id}/providers/Microsoft.Network/virtualNetworks/vnet-${local.resource_prefix}"
  }
}

output "private_endpoint_subnet_id" {
  value = "${local.resource_group_id}/providers/Microsoft.Network/virtualNetworks/vnet-${local.resource_prefix}/subnets/snet-pe"
}

output "compute_cluster_subnet" {
  value = {
    name = "snet-ml"
    id   = "${local.resource_group_id}/providers/Microsoft.Network/virtualNetworks/vnet-${local.resource_prefix}/subnets/snet-ml"
  }
}

output "kubernetes" {
  value = {
    name                = "aks-${local.resource_prefix}"
    id                  = "${local.resource_group_id}/providers/Microsoft.ContainerService/managedClusters/aks-${local.resource_prefix}"
    resource_group_name = local.resource_group_name
    default_node_pool = [
      {
        name       = "default"
        node_count = 1
        vm_size    = "Standard_D4s_v5"
      }
    ]
  }
}
