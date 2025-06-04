/**
 * # Provider Versions for K8 Bridge Role Assignment Module
 *
 * This file defines the required Terraform and provider versions.
 */

terraform {
  required_version = ">= 1.9.8, < 2.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.8.0"
    }
  }
}
