terraform {
  required_version = ">= 1.9.8, < 2.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.51.0"
    }
  }
}
