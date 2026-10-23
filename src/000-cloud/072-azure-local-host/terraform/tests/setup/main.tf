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
  subscription_id      = "00000000-0000-0000-0000-000000000000"
  subscription_id_part = "/subscriptions/${local.subscription_id}"
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

output "subscription_id" {
  value = local.subscription_id
}

output "resource_group" {
  value = {
    name = local.resource_group_name
    id   = local.resource_group_id
  }
}

output "custom_locations_oid" {
  value = "${local.resource_group_id}/providers/Microsoft.ExtendedLocation/customLocations/cl-${local.resource_prefix}"
}

output "logical_network_name" {
  value = "lnet-${local.resource_prefix}"
}

output "logical_network_resource_group_name" {
  value = "rg-${local.resource_prefix}-network"
}
