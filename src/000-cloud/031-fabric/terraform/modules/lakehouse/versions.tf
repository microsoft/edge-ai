terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "1.10.0"
    }
  }
  required_version = ">= 1.12.0, < 2.0"
}
