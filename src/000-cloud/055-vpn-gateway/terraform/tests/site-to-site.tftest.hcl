mock_provider "azurerm" {}

mock_provider "tls" {}

# Call the setup module to create fabricated resource group/virtual network identifiers
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Site names are used in the local network gateway and connection names, so any character
# Azure does not allow in a resource name must be replaced. Underscores and periods are valid
# in Azure resource names and are kept, so names of existing sites stay the same.
run "site_names_are_sanitized_in_resource_names" {
  command = plan

  variables {
    resource_prefix    = run.setup_tests.resource_prefix
    environment        = run.setup_tests.environment
    location           = run.setup_tests.location
    instance           = run.setup_tests.instance
    aio_resource_group = run.setup_tests.resource_group
    virtual_network    = run.setup_tests.virtual_network

    vpn_site_connections = [
      {
        name                 = "onprem-site"
        address_spaces       = ["192.168.0.0/24"]
        shared_key_reference = "shared"
        gateway_ip_address   = "203.0.113.1"
      },
      {
        name                 = "Seattle HQ"
        address_spaces       = ["192.168.1.0/24"]
        shared_key_reference = "shared"
        gateway_ip_address   = "203.0.113.2"
      },
      {
        name                 = "Plant #3 (Main)"
        address_spaces       = ["192.168.2.0/24"]
        shared_key_reference = "shared"
        gateway_ip_address   = "203.0.113.3"
      },
      {
        name                 = "Branch_Office.EU"
        address_spaces       = ["192.168.3.0/24"]
        shared_key_reference = "shared"
        gateway_ip_address   = "203.0.113.4"
      },
      {
        name                 = "abcdefghijklmnopqrstuvwxyz123 tail"
        address_spaces       = ["192.168.4.0/24"]
        shared_key_reference = "shared"
        gateway_ip_address   = "203.0.113.5"
      }
    ]
    vpn_site_shared_keys = {
      "shared" = "not-a-real-shared-key"
    }
  }

  assert {
    condition     = module.site_to_site[0].local_network_gateways["onprem-site"].name == "lng-${var.resource_prefix}-onprem-site-${var.environment}-${var.instance}"
    error_message = "Site names that are already valid must be used unchanged in the local network gateway name"
  }

  assert {
    condition     = module.site_to_site[0].site_connections["onprem-site"].name == "conn-onprem-site-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Site names that are already valid must be used unchanged in the connection name"
  }

  assert {
    condition     = module.site_to_site[0].local_network_gateways["Seattle HQ"].name == "lng-${var.resource_prefix}-seattle-hq-${var.environment}-${var.instance}"
    error_message = "Spaces and upper-case letters in site names must be sanitized in the local network gateway name"
  }

  assert {
    condition     = module.site_to_site[0].site_connections["Seattle HQ"].name == "conn-seattle-hq-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Spaces and upper-case letters in site names must be sanitized in the connection name"
  }

  assert {
    condition     = module.site_to_site[0].local_network_gateways["Plant #3 (Main)"].name == "lng-${var.resource_prefix}-plant-3-main-${var.environment}-${var.instance}"
    error_message = "Runs of invalid characters must collapse to a single hyphen and trailing hyphens must be trimmed"
  }

  assert {
    condition     = module.site_to_site[0].local_network_gateways["Branch_Office.EU"].name == "lng-${var.resource_prefix}-branch_office.eu-${var.environment}-${var.instance}"
    error_message = "Underscores and periods are valid in Azure resource names and must be kept"
  }

  assert {
    condition     = module.site_to_site[0].local_network_gateways["abcdefghijklmnopqrstuvwxyz123 tail"].name == "lng-${var.resource_prefix}-abcdefghijklmnopqrstuvwxyz123-${var.environment}-${var.instance}"
    error_message = "Site name slugs must be truncated to 30 characters without a trailing hyphen"
  }
}
