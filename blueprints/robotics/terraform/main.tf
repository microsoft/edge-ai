/**
 * # Robotics Blueprint
 *
 * Deploys robotics infrastructure with NVIDIA GPU support, KAI Scheduler,
 * and optional Azure Machine Learning integration.
 */

module "robotics" {
  source = "../../modules/robotics/terraform"

  // Core variables (required)
  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  // Foundational creation flags - robotics typically needs full stack
  should_create_networking        = var.should_create_networking
  should_create_acr               = var.should_create_acr
  should_create_aks_cluster       = var.should_create_aks_cluster
  should_create_security_identity = var.should_create_security_identity
  should_create_observability     = var.should_create_observability
  should_create_storage           = var.should_create_storage

  // Security identity configuration
  should_use_current_user_key_vault_admin = var.should_use_current_user_key_vault_admin

  // PostgreSQL configuration
  should_deploy_postgresql                         = var.should_deploy_postgresql
  postgresql_admin_username                        = var.postgresql_admin_username
  postgresql_admin_password                        = var.postgresql_admin_password
  postgresql_should_generate_admin_password        = var.postgresql_should_generate_admin_password
  postgresql_should_store_credentials_in_key_vault = var.postgresql_should_store_credentials_in_key_vault
  postgresql_databases                             = var.postgresql_databases
  postgresql_delegated_subnet_id                   = var.postgresql_delegated_subnet_id
  postgresql_should_enable_extensions              = var.postgresql_should_enable_extensions
  postgresql_should_enable_geo_redundant_backup    = var.postgresql_should_enable_geo_redundant_backup
  postgresql_should_enable_timescaledb             = var.postgresql_should_enable_timescaledb
  postgresql_sku_name                              = var.postgresql_sku_name
  postgresql_storage_mb                            = var.postgresql_storage_mb
  postgresql_subnet_address_prefixes               = var.postgresql_subnet_address_prefixes
  postgresql_version                               = var.postgresql_version

  // Azure Managed Redis configuration
  should_deploy_redis                      = var.should_deploy_redis
  redis_sku_name                           = var.redis_sku_name
  redis_should_enable_high_availability    = var.redis_should_enable_high_availability
  redis_clustering_policy                  = var.redis_clustering_policy
  redis_access_keys_authentication_enabled = var.redis_access_keys_authentication_enabled

  // ML workload identity and compute cluster
  should_create_ml_workload_identity = var.should_create_ml_workload_identity
  should_create_compute_cluster      = var.should_create_compute_cluster
  compute_cluster_vm_priority        = var.compute_cluster_vm_priority
  compute_cluster_min_nodes          = var.compute_cluster_min_nodes
  compute_cluster_max_nodes          = var.compute_cluster_max_nodes

  // Resource name overrides
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  aks_cluster_name     = var.aks_cluster_name

  // Network configuration
  virtual_network_config          = var.virtual_network_config
  subnet_address_prefixes_aks     = var.subnet_address_prefixes_aks
  subnet_address_prefixes_aks_pod = var.subnet_address_prefixes_aks_pod

  // AKS Configuration optimized for robotics
  node_vm_size        = var.node_vm_size
  node_count          = var.node_count
  node_pools          = var.node_pools
  enable_auto_scaling = var.enable_auto_scaling
  min_count           = var.min_count
  max_count           = var.max_count

  // GPU and robotics-specific configuration
  should_integrate_aks_cluster = var.should_integrate_aks_cluster
  aks_cluster_purpose          = var.aks_cluster_purpose

  // Workload scheduling configuration
  workload_tolerations               = var.workload_tolerations
  cluster_integration_instance_types = var.cluster_integration_instance_types

  // Edge deployment
  should_deploy_edge_extension = var.should_deploy_edge_extension

  // Private endpoints and VPN
  should_enable_private_endpoints = var.should_enable_private_endpoints
  should_enable_vpn_gateway       = var.should_enable_vpn_gateway
  vpn_site_connections            = var.vpn_site_connections
  vpn_site_default_ipsec_policy   = var.vpn_site_default_ipsec_policy
  vpn_site_shared_keys            = var.vpn_site_shared_keys

  // VM host configuration
  should_create_vm_host               = var.should_create_vm_host
  vm_host_count                       = var.vm_host_count
  vm_sku_size                         = var.vm_sku_size
  vm_priority                         = var.vm_priority
  vm_eviction_policy                  = var.vm_eviction_policy
  vm_max_bid_price                    = var.vm_max_bid_price
  should_assign_current_user_vm_admin = var.should_assign_current_user_vm_admin
  should_use_vm_password_auth         = var.should_use_vm_password_auth
  should_create_vm_ssh_key            = var.should_create_vm_ssh_key

  // Inference router
  inference_router_service_type = var.inference_router_service_type

  // Chart installation - Robotics by default, AzureML optional
  should_install_robotics_charts      = var.should_install_robotics_charts
  should_install_azureml_charts       = var.should_install_azureml_charts
  should_install_nvidia_device_plugin = var.should_install_nvidia_device_plugin
  should_install_dcgm_exporter        = var.should_install_dcgm_exporter
  should_install_volcano              = var.should_install_volcano

  // AzureML registry
  should_deploy_azureml_registry = var.should_deploy_azureml_registry

  // Optional AzureML integration
  azureml_workspace_name                = var.azureml_workspace_name
  should_enable_managed_outbound_access = var.should_enable_managed_outbound_access
}
