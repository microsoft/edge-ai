terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.8.0"
    }
    msgraph = {
      source  = "microsoft/msgraph"
      version = ">= 0.2.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
  }
  required_version = ">= 1.9.8, < 2.0"
}
