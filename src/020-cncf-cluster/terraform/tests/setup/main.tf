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
  virtual_machine_name = "vm-${local.resource_prefix}"
  virtual_machine_id   = "${local.resource_group_id}/providers/Microsoft.Compute/virtualMachines/${local.virtual_machine_name}"
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
}

output "resource_prefix" {
  value = "a${random_string.prefix.id}"
}

output "aio_resource_group" {
  value = {
    name = local.resource_group_name
    id   = local.resource_group_id
  }
}

output "aio_virtual_machine" {
  value = {
    name = local.virtual_machine_name
    id   = local.virtual_machine_id
  }
}
