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
  subscription_id_part            = "/subscriptions/00000000-0000-0000-0000-000000000000"
  resource_prefix                 = "a${random_string.prefix.id}"
  resource_group_name             = "rg-${local.resource_prefix}"
  resource_group_id               = "${local.subscription_id_part}/resourceGroups/${local.resource_group_name}"
  key_vault_name                  = "kv-${local.resource_prefix}"
  key_vault_id                    = "${local.subscription_id_part}/resourceGroups/${local.resource_group_name}/providers/Microsoft.KeyVault/vaults/${local.key_vault_name}"
  sse_user_assigned_identity_name = "uami-sse-${local.resource_prefix}"
  sse_user_assigned_identity_id   = "${local.resource_group_id}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${local.sse_user_assigned_identity_name}"
  aio_user_assigned_identity_name = "uami-aio-${local.resource_prefix}"
  aio_user_assigned_identity_id   = "${local.resource_group_id}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${local.aio_user_assigned_identity_name}"
  adr_schema_registry_name        = "adr-${local.resource_prefix}"
  adr_schema_registry_id          = "${local.resource_group_id}/providers/Microsoft.DeviceRegistry/schemaRegistries/${local.adr_schema_registry_name}"
  arc_connected_cluster_name      = "arc-${local.resource_prefix}"
  arc_connected_cluster_id        = "${local.resource_group_id}/providers/Microsoft.Kubernetes/connectedClusters/${local.arc_connected_cluster_name}"
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
}

resource "random_uuid" "client_id" {
}

output "resource_prefix" {
  value = "a${random_string.prefix.id}"
}

output "aio_resource_group" {
  value = {
    name     = local.resource_group_name
    id       = local.resource_group_id
    location = "eastus2"
  }
}

output "sse_key_vault" {
  value = {
    name = local.key_vault_name
    id   = local.key_vault_id
  }
}

output "sse_user_assigned_identity" {
  value = {
    id        = local.sse_user_assigned_identity_id
    client_id = random_uuid.client_id.result
  }
}

output "aio_user_assigned_identity" {
  value = {
    id = local.aio_user_assigned_identity_id
  }
}

output "adr_schema_registry" {
  value = {
    id = local.adr_schema_registry_id
  }
}

output "arc_connected_cluster" {
  value = {
    name     = local.arc_connected_cluster_name
    id       = local.arc_connected_cluster_id
    location = "eastus2"
  }
}
