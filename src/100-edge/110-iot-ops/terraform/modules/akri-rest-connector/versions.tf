terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.7"
    }
  }
}
