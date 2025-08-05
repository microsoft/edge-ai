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
  location             = "eastus"
  subscription_id_part = "/subscriptions/00000000-0000-0000-0000-000000000000"
  resource_prefix      = "a${random_string.prefix.id}"
  resource_group_name  = "rg-${local.resource_prefix}"
  resource_group_id    = "${local.subscription_id_part}/resourceGroups/${local.resource_group_name}"

  # Mock identity for Arc onboarding
  identity_name = "id-${local.resource_prefix}-arc"
  identity_id   = "${local.resource_group_id}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${local.identity_name}"
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
    name     = local.resource_group_name
    id       = local.resource_group_id
    location = local.location
  }
}

output "mock_sp" {
  value = {
    client_id     = "00000000-0000-0000-0000-000000000001"
    object_id     = "00000000-0000-0000-0000-000000000002"
    client_secret = "mock-client-secret"
  }
}

output "mock_custom_locations_oid" {
  value = "00000000-0000-0000-0000-000000000003"
}

output "mock_identity" {
  value = {
    principal_id = "00000000-0000-0000-0000-000000000004"
    id           = local.identity_id
  }
}

output "key_vault" {
  value = {
    id        = "${local.resource_group_id}/providers/Microsoft.KeyVault/vaults/mock-key-vault"
    name      = "mock-key-vault"
    vault_uri = "mock-key-vault-uri"
  }
}

output "cluster_server_machine" {
  value = {
    id       = "${local.resource_group_id}/providers/Microsoft.Compute/virtualMachines/mock-vm"
    location = local.location
  }
}

output "mock_private_key_pem" {
  value = "<mock-private-key-pem>"
}

output "mock_http_proxy" {
  value = "http://mock-proxy:8080"
}
