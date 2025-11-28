terraform {
  required_version = ">= 1.9.8, < 2.0"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}
