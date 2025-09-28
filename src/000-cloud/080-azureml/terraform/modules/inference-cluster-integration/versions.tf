terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.8.0"
    }
  }
  required_version = ">= 1.9.8, < 2.0"
}
