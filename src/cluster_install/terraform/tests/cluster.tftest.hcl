# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Apply run block to create the cluster
run "create_default_cluster" {
  variables {
    resource_prefix  = run.setup_tests.resource_prefix
    environment      = "dev"
    location         = "centralus"
    arc_sp_client_id = "test_sp_client_id"
    arc_sp_secret    = "test_sp_secret"
  }

  # Check that a SP is not created when providing the SP credentials
  assert {
    condition     = length(module.arc_service_principal) == 0
    error_message = "SP should not have been created"
  }
}
