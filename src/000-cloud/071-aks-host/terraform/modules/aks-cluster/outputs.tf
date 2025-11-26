output "aks" {
  description = "The Azure Kubernetes Service resource created by this module."
  value = {
    id                  = azurerm_kubernetes_cluster.aks.id
    name                = azurerm_kubernetes_cluster.aks.name
    resource_group_name = azurerm_kubernetes_cluster.aks.resource_group_name
    default_node_pool   = azurerm_kubernetes_cluster.aks.default_node_pool
    dns_prefix          = azurerm_kubernetes_cluster.aks.dns_prefix
    fqdn                = azurerm_kubernetes_cluster.aks.fqdn
    private_fqdn        = azurerm_kubernetes_cluster.aks.private_fqdn
    oidc_issuer_url     = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  }
}

output "aks_identity" {
  description = "The Azure Kubernetes Service identity."
  value = {
    principal_id = local.should_use_user_assigned_identity ? var.aks_identity.principal_id : azurerm_kubernetes_cluster.aks.identity[0].principal_id
  }
}

output "aks_kube_config" {
  description = "The Azure Kubernetes Service .kube config."
  value       = azurerm_kubernetes_cluster.aks.kube_config
  sensitive   = true
}

output "node_pools" {
  description = "The additional node pools created for the AKS cluster."
  value = {
    for k, v in azurerm_kubernetes_cluster_node_pool.additional : k => {
      id             = v.id
      name           = v.name
      node_count     = v.node_count
      vm_size        = v.vm_size
      vnet_subnet_id = v.vnet_subnet_id
      pod_subnet_id  = v.pod_subnet_id
    }
  }
}

output "private_endpoint" {
  description = "The private endpoint resource for AKS cluster."
  value = var.should_enable_private_endpoint ? {
    id                   = azurerm_private_endpoint.aks_pe[0].id
    name                 = azurerm_private_endpoint.aks_pe[0].name
    private_ip_address   = azurerm_private_endpoint.aks_pe[0].private_service_connection[0].private_ip_address
    network_interface_id = azurerm_private_endpoint.aks_pe[0].network_interface[0].id
    custom_dns_configs   = azurerm_private_endpoint.aks_pe[0].custom_dns_configs
  } : null
}

output "private_dns_zone" {
  description = "The private DNS zone for AKS cluster."
  value = var.should_enable_private_cluster && var.private_dns_zone_id == null ? {
    id   = azurerm_private_dns_zone.aks_private_dns_zone[0].id
    name = azurerm_private_dns_zone.aks_private_dns_zone[0].name
  } : null
}
