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
    resource_group                   = run.setup_tests.resource_group
    arc_connected_cluster            = run.setup_tests.arc_connected_cluster
    aio_log_analytics_workspace      = run.setup_tests.aio_log_analytics_workspace
    aio_azure_monitor_workspace      = run.setup_tests.aio_azure_monitor_workspace
    aio_azure_managed_grafana        = run.setup_tests.aio_azure_managed_grafana
    aio_metrics_data_collection_rule = run.setup_tests.aio_metrics_data_collection_rule
    aio_logs_data_collection_rule    = run.setup_tests.aio_logs_data_collection_rule
  }

  assert {
    condition     = module.rule_associations_obs.metrics_data_collection_rule_association.name != null
    error_message = "Metrics data collection rule association should be created"
  }

  assert {
    condition     = module.rule_associations_obs.logs_data_collection_rule_association.name != null
    error_message = "Logs data collection rule association should be created"
  }

  assert {
    condition     = module.cluster_extensions_obs.container_metrics.name != null
    error_message = "Metrics extension should be created"
  }

  assert {
    condition     = module.cluster_extensions_obs.container_logs.name != null
    error_message = "Logs extension should be created"
  }
}

run "create_non_default_configuration" {
  command = plan

  variables {
    resource_group                   = run.setup_tests.resource_group
    arc_connected_cluster            = run.setup_tests.arc_connected_cluster
    aio_log_analytics_workspace      = run.setup_tests.aio_log_analytics_workspace
    aio_azure_monitor_workspace      = run.setup_tests.aio_azure_monitor_workspace
    aio_azure_managed_grafana        = run.setup_tests.aio_azure_managed_grafana
    aio_metrics_data_collection_rule = run.setup_tests.aio_metrics_data_collection_rule
    aio_logs_data_collection_rule    = run.setup_tests.aio_logs_data_collection_rule
    scrape_interval                  = "PT5M"
  }


  assert {
    condition     = module.rule_associations_obs.metrics_data_collection_rule_association.name != null
    error_message = "Metrics data collection rule association should be created"
  }

  assert {
    condition     = module.rule_associations_obs.logs_data_collection_rule_association.name != null
    error_message = "Logs data collection rule association should be created"
  }

  assert {
    condition     = module.cluster_extensions_obs.container_metrics.name != null
    error_message = "Metrics extension should be created"
  }

  assert {
    condition     = module.cluster_extensions_obs.container_logs.name != null
    error_message = "Logs extension should be created"
  }
}
