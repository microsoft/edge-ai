# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "test__add_current_entra_user_cluster_admin__error_with_invalid_environment" {

  command = plan
  variables {
    resource_prefix = run.setup_tests.resource_prefix
    location        = "centralus"

    # Variables under test
    environment                          = "prod"
    add_current_entra_user_cluster_admin = true
  }
  expect_failures = [var.add_current_entra_user_cluster_admin]
}

run "test__add_current_entra_user_cluster_admin__success_with_cluster_admin_off" {

  command = plan
  variables {
    resource_prefix = run.setup_tests.resource_prefix
    location        = "centralus"

    # Variables under test
    environment                          = "prod"
    add_current_entra_user_cluster_admin = false
  }
}

run "test__add_current_entra_user_cluster_admin__success_with_valid_env" {

  command = plan
  variables {
    resource_prefix = run.setup_tests.resource_prefix
    location        = "centralus"

    # Variables under test
    environment                          = "dev"
    add_current_entra_user_cluster_admin = true
  }
}

