output "cluster" {
  value = module.aio_cluster
}

locals {
  kube_config = yamldecode(rancher2_cluster_sync.arc_sync.kube_config)
}

output "kube_config" {
  value = {
    content = rancher2_cluster_sync.arc_sync.kube_config
    token = local.kube_config["users"][0]["user"]["token"]
    host = local.kube_config["clusters"][0]["cluster"]["server"]
  }
}

output "arc_k8s_cluster" {
  value = module.connectedk8s.cluster
}

output "azure_resource_group" {
  value = azurerm_resource_group.aio
}

output "schema_registry" {
  value = module.schema_registry.schema_registry
}