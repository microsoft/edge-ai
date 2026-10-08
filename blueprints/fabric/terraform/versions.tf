terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.3.0, < 6.0.0"
    }
    fabric = {
      source  = "microsoft/fabric"
      version = "1.10.0"
    }
    msgraph = {
      source  = "microsoft/msgraph"
      version = ">= 0.2.0"
    }
  }
  required_version = ">= 1.12.0, < 2.0"
}

provider "azurerm" {
  resource_provider_registrations = "none"
  storage_use_azuread             = true
  partner_id                      = "acce1e78-0375-4637-a593-86aa36dcfeac"
  features {
    enhanced_validation {
      locations          = true
      resource_providers = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "fabric" {
  # Enable preview features required for pre-release
  preview = true
}
