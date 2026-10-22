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
  subscription_id_part       = "/subscriptions/00000000-0000-0000-0000-000000000000"
  resource_prefix            = "a${random_string.prefix.id}"
  resource_group_name        = "rg-${local.resource_prefix}"
  resource_group_id          = "${local.subscription_id_part}/resourceGroups/${local.resource_group_name}"
  arc_connected_cluster_name = "arck-${local.resource_prefix}"
  arc_connected_cluster_id   = "${local.resource_group_id}/providers/Microsoft.Kubernetes/connectedClusters/${local.arc_connected_cluster_name}"
  location                   = "eastus2"
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
}

output "arc_connected_cluster" {
  value = {
    id       = local.arc_connected_cluster_id
    name     = local.arc_connected_cluster_name
    location = local.location
  }
}
