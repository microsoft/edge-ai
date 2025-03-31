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
    arc_connected_cluster            = run.setup_tests.arc_connected_cluster
    aio_log_analytics_workspace      = run.setup_tests.aio_log_analytics_workspace
    aio_azure_monitor_workspace      = run.setup_tests.aio_azure_monitor_workspace
    aio_azure_managed_grafana        = run.setup_tests.aio_azure_managed_grafana
    aio_resource_group               = run.setup_tests.aio_resource_group
    aio_metrics_data_collection_rule = run.setup_tests.aio_metrics_data_collection_rule
    aio_logs_data_collection_rule    = run.setup_tests.aio_logs_data_collection_rule
  }
}

run "create_non_default_configuration" {

  command = plan

  variables {
    arc_connected_cluster            = run.setup_tests.arc_connected_cluster
    aio_log_analytics_workspace      = run.setup_tests.aio_log_analytics_workspace
    aio_azure_monitor_workspace      = run.setup_tests.aio_azure_monitor_workspace
    aio_azure_managed_grafana        = run.setup_tests.aio_azure_managed_grafana
    aio_resource_group               = run.setup_tests.aio_resource_group
    aio_metrics_data_collection_rule = run.setup_tests.aio_metrics_data_collection_rule
    aio_logs_data_collection_rule    = run.setup_tests.aio_logs_data_collection_rule
    # Periodically scrape the metrics from the cluster at 5 minute intervals
    scrape_interval                  = "PT5M"
  }
}
