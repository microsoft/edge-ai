terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "0.1.0-rc.2"
    }
  }
  required_version = ">= 1.9.8, < 2.0.0"
}
