output "snet_aks" {
  description = "The subnet created for Azure Kubernetes service."
  value = {
    id   = azurerm_subnet.snet_aks.id
    name = azurerm_subnet.snet_aks.name
  }
}

output "snet_aks_pod" {
  description = "The subnet created for Azure Kubernetes service pod vnet."
  value = {
    id   = azurerm_subnet.snet_aks_pod.id
    name = azurerm_subnet.snet_aks_pod.name
  }
}

output "snet_aks_node_pool" {
  description = "The subnets created for Azure Kubernetes service node pools."
  value = {
    for name, subnet in azurerm_subnet.snet_aks_node_pool : name => {
      id   = subnet.id
      name = subnet.name
    }
  }
}

output "snet_aks_node_pool_pod" {
  description = "The subnets created for Azure Kubernetes service node pool pods."
  value = {
    for name, subnet in azurerm_subnet.snet_aks_node_pool_pod : name => {
      id   = subnet.id
      name = subnet.name
    }
  }
}
