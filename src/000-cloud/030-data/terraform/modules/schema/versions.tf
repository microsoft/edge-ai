terraform {
  required_version = ">= 1.12.0, < 2.0"
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.0.1"
    }
  }
}
