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
    location        = "centralus"

    # Variables under test
    trust_config = {
      source = "InvalidSource"
    }
  }
  expect_failures = [var.trust_config]
}
