terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.8.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.3.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = ">= 2.17.0"
    }
  }
  required_version = ">= 1.9.8, < 2.0"
}
