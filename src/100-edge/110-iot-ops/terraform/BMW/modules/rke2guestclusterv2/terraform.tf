##########################################
### Providers
##########################################

terraform {
  required_providers {
    # https://github.com/rancher/terraform-provider-rancher2/blob/master/docs/compatibility-matrix.md
    rancher2 = {
      source  = "rancher/rancher2"
      version = "5.1.0"
    }

    http-full = {
      source  = "salrashid123/http-full"
      version = "1.2.8"
    }
  }

  required_version = ">= 1.2.9"
}
