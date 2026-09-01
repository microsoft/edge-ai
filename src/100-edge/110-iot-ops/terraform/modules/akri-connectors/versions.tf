terraform {
  required_version = ">= 1.12.0, < 2.0"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.3.0, < 6.0.0"
    }
  }
}
