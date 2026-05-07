terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.3.0"
    }
  }

  required_version = ">= 1.12.0, < 2.0"
}
