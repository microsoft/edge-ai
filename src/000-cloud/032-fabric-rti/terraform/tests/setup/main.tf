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
  resource_prefix = "a${random_string.prefix.id}"
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
}

resource "random_uuid" "workspace_id" {
}

resource "random_uuid" "eventhouse_database_id" {
}

resource "random_uuid" "lakehouse_id" {
}

output "resource_prefix" {
  value = local.resource_prefix
}

output "fabric_workspace" {
  value = {
    id           = random_uuid.workspace_id.result
    display_name = "ws-${local.resource_prefix}"
  }
}

output "eventhouse_database_id" {
  value = random_uuid.eventhouse_database_id.result
}

output "lakehouse_id" {
  value = random_uuid.lakehouse_id.result
}
