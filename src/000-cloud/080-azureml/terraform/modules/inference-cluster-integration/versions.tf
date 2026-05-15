terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.51.0"
    }
  }
  required_version = ">= 1.12.0, < 2.0"
}
