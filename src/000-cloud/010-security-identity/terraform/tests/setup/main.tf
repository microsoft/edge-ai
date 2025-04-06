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
  subscription_id_part = "/subscriptions/00000000-0000-0000-0000-000000000000"
  resource_prefix      = "a${random_string.prefix.id}"
  resource_group_name  = "rg-${local.resource_prefix}"
  resource_group_id    = "${local.subscription_id_part}/resourceGroups/${local.resource_group_name}"
  key_vault_name       = "kv-${local.resource_prefix}"
  key_vault_id         = "${local.subscription_id_part}/resourceGroups/${local.resource_group_name}/providers/Microsoft.KeyVault/vaults/${local.key_vault_name}"
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
}

output "resource_prefix" {
  value = local.resource_prefix
}

output "aio_resource_group" {
  value = {
    id       = local.resource_group_id
    name     = local.resource_group_name
    location = "eastus2"
  }
}

output "sse_key_vault" {
  value = {
    id = local.key_vault_id
  }
}

output "location" {
  value = "eastus2"
}

output "key_vault_name" {
  value = "kv-custom-${local.resource_prefix}"
}

output "key_vault_admin_principal_id" {
  value = "11111111-1111-1111-1111-111111111111"
}

output "onboard_identity_type" {
  value = "sp"
}
