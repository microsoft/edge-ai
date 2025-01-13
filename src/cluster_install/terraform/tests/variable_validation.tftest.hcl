# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "test_trust_config_error_with_invalid_source" {

  command = plan
  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "dev"
    location        = "centralus"

    # Variables under test
    trust_config = {
      source = "InvalidSource"
    }
  }
  expect_failures = [var.trust_config, ]
}

run "test_customer_managed_trust_config_error_with_no_cluster_admin" {

  command = plan
  variables {
    resource_prefix = run.setup_tests.resource_prefix
    location        = "centralus"

    # Variables under test
    add_current_entra_user_cluster_admin = false
    environment                          = "dev"
    trust_config = {
      source = "CustomerManaged"
    }
  }
  expect_failures = [var.trust_config]
}

run "test_customer_managed_trust_config_error_with_invalid_environment" {

  command = plan
  variables {
    resource_prefix = run.setup_tests.resource_prefix
    location        = "centralus"

    # Variables under test
    add_current_entra_user_cluster_admin = true
    environment                          = "prod"
    trust_config = {
      source = "CustomerManaged"
    }
  }
  expect_failures = [var.trust_config]
}
