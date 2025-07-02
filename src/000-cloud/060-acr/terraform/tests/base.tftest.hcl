provider "azurerm" {
  storage_use_azuread = true
  features {}
}

# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "create_default_configuration" {
  command = plan

  variables {
    resource_prefix        = run.setup_tests.resource_prefix
    environment            = run.setup_tests.environment
    location               = run.setup_tests.location
    instance               = run.setup_tests.instance
    resource_group         = run.setup_tests.resource_group
    network_security_group = run.setup_tests.network_security_group
    virtual_network        = run.setup_tests.virtual_network
  }

  assert {
    condition     = module.network.snet_acr == null
    error_message = "Subnet for ACR should be null when private endpoint is not created"
  }

  assert {
    condition     = module.container_registry.acr.name == "acr${var.resource_prefix}${var.environment}${var.instance}"
    error_message = "Azure Container Registry name does not match expected pattern"
  }
}

run "create_non_default_configuration" {
  command = plan

  variables {
    resource_prefix                    = run.setup_tests.resource_prefix
    environment                        = run.setup_tests.environment
    location                           = run.setup_tests.location
    instance                           = run.setup_tests.instance
    resource_group                     = run.setup_tests.resource_group
    network_security_group             = run.setup_tests.network_security_group
    virtual_network                    = run.setup_tests.virtual_network
    should_create_acr_private_endpoint = true
    sku                                = "Basic"
  }

  assert {
    condition     = module.container_registry.acr.sku == "Basic"
    error_message = "Azure Container Registry SKU does not match expected value"
  }
}
