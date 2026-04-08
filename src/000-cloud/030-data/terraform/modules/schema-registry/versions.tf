terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
  required_version = ">= 1.9.8, < 2.0"
}
