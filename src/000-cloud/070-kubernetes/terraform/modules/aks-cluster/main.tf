/**
 * # Azure Kubernetes Service
 *
 * Deploys a Kubernetes cluster in Azure with a system-assigned managed identity.
 *
 */
locals {
  dns_prefix = coalesce(var.dns_prefix, "dns-${var.resource_prefix}-${var.environment}-${var.instance}")
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.resource_prefix}-${var.environment}-${var.instance}"
  location            = var.location
  resource_group_name = var.resource_group.name
  dns_prefix          = local.dns_prefix

  network_profile {
    // due to the dependency between network_plugin and network_policy, we need to set both
    // to the same value "azure" https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#network_policy-1
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }

  default_node_pool {
    name           = "default"
    node_count     = var.node_count
    vm_size        = var.node_vm_size
    vnet_subnet_id = var.snet_aks.id
    pod_subnet_id  = var.snet_aks_pod.id
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                            = var.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}
