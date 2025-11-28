/**
 * # Provider Versions for Kubernetes Assets
 *
 * This file defines the required Terraform and provider versions.
 */

terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.51.0"
    }
  }
  required_version = ">= 1.9.8, < 2.0"
}
