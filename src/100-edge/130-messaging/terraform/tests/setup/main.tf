terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
  }
  required_version = ">= 1.9.8, < 2.0"
}

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
  default     = "test"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "msg"
}

variable "component" {
  description = "Component name"
  type        = string
  default     = "messaging"
}

locals {
  resource_group_name = "rg-${var.environment}-${var.prefix}-${var.component}"
  custom_location_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${local.resource_group_name}/providers/Microsoft.ExtendedLocation/customLocations/cl-test"
  aio_instance_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${local.resource_group_name}/providers/Microsoft.IoTOperations/instances/aio-test"
  dataflow_profile_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${local.resource_group_name}/providers/Microsoft.IoTOperations/instances/aio-test/dataflowProfiles/profile-test"
  identity_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${local.resource_group_name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-test"
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
}

output "resource_prefix" {
  value = "a${random_string.prefix.id}"
}

output "environment" {
  value = var.environment
}

output "instance" {
  value = "001"
}

output "aio_identity" {
  value = {
    id           = local.identity_id
    principal_id = "00000000-0000-0000-0000-000000000001"
    tenant_id    = "00000000-0000-0000-0000-000000000002"
    client_id    = "00000000-0000-0000-0000-000000000003"
  }
}

output "aio_custom_locations" {
  value = {
    name = "cl-test"
    id   = local.custom_location_id
  }
}

output "aio_instance" {
  value = {
    id = local.aio_instance_id
  }
}

output "aio_dataflow_profile" {
  value = {
    id = local.dataflow_profile_id
  }
}

output "eventhub" {
  value = {
    namespace_name = "evhns-test"
    eventhub_name  = "evh-test"
  }
}

output "eventgrid" {
  value = {
    topic_name = "egt-test"
    endpoint   = "https://egt-test.eastus2-1.eventgrid.azure.net"
  }
}
