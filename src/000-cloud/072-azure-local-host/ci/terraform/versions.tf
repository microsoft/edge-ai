terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.8.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.13.0"
    }
  }
  required_version = ">= 1.12.0, < 2.0"
}

provider "azurerm" {
  features {}
}
