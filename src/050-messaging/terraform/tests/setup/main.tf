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
  custom_locations_name           = "cl-${local.resource_prefix}"
  custom_locations_id             = "${local.subscription_id_part}/resourceGroups/${local.resource_group_name}/providers/Microsoft.ExtendedLocation/customLocations/${local.custom_locations_name}"
  aio_instance_name               = "aio-instance-${local.resource_prefix}"
  aio_instance_id                 = "${local.resource_group_id}/providers/Microsoft.IoTOperations/instances/${local.aio_instance_name}"
  aio_user_assigned_identity_name = "uami-aio-${local.resource_prefix}"
  aio_user_assigned_identity_id   = "${local.resource_group_id}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${local.aio_user_assigned_identity_name}"
  aio_dataflow_profile_id         = "${local.aio_instance_id}/dataflowProfiles/default"
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
}

resource "random_uuid" "principal_id" {
}

resource "random_uuid" "tenant_id" {
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

output "aio_user_assigned_identity" {
  value = {
    id           = local.aio_user_assigned_identity_id
    principal_id = random_uuid.principal_id.result
    tenant_id    = random_uuid.tenant_id.result
    client_id    = random_uuid.client_id.result
  }
}

output "aio_custom_locations" {
  value = {
    name = local.custom_locations_name
    id   = local.custom_locations_id
  }
}

output "aio_instance" {
  value = {
    id = local.aio_instance_id
  }
}

output "aio_dataflow_profile" {
  value = {
    id = local.aio_dataflow_profile_id
  }
}
