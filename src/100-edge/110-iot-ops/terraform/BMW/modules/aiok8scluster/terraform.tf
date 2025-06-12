##########################################
### Providers
##########################################

terraform {
  required_providers {
    rancher2 = {
      source  = "rancher/rancher2"
      version = "5.1.0"
    }

    http-full = {
      source  = "salrashid123/http-full"
      version = "1.2.8"
    }

    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 4.11.0"
    }

    azapi = {
      source = "azure/azapi"
      version = "2.3.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.3.0"
    }

    external = {
      source = "hashicorp/external"
      version = ">= 2.3.4"
    }

    http = {
      source = "hashicorp/http"
      version = ">= 3.2.0"
    }

    helm = {
      source = "hashicorp/helm"
      version = ">= 2.17.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  required_version = ">= 1.11.0"
}
