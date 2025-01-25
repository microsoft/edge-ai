terraform {
  required_version = ">= 1.9.8, < 2.0"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "2.1.0"
    }
  }
}
