terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.3.0, < 6.0.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.3.0"
    }
  }
  required_version = ">= 1.12.0, < 2.0"
}

provider "azurerm" {
  resource_provider_registrations = "none"
  features {
    enhanced_validation {
      locations          = true
      resource_providers = true
    }
  }
}
