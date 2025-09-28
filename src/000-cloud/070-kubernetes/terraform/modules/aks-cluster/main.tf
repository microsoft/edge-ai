/**
 * # Azure Kubernetes Service
 *
 * Deploys a Kubernetes cluster in Azure with a system-assigned managed identity.
 * Supports private clusters with optional private endpoints and DNS zone management.
 */
locals {
  dns_prefix = coalesce(var.dns_prefix, "dns-${var.resource_prefix}-${var.environment}-${var.instance}")

  should_use_user_assigned_identity = try(coalesce(var.aks_identity.id), null) != null
  kubelet_identity_principal_id     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.resource_prefix}-${var.environment}-${var.instance}"
  location            = var.location
  resource_group_name = var.resource_group.name
  dns_prefix          = local.dns_prefix

  private_cluster_enabled             = var.should_enable_private_endpoint || var.should_enable_private_cluster
  private_cluster_public_fqdn_enabled = var.should_enable_private_cluster_public_fqdn
  private_dns_zone_id                 = var.should_enable_private_endpoint || var.should_enable_private_cluster ? coalesce(var.private_dns_zone_id, try(azurerm_private_dns_zone.aks_private_dns_zone[0].id, null)) : null

  oidc_issuer_enabled       = var.should_enable_oidc_issuer || var.should_enable_workload_identity
  workload_identity_enabled = var.should_enable_workload_identity

  dynamic "microsoft_defender" {
    for_each = try(var.log_analytics_workspace.id, null) != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace.id
    }
  }

  dynamic "oms_agent" {
    for_each = try(var.log_analytics_workspace.id, null) != null ? [1] : []
    content {
      log_analytics_workspace_id      = var.log_analytics_workspace.id
      msi_auth_for_monitoring_enabled = true
    }
  }

  dynamic "monitor_metrics" {
    for_each = var.should_enable_azure_monitor_metrics ? [1] : []
    content {
      annotations_allowed = var.azure_monitor_annotations_allowed
      labels_allowed      = var.azure_monitor_labels_allowed
    }
  }

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
    name                 = "default"
    node_count           = var.enable_auto_scaling ? null : var.node_count
    vm_size              = var.node_vm_size
    vnet_subnet_id       = var.snet_aks.id
    pod_subnet_id        = var.snet_aks_pod.id
    auto_scaling_enabled = var.enable_auto_scaling
    min_count            = var.enable_auto_scaling ? var.min_count : null
    max_count            = var.enable_auto_scaling ? var.max_count : null
    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  dynamic "identity" {
    for_each = local.should_use_user_assigned_identity ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.aks_identity.id]
    }
  }

  dynamic "identity" {
    for_each = local.should_use_user_assigned_identity ? [] : [1]
    content {
      type = "SystemAssigned"
    }
  }
}

/*
 * Azure Monitor Data Collection Rule Association
 */

resource "azurerm_monitor_data_collection_rule_association" "aks_metrics" {
  count = var.should_enable_azure_monitor_metrics && var.metrics_data_collection_rule != null ? 1 : 0

  name                    = "dcra-aks-metrics-${var.resource_prefix}-${var.environment}-${var.instance}"
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = var.metrics_data_collection_rule.id
  description             = "Associates AKS cluster with metrics data collection rule for custom Azure Monitor workspace"
}

/*
 * Role Assignments and Network Resources
 */

resource "azurerm_role_assignment" "acr_pull" {
  scope                            = var.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = local.kubelet_identity_principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "cluster_admin" {
  count = var.should_assign_cluster_admin ? 1 : 0

  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = var.cluster_admin_oid
}

resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  node_count            = each.value.node_count
  vm_size               = each.value.vm_size
  vnet_subnet_id        = each.value.vnet_subnet_id
  pod_subnet_id         = each.value.pod_subnet_id
  node_taints           = each.value.node_taints
  auto_scaling_enabled  = each.value.enable_auto_scaling
  min_count             = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count             = each.value.enable_auto_scaling ? each.value.max_count : null
  priority              = each.value.priority
  zones                 = each.value.zones
  eviction_policy       = each.value.eviction_policy
  gpu_driver            = each.value.gpu_driver
}

/*
 * Private Endpoint for AKS Cluster
 */

resource "azurerm_private_endpoint" "aks_pe" {
  count = var.should_enable_private_endpoint ? 1 : 0

  name                = "pe-${azurerm_kubernetes_cluster.aks.name}"
  location            = var.location
  resource_group_name = var.resource_group.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "aks-privatelink"
    private_connection_resource_id = azurerm_kubernetes_cluster.aks.id
    is_manual_connection           = false
    subresource_names              = ["management"]
  }
}

resource "azurerm_role_assignment" "dns_zone_contributor" {
  count = var.should_enable_private_endpoint ? 1 : 0

  scope                = coalesce(var.private_dns_zone_id, azurerm_private_dns_zone.aks_private_dns_zone[0].id)
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = var.aks_identity.principal_id
}

resource "azurerm_private_dns_zone" "aks_private_dns_zone" {
  count = var.should_enable_private_endpoint && var.private_dns_zone_id == null ? 1 : 0

  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = var.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks_vnet_link" {
  count = var.should_enable_private_endpoint && var.private_dns_zone_id == null ? 1 : 0

  name                  = "vnet-pzl-aks-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name   = var.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.aks_private_dns_zone[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "aks_a_record" {
  count = var.should_enable_private_endpoint && var.private_dns_zone_id == null ? 1 : 0

  name                = azurerm_kubernetes_cluster.aks.name
  zone_name           = azurerm_private_dns_zone.aks_private_dns_zone[0].name
  resource_group_name = var.resource_group.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.aks_pe[0].private_service_connection[0].private_ip_address]
}
