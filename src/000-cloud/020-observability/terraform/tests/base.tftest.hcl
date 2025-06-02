mock_provider "azurerm" {}

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
    app_insights_retention_in_days       = 60
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

  assert {
    condition     = module.application_insights.application_insights.name == "appi-${var.resource_prefix}-${var.environment}-001"
    error_message = "Application Insights name does not match expected pattern"
  }

  assert {
    condition     = module.application_insights.application_insights.application_type == "web"
    error_message = "Application Insights application type does not match expected value"
  }

  assert {
    condition     = module.application_insights.application_insights.retention_in_days == 60
    error_message = "Application Insights retention in days does not match expected value"
  }
}

run "create_application_insights_with_custom_type" {
  command = plan

  variables {
    resource_prefix                = run.setup_tests.resource_prefix
    environment                    = "dev"
    instance                       = "001"
    location                       = run.setup_tests.location
    azmon_resource_group           = run.setup_tests.azmon_resource_group
    app_insights_application_type  = "other"
    app_insights_retention_in_days = 30
  }

  assert {
    condition     = module.application_insights.application_insights.application_type == "other"
    error_message = "Application Insights application type does not match custom value"
  }

  assert {
    condition     = module.application_insights.application_insights.retention_in_days == 30
    error_message = "Application Insights retention in days does not match custom value"
  }

  assert {
    condition     = can(regex("^appi-.*-dev-001$", module.application_insights.application_insights.name))
    error_message = "Application Insights name does not follow expected naming convention"
  }
}

run "validate_application_insights_outputs" {
  command = plan

  variables {
    resource_prefix      = run.setup_tests.resource_prefix
    environment          = "dev"
    instance             = "001"
    location             = run.setup_tests.location
    azmon_resource_group = run.setup_tests.azmon_resource_group
  }

  assert {
    condition     = output.application_insights != null
    error_message = "Application Insights output should not be null"
  }

  assert {
    condition     = contains(keys(output.application_insights), "connection_string")
    error_message = "Application Insights output should contain connection_string field"
  }

  assert {
    condition     = contains(keys(output.application_insights), "instrumentation_key")
    error_message = "Application Insights output should contain instrumentation_key field"
  }

  assert {
    condition     = contains(keys(output.application_insights), "app_id")
    error_message = "Application Insights output should contain app_id field"
  }

  assert {
    condition     = output.application_insights.location == var.location
    error_message = "Application Insights location should match the specified location"
  }

  assert {
    condition     = output.application_insights.resource_group_name == var.azmon_resource_group.name
    error_message = "Application Insights resource group should match the specified resource group"
  }
}
