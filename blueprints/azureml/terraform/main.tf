/**
 * # Azure ML Unified Blueprint
 *
 * This blueprint provides Azure Machine Learning capabilities with optional foundational resource creation and scenario-driven deployment.
 *
 */

module "robotics" {
  source = "../../modules/robotics/terraform"

  // Core parameters
  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance

  // Foundational creation flags
  should_create_acr         = var.should_create_acr
  should_create_aks_cluster = var.should_create_aks_cluster
  should_create_networking  = var.should_create_networking

  // Foundational resource name overrides
  acr_name                   = var.acr_name
  subnet_name                = var.subnet_name
  virtual_network_name       = var.virtual_network_name
  resource_group_name        = var.resource_group_name
  aks_cluster_name           = var.aks_cluster_name
  arc_connected_cluster_name = var.arc_connected_cluster_name

  // AKS cluster configuration
  should_create_aks_identity       = var.should_create_aks_identity
  dns_prefix                       = var.dns_prefix
  node_count                       = var.node_count
  node_vm_size                     = var.node_vm_size
  subnet_address_prefixes_aks      = var.subnet_address_prefixes_aks
  subnet_address_prefixes_aks_pod  = var.subnet_address_prefixes_aks_pod
  enable_auto_scaling              = var.enable_auto_scaling
  min_count                        = var.min_count
  max_count                        = var.max_count
  node_pools                       = var.node_pools
  should_disable_aks_local_account = var.should_disable_aks_local_account

  // Scenario selection flags
  should_deploy_edge_extension = var.should_deploy_edge_extension
  should_integrate_aks_cluster = var.should_integrate_aks_cluster

  // Azure ML workspace configuration
  azureml_workspace_name = var.azureml_workspace_name

  // Public network access configuration
  should_enable_public_network_access = var.should_enable_public_network_access

  // Optional supporting components
  should_create_security_identity    = var.should_create_security_identity
  should_create_ml_workload_identity = var.should_create_ml_workload_identity
  should_create_observability        = var.should_create_observability
  key_vault_name                     = var.key_vault_name
  application_insights_name          = var.application_insights_name
  storage_account_name               = var.storage_account_name
  should_create_storage              = var.should_create_storage

  // PostgreSQL configuration
  should_deploy_postgresql                         = var.should_deploy_postgresql
  postgresql_admin_username                        = var.postgresql_admin_username
  postgresql_admin_password                        = var.postgresql_admin_password
  postgresql_should_generate_admin_password        = var.postgresql_should_generate_admin_password
  postgresql_should_store_credentials_in_key_vault = var.postgresql_should_store_credentials_in_key_vault
  postgresql_delegated_subnet_id                   = var.postgresql_delegated_subnet_id
  postgresql_databases                             = var.postgresql_databases
  postgresql_should_enable_extensions              = var.postgresql_should_enable_extensions
  postgresql_should_enable_geo_redundant_backup    = var.postgresql_should_enable_geo_redundant_backup
  postgresql_should_enable_timescaledb             = var.postgresql_should_enable_timescaledb
  postgresql_sku_name                              = var.postgresql_sku_name
  postgresql_storage_mb                            = var.postgresql_storage_mb
  postgresql_version                               = var.postgresql_version

  // Azure Managed Redis configuration
  should_deploy_redis                   = var.should_deploy_redis
  redis_sku_name                        = var.redis_sku_name
  redis_should_enable_high_availability = var.redis_should_enable_high_availability
  redis_clustering_policy               = var.redis_clustering_policy

  // Azure ML workspace additional configuration
  workspace_friendly_name = var.workspace_friendly_name

  // Registry configuration
  should_deploy_azureml_registry               = var.should_deploy_azureml_registry
  registry_should_enable_public_network_access = var.registry_should_enable_public_network_access

  // Compute cluster configuration
  should_create_compute_cluster = var.should_create_compute_cluster
  ml_workload_subjects          = var.ml_workload_subjects
  compute_cluster_name          = var.compute_cluster_name
  compute_cluster_idle_duration = var.compute_cluster_idle_duration
  compute_cluster_max_nodes     = var.compute_cluster_max_nodes
  compute_cluster_min_nodes     = var.compute_cluster_min_nodes
  compute_cluster_vm_priority   = var.compute_cluster_vm_priority
  compute_cluster_vm_size       = var.compute_cluster_vm_size

  // Component-specific configuration
  virtual_network_config          = var.virtual_network_config
  should_enable_private_endpoints = var.should_enable_private_endpoints

  // Outbound access configuration
  should_enable_managed_outbound_access = var.should_enable_managed_outbound_access
  nat_gateway_idle_timeout_minutes      = var.nat_gateway_idle_timeout_minutes
  nat_gateway_public_ip_count           = var.nat_gateway_public_ip_count
  nat_gateway_zones                     = var.nat_gateway_zones

  // AKS private cluster configuration
  aks_should_enable_private_cluster             = var.aks_should_enable_private_cluster
  aks_should_enable_private_cluster_public_fqdn = var.aks_should_enable_private_cluster_public_fqdn
  aks_private_dns_zone_id                       = var.aks_private_dns_zone_id

  // VPN gateway configuration
  should_enable_vpn_gateway            = var.should_enable_vpn_gateway
  vpn_gateway_config                   = var.vpn_gateway_config
  vpn_gateway_subnet_address_prefixes  = var.vpn_gateway_subnet_address_prefixes
  vpn_site_connections                 = var.vpn_site_connections
  vpn_site_default_ipsec_policy        = var.vpn_site_default_ipsec_policy
  vpn_site_shared_keys                 = var.vpn_site_shared_keys
  vpn_gateway_should_use_azure_ad_auth = var.vpn_gateway_should_use_azure_ad_auth
  vpn_gateway_azure_ad_config          = var.vpn_gateway_azure_ad_config
  vpn_gateway_should_generate_ca       = var.vpn_gateway_should_generate_ca
  existing_certificate_name            = var.existing_certificate_name
  should_enable_private_resolver       = var.should_enable_private_resolver
  resolver_subnet_address_prefix       = var.resolver_subnet_address_prefix
  certificate_validity_days            = var.certificate_validity_days
  certificate_subject                  = var.certificate_subject

  // ACR configuration
  acr_sku                           = var.acr_sku
  subnet_address_prefixes_acr       = var.subnet_address_prefixes_acr
  acr_allow_trusted_services        = var.acr_allow_trusted_services
  acr_allowed_public_ip_ranges      = var.acr_allowed_public_ip_ranges
  acr_data_endpoint_enabled         = var.acr_data_endpoint_enabled
  acr_public_network_access_enabled = var.acr_public_network_access_enabled

  // VM host configuration
  should_create_vm_host               = var.should_create_vm_host
  vm_host_count                       = var.vm_host_count
  vm_sku_size                         = var.vm_sku_size
  vm_priority                         = var.vm_priority
  vm_eviction_policy                  = var.vm_eviction_policy
  vm_max_bid_price                    = var.vm_max_bid_price
  should_assign_current_user_vm_admin = var.should_assign_current_user_vm_admin
  vm_admin_principals                 = var.vm_admin_principals
  vm_user_principals                  = var.vm_user_principals
  should_create_vm_ssh_key            = var.should_create_vm_ssh_key
  should_use_vm_password_auth         = var.should_use_vm_password_auth

  // AKS integration configuration
  extension_name                      = var.extension_name
  aks_compute_target_name             = var.aks_compute_target_name
  arc_compute_target_name             = var.arc_compute_target_name
  arc_cluster_purpose                 = var.arc_cluster_purpose
  should_enable_cluster_training      = var.should_enable_cluster_training
  should_enable_cluster_inference     = var.should_enable_cluster_inference
  should_enable_inference_router_ha   = var.should_enable_inference_router_ha
  inference_router_service_type       = var.inference_router_service_type
  should_install_dcgm_exporter        = var.should_install_dcgm_exporter
  should_install_nvidia_device_plugin = var.should_install_nvidia_device_plugin
  should_install_prom_op              = var.should_install_prom_op
  should_install_volcano              = var.should_install_volcano
  aks_cluster_purpose                 = var.aks_cluster_purpose

  // SSL/TLS configuration
  ssl_cname    = var.ssl_cname
  ssl_cert_pem = var.ssl_cert_pem
  ssl_key_pem  = var.ssl_key_pem

  // AzureML extension toleration configuration
  system_tolerations   = var.system_tolerations
  workload_tolerations = var.workload_tolerations

  // Kubernetes compute configuration
  cluster_integration_description           = var.cluster_integration_description
  cluster_integration_disable_local_auth    = var.cluster_integration_disable_local_auth
  cluster_integration_default_instance_type = var.cluster_integration_default_instance_type
  cluster_integration_instance_types        = var.cluster_integration_instance_types

  // Chart installation configuration - AzureML only
  should_install_robotics_charts = false
  should_install_azureml_charts  = var.should_install_charts
}
