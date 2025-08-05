terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.23.0" # Updated to ensure support for azurerm_fabric_capacity
    }
    fabric = {
      source  = "microsoft/fabric"
      version = "1.3.0"
    }
  }
  required_version = ">= 1.9.8, < 2.0.0"
}
