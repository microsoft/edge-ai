mock_provider "azurerm" {}

# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Test 1: CI defaults, a Redis cache is created with the default SKU and no private endpoint
run "create_default_configuration" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    instance        = "001"
    location        = run.setup_tests.location
    resource_group  = run.setup_tests.resource_group
    virtual_network = run.setup_tests.virtual_network
  }

  assert {
    condition     = length(module.managed_redis) == 1
    error_message = "Managed Redis should be created when should_deploy_redis is true"
  }

  assert {
    condition     = module.managed_redis[0].managed_redis.name == "redis-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Managed Redis name does not match expected pattern"
  }

  assert {
    condition     = module.managed_redis[0].managed_redis.sku_name == "Balanced_B10"
    error_message = "Managed Redis should default to the Balanced_B10 SKU"
  }

  assert {
    condition     = module.managed_redis[0].managed_redis.resource_group_name == var.resource_group.name
    error_message = "Managed Redis should be created in the resource group"
  }

  assert {
    condition     = output.private_endpoint == null
    error_message = "Private endpoint should not be created when should_enable_private_endpoint is false"
  }
}

# Test 2: Redis deployment disabled, nothing is created and the outputs are null
run "create_without_redis" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    instance        = "001"
    location        = run.setup_tests.location
    resource_group  = run.setup_tests.resource_group

    should_deploy_redis = false
  }

  assert {
    condition     = length(module.managed_redis) == 0
    error_message = "Managed Redis should not be created when should_deploy_redis is false"
  }

  assert {
    condition     = output.managed_redis == null
    error_message = "managed_redis output should be null when should_deploy_redis is false"
  }

  assert {
    condition     = output.private_endpoint == null
    error_message = "private_endpoint output should be null when should_deploy_redis is false"
  }
}

# Test 3: Private endpoint with Entra ID identity and a non-default SKU
run "create_with_private_endpoint" {
  command = plan

  variables {
    resource_prefix         = run.setup_tests.resource_prefix
    environment             = "test"
    instance                = "002"
    location                = run.setup_tests.location
    resource_group          = run.setup_tests.resource_group
    virtual_network         = run.setup_tests.virtual_network
    private_endpoint_subnet = run.setup_tests.private_endpoint_subnet
    managed_identity        = run.setup_tests.managed_identity

    sku_name                        = "Balanced_B20"
    should_enable_high_availability = false
    should_enable_private_endpoint  = true
  }

  assert {
    condition     = module.managed_redis[0].managed_redis.sku_name == "Balanced_B20"
    error_message = "Managed Redis should use the provided SKU"
  }

  assert {
    condition     = module.managed_redis[0].private_endpoint != null
    error_message = "Private endpoint should be created when should_enable_private_endpoint is true"
  }

  assert {
    condition     = module.managed_redis[0].private_endpoint.name == "pe-redis-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Private endpoint name does not match expected pattern"
  }
}

# Test 4: Enabling the private endpoint without a subnet fails validation
run "create_private_endpoint_without_subnet" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    instance        = "003"
    location        = run.setup_tests.location
    resource_group  = run.setup_tests.resource_group
    virtual_network = run.setup_tests.virtual_network

    should_enable_private_endpoint = true
  }

  expect_failures = [
    var.private_endpoint_subnet,
  ]
}

# Test 5: An invalid SKU name fails validation
run "create_with_invalid_sku_name" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    instance        = "004"
    location        = run.setup_tests.location
    resource_group  = run.setup_tests.resource_group
    virtual_network = run.setup_tests.virtual_network

    sku_name = "Premium_P1"
  }

  expect_failures = [
    var.sku_name,
  ]
}

# Test 6: An invalid clustering policy fails validation
run "create_with_invalid_clustering_policy" {
  command = plan

  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "test"
    instance        = "005"
    location        = run.setup_tests.location
    resource_group  = run.setup_tests.resource_group
    virtual_network = run.setup_tests.virtual_network

    clustering_policy = "NoCluster"
  }

  expect_failures = [
    var.clustering_policy,
  ]
}
