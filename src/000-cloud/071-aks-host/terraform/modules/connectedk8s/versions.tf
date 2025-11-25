terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.5"
    }
  }
  required_version = ">= 1.9.8, < 2.0"
}
