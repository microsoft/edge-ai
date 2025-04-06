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
    location             = run.setup_tests.location
    azmon_resource_group = run.setup_tests.azmon_resource_group
  }

  assert {
    condition     = azurerm_monitor_workspace.monitor.name == "azmon-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Azure Monitor Workspace name does not match expected pattern"
  }
}

run "create_non_default_configuration" {
  command = plan

  variables {
    resource_prefix                      = run.setup_tests.resource_prefix
    environment                          = "dev"
    instance                             = "001"
    location                             = run.setup_tests.location
    azmon_resource_group                 = run.setup_tests.azmon_resource_group
    grafana_admin_principal_id           = "test_principal_id"
    grafana_major_version                = "10"
    log_retention_in_days                = 45
    daily_quota_in_gb                    = 15
    logs_data_collection_rule_namespaces = ["kube-system", "gatekeeper-system"]
    logs_data_collection_rule_streams    = ["Microsoft-ContainerLog", "Microsoft-ContainerLogV2"]
  }

  assert {
    condition     = azurerm_log_analytics_workspace.monitor.retention_in_days == 45
    error_message = "Log Analytics Workspace retention in days does not match expected value"
  }

  assert {
    condition     = azurerm_log_analytics_workspace.monitor.daily_quota_gb == 15
    error_message = "Log Analytics Workspace daily quota does not match expected value"
  }

  assert {
    condition     = azurerm_dashboard_grafana.monitor.grafana_major_version == "10"
    error_message = "Grafana major version does not match expected value"
  }
}
