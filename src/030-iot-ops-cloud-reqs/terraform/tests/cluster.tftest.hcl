# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "create_default_configuration" {

  command = plan
  variables {
    resource_prefix         = run.setup_tests.resource_prefix
    environment             = "dev"
    location                = "centralus"
    instance                = "test"
    resource_group_name     = null
    existing_key_vault_name = null
  }
}

run "create_non_default_configuration" {
  command = plan
  variables {
    resource_prefix         = run.setup_tests.resource_prefix
    environment             = "dev"
    location                = "centralus"
    instance                = "test"
    resource_group_name     = "test-rg"
    existing_key_vault_name = "test"
  }
}
