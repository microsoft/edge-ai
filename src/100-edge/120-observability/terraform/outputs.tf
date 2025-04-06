output "cluster_extensions" {
  description = "The cluster extensions for observability."
  value = {
    container_metrics = module.cluster_extensions_obs.container_metrics
    container_logs    = module.cluster_extensions_obs.container_logs
  }
}

output "rule_associations" {
  description = "The data collection rule associations for observability."
  value = {
    metrics_association = module.rule_associations_obs.metrics_data_collection_rule_association
    logs_association    = module.rule_associations_obs.logs_data_collection_rule_association
  }
}
