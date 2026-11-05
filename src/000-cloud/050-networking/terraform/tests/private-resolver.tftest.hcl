mock_provider "azurerm" {}

# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# The private resolver is used for VPN client DNS resolution and does not depend on the
# NAT gateway, so it must plan when managed outbound access is disabled.
run "create_private_resolver_without_nat_gateway" {
  command = plan

  variables {
    resource_prefix                = run.setup_tests.resource_prefix
    environment                    = "test"
    instance                       = "001"
    location                       = run.setup_tests.location
    resource_group                 = run.setup_tests.resource_group
    should_enable_private_resolver = true
    should_enable_nat_gateway      = false
  }

  assert {
    condition     = length(module.private_resolver) == 1
    error_message = "Private resolver module should be created when should_enable_private_resolver is true"
  }

  assert {
    condition     = module.private_resolver[0].resolver_subnet.name == "snet-resolver-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Private resolver subnet name does not match expected pattern"
  }

  assert {
    condition     = length(module.nat_gateway) == 0
    error_message = "NAT gateway module should not be created when should_enable_nat_gateway is false"
  }

  assert {
    condition     = length(azurerm_subnet_nat_gateway_association.main) == 0
    error_message = "Subnet should not be associated with a NAT gateway when should_enable_nat_gateway is false"
  }
}

# With managed outbound access enabled, the resolver subnet is also associated with the NAT gateway.
run "create_private_resolver_with_nat_gateway" {
  command = plan

  variables {
    resource_prefix                = run.setup_tests.resource_prefix
    environment                    = "test"
    instance                       = "001"
    location                       = run.setup_tests.location
    resource_group                 = run.setup_tests.resource_group
    should_enable_private_resolver = true
    should_enable_nat_gateway      = true
  }

  assert {
    condition     = length(module.private_resolver) == 1
    error_message = "Private resolver module should be created when should_enable_private_resolver is true"
  }

  assert {
    condition     = length(module.nat_gateway) == 1
    error_message = "NAT gateway module should be created when should_enable_nat_gateway is true"
  }
}
