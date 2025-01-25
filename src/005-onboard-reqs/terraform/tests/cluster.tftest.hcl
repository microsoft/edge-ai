# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Apply run block to create the cluster
run "create_default_cluster" {

  command = plan
  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "dev"
    location        = "centralus"
  }

}

run "create_non_default_cluster" {
  command = plan
  variables {
    resource_prefix                      = run.setup_tests.resource_prefix
    environment                          = "dev"
    instance                             = "002"
    location                             = "centralus"
    should_create_onboard_identity       = false
    onboard_identity_type                = "sp"
  }
}
