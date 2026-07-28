provider "azurerm" {
  features {}
}

# Call the setup module to create fabricated resource group/virtual network identifiers
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Default configuration uses Azure AD (Entra ID) authentication and creates no certificates,
# so it does not require a real Key Vault to exist for the plan to succeed.
run "create_default_configuration" {
  command = plan

  variables {
    resource_prefix    = run.setup_tests.resource_prefix
    environment        = run.setup_tests.environment
    location           = run.setup_tests.location
    instance           = run.setup_tests.instance
    aio_resource_group = run.setup_tests.resource_group
    virtual_network    = run.setup_tests.virtual_network
  }

  assert {
    condition     = module.vpn_gateway.gateway_subnet.name == "GatewaySubnet"
    error_message = "VPN Gateway subnet must use the fixed 'GatewaySubnet' name required by Azure"
  }

  assert {
    condition     = output.vpn_gateway.name == "vng-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "VPN Gateway name does not match expected pattern"
  }

  assert {
    condition     = length(module.certificate_management) == 0
    error_message = "Certificate management module should not be created when should_use_azure_ad_auth is true"
  }

  assert {
    condition     = length(module.site_to_site) == 0
    error_message = "Site-to-site module should not be created when vpn_site_connections is empty"
  }
}

# Site-to-site connections layer onto the same Azure AD authenticated gateway without
# requiring certificate management, so this stays within the plan-only, no-Key-Vault path.
run "create_with_site_to_site" {
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
        shared_key_reference = "onprem-site-key"
        gateway_ip_address   = "203.0.113.1"
      }
    ]
    vpn_site_default_ipsec_policy = {
      dh_group         = "DHGroup14"
      ike_encryption   = "AES256"
      ike_integrity    = "SHA256"
      ipsec_encryption = "AES256"
      ipsec_integrity  = "SHA256"
      pfs_group        = "PFS14"
    }
    vpn_site_shared_keys = {
      "onprem-site-key" = "not-a-real-shared-key"
    }
  }

  assert {
    condition     = length(module.site_to_site) == 1
    error_message = "Site-to-site module should be created when vpn_site_connections is non-empty"
  }
}
