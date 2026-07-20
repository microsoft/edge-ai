terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.51.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.13.0"
    }
  }
  required_version = ">= 1.12.0, < 2.0"
}
