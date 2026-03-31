terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
  }
  required_version = ">= 1.9.8, < 2.0"
}

locals {
  subscription_id_part    = "/subscriptions/00000000-0000-0000-0000-000000000000"
  resource_prefix         = "a${random_string.prefix.id}"
  resource_group_name     = "rg-${local.resource_prefix}"
  resource_group_id       = "${local.subscription_id_part}/resourceGroups/${local.resource_group_name}"
  resource_location       = "eastus2"
  eventhub_namespace_name = "evhns-${local.resource_prefix}-aio-test-001"
  storage_account_name    = "st${local.resource_prefix}test001"
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
  value = local.resource_location
}

output "resource_group" {
  value = {
    name     = local.resource_group_name
    id       = local.resource_group_id
    location = local.resource_location
  }
}

output "eventhub_namespace" {
  value = {
    id   = "${local.resource_group_id}/providers/Microsoft.EventHub/namespaces/${local.eventhub_namespace_name}"
    name = local.eventhub_namespace_name
  }
}

output "storage_account" {
  value = {
    id   = "${local.resource_group_id}/providers/Microsoft.Storage/storageAccounts/${local.storage_account_name}"
    name = local.storage_account_name
  }
}
