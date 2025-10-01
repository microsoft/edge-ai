/**
 * # Azure Kubernetes Service (AKS)
 *
 * Deploys Azure Kubernetes Service resources
 */

locals {
  current_user_oid            = try(msgraph_resource_action.current_user.output.oid, null)
  should_assign_cluster_admin = var.cluster_admin_oid != null || var.should_add_current_user_cluster_admin
  cluster_admin_oid           = try(coalesce(var.cluster_admin_oid, local.current_user_oid), null)
}

/*
 * Data Sources
 */

resource "msgraph_resource_action" "current_user" {

  method       = "GET"
  resource_url = "me"


  response_export_values = {
    oid = "id"
  }
}

module "network" {
  source = "./modules/network"

  // Resource dependencies first
  resource_group         = var.resource_group
  network_security_group = var.network_security_group
  virtual_network        = var.virtual_network

  // Core parameters next
  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance

  // Optional parameters
  default_outbound_access_enabled = var.default_outbound_access_enabled
  nat_gateway_id                  = try(var.nat_gateway.id, null)
  subnet_address_prefixes_aks     = var.subnet_address_prefixes_aks
  subnet_address_prefixes_aks_pod = var.subnet_address_prefixes_aks_pod
  node_pools                      = var.node_pools
  should_enable_private_endpoint  = var.should_enable_private_endpoint
}


module "aks_cluster" {
  count = var.should_create_aks ? 1 : 0

  source = "./modules/aks-cluster"

  // Resource dependencies first
  resource_group               = var.resource_group
  snet_aks                     = module.network.snet_aks
  snet_aks_pod                 = module.network.snet_aks_pod
  acr                          = var.acr
  aks_identity                 = var.aks_identity
  log_analytics_workspace      = var.log_analytics_workspace
  metrics_data_collection_rule = var.metrics_data_collection_rule

  // Core parameters next
  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance

  // optional parameters
  node_count          = var.node_count
  node_vm_size        = var.node_vm_size
  dns_prefix          = var.dns_prefix
  enable_auto_scaling = var.enable_auto_scaling
  min_count           = var.min_count
  max_count           = var.max_count
  node_pools = {
    for name, config in var.node_pools : name => {
      node_count          = config.node_count
      vm_size             = config.vm_size
      vnet_subnet_id      = module.network.snet_aks_node_pool[name].id
      pod_subnet_id       = module.network.snet_aks_node_pool_pod[name].id
      node_taints         = config.node_taints
      enable_auto_scaling = config.enable_auto_scaling
      min_count           = config.min_count
      max_count           = config.max_count
      priority            = config.priority
      zones               = config.zones
      eviction_policy     = config.priority == "Spot" ? config.eviction_policy : null
      gpu_driver          = config.gpu_driver
    }
  }

  // Private cluster configuration
  should_enable_private_cluster             = var.should_enable_private_cluster
  should_enable_private_cluster_public_fqdn = var.should_enable_private_cluster_public_fqdn
  private_dns_zone_id                       = var.private_dns_zone_id
  should_enable_private_endpoint            = var.should_enable_private_endpoint
  private_endpoint_subnet_id                = var.private_endpoint_subnet_id
  virtual_network_id                        = var.virtual_network_id

  // Azure Monitor configuration
  should_enable_azure_monitor_metrics = var.should_enable_azure_monitor_metrics
  azure_monitor_annotations_allowed   = var.azure_monitor_annotations_allowed
  azure_monitor_labels_allowed        = var.azure_monitor_labels_allowed

  // Workload Identity configuration
  should_enable_workload_identity = var.should_enable_workload_identity
  should_enable_oidc_issuer       = var.should_enable_oidc_issuer

  // Cluster Admin configuration
  cluster_admin_oid            = local.cluster_admin_oid
  should_assign_cluster_admin  = local.should_assign_cluster_admin
  should_disable_local_account = var.should_disable_local_account
}

module "arc_cluster_instance" {
  count = var.should_create_arc_cluster_instance ? 1 : 0

  source = "./modules/connectedk8s"

  // Resource dependencies first
  resource_group = var.resource_group

  // Core parameters next
  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance
}

module "command_invoke" {
  # Execute for each command configuration provided
  for_each = var.aks_command_invoke_configurations

  source = "./modules/command-invoke"

  // Resource dependencies first
  cluster_id = coalesce(
    each.value.target_cluster_id,
    try(module.aks_cluster[0].aks.id, null)
  )

  // Command configuration
  command         = each.value.command
  file_path       = each.value.file_path
  folder_path     = each.value.folder_path
  timeout_minutes = each.value.timeout_minutes

  depends_on = [module.aks_cluster]
}
