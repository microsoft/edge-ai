terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0.0"
    }
  }
  required_version = ">= 1.9.8, < 2.0"
}
