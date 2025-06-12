##########################################
### Providers
##########################################

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 4.11.0"
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
  }

  required_version = ">= 1.11.0"
}
