terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.8.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.0.2"
    }
  }
  required_version = ">= 1.9.8"
}

resource "random_pet" "prefix" {
  length = 4
}

output "resource_prefix" {
  value = random_pet.prefix.id
}
