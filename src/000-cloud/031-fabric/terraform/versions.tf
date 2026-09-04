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
  }
  required_version = ">= 1.12.0, < 2.0"
}
