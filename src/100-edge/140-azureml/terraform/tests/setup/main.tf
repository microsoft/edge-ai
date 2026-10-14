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
  subscription_id_part = "/subscriptions/00000000-0000-0000-0000-000000000000"
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

output "resource_group" {
  value = {
    name = local.resource_group_name
    id   = local.resource_group_id
  }
}

output "connected_cluster" {
  value = {
    name = "arck-${local.resource_prefix}"
    id   = "${local.resource_group_id}/providers/Microsoft.Kubernetes/connectedClusters/arck-${local.resource_prefix}"
  }
}

output "machine_learning_workspace" {
  value = {
    name     = "mlw-${local.resource_prefix}"
    id       = "${local.resource_group_id}/providers/Microsoft.MachineLearningServices/workspaces/mlw-${local.resource_prefix}"
    location = local.location
  }
}

output "ml_workload_identity" {
  value = {
    id           = "${local.resource_group_id}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-${local.resource_prefix}-ml"
    principal_id = "22222222-2222-2222-2222-222222222222"
  }
}

output "workspace_identity_principal_id" {
  value = "33333333-3333-3333-3333-333333333333"
}
