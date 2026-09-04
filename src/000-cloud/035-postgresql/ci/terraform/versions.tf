terraform {
  required_version = ">= 1.12.0, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.3.0, < 6.0.0"
    }
  }
}

provider "azurerm" {
  resource_provider_registrations = "none"
  storage_use_azuread             = true
  features {
    enhanced_validation {
      locations          = true
      resource_providers = true
    }
  }
}
