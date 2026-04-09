terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.51.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.0"
    }
    msgraph = {
      source  = "microsoft/msgraph"
      version = ">= 0.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }
  required_version = ">= 1.9.8, < 2.0"
}
