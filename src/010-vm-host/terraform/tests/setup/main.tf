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
  subscription_id_part  = "/subscriptions/00000000-0000-0000-0000-000000000000"
  resource_prefix       = "a${random_string.prefix.id}"
  resource_group_name   = "rg-${local.resource_prefix}"
  arc_onboard_uami_name = "uami-${local.resource_prefix}"
  arc_onboard_uami_id   = "${local.subscription_id_part}/resourceGroups/${local.resource_group_name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${local.arc_onboard_uami_name}"
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
    name = local.resource_group_name
  }
}

output "arc_onboarding_user_assigned_identity" {
  value = {
    id = local.arc_onboard_uami_id
  }
}
