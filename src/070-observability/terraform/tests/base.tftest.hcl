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
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = "dev"
    instance             = "001"
    azmon_resource_group = run.setup_tests.azmon_resource_group
  }
}

run "create_non_default_configuration" {

  command = plan

  variables {
    resource_prefix            = run.setup_tests.resource_prefix
    environment                = "dev"
    instance                   = "001"
    azmon_resource_group       = run.setup_tests.azmon_resource_group
    grafana_admin_principal_id = "test_principal_id"
    grafana_major_version      = "10"
    log_retention_in_days      = 45
    daily_quota_in_gb          = 15
  }
}
