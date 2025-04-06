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
  description = "Environment name"
  type        = string
  default     = "test"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "cdp"
}

variable "component" {
  description = "Component name"
  type        = string
  default     = "storage"
}

locals {
  resource_group_name = "rg-${var.environment}-${var.prefix}-${var.component}"
  resource_group_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${local.resource_group_name}"
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
}

output "resource_prefix" {
  value = "a${random_string.prefix.id}"
}

output "resource_group" {
  value = {
    name = local.resource_group_name
    id   = local.resource_group_id
  }
}

output "location" {
  value = "eastus2"
}

output "environment" {
  value = var.environment
}

output "instance" {
  value = "001"
}
