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
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
}

output "resource_prefix" {
  value = "a${random_string.prefix.id}"
}

output "resource_group_name" {
  value = local.resource_group_name
}

output "location" {
  value = "eastus2"
}

output "environment" {
  value = "test"
}

output "instance" {
  value = "001"
}