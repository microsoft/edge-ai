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
  subscription_id_part  = "/subscriptions/00000000-0000-0000-0000-000000000000"
  resource_prefix       = "a${random_string.prefix.id}"
  resource_group_name   = "rg-${local.resource_prefix}"
  resource_group_id     = "${local.subscription_id_part}/resourceGroups/${local.resource_group_name}"
  custom_locations_name = "cl-${local.resource_prefix}"
  custom_locations_id   = "${local.resource_group_id}/providers/Microsoft.ExtendedLocation/customLocations/${local.custom_locations_name}"
  adr_namespace_name    = "adrns-${local.resource_prefix}"
  adr_namespace_id      = "${local.resource_group_id}/providers/Microsoft.DeviceRegistry/namespaces/${local.adr_namespace_name}"
  location              = "eastus2"
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
}

resource "random_uuid" "k8s_bridge_principal_id" {
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

output "custom_location_id" {
  value = local.custom_locations_id
}

output "adr_namespace" {
  value = {
    id = local.adr_namespace_id
  }
}

output "k8s_bridge_principal_id" {
  value = random_uuid.k8s_bridge_principal_id.result
}
