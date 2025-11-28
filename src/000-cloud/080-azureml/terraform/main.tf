/**
 * # Azure Machine Learning Component
 *
 * Creates Azure Machine Learning workspace with optional compute cluster and
 * AKS cluster integration for AI model training and deployment. Integrates with
 * existing cloud infrastructure including Key Vault, Storage Account, Application Insights, and networking.
 */

/*
 * Current User Data (Microsoft Graph)
 */

resource "msgraph_resource_action" "current_user" {
  count = var.should_assign_current_user_workspace_roles ? 1 : 0

  method       = "GET"
  resource_url = "me"


  response_export_values = {
    oid = "id"
  }
}

/*
 * Network Module for Azure ML Compute Cluster
 */

module "network" {
  count = alltrue([var.should_create_compute_cluster, var.should_create_compute_cluster_snet]) ? 1 : 0

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
  default_outbound_access_enabled         = var.default_outbound_access_enabled
  should_associate_network_security_group = var.should_associate_network_security_group
  should_enable_nat_gateway               = var.should_enable_nat_gateway
  nat_gateway_id                          = var.should_enable_nat_gateway ? var.nat_gateway.id : null
  subnet_address_prefixes_azureml         = var.subnet_address_prefixes_azureml
}

// Azure Machine Learning Workspace
module "workspace" {
  source = "./modules/workspace"

  depends_on = [module.network]

  name                                       = var.workspace_name
  resource_prefix                            = var.resource_prefix
  environment                                = var.environment
  instance                                   = var.instance
  location                                   = var.location
  resource_group_name                        = var.resource_group.name
  application_insights_id                    = var.application_insights.id
  key_vault_id                               = var.key_vault.id
  storage_account_id                         = var.storage_account.id
  container_registry_id                      = var.acr.id
  public_network_access_enabled              = var.should_enable_public_network_access
  description                                = "Azure Machine Learning workspace for ${var.resource_prefix}-${var.environment}-${var.instance}"
  friendly_name                              = coalesce(var.workspace_friendly_name, "${var.resource_prefix}-${var.environment}-${var.instance} ML Workspace")
  should_assign_current_user_workspace_roles = var.should_assign_current_user_workspace_roles
  current_user_object_id                     = try(msgraph_resource_action.current_user[0].output.oid, null)
  ml_workload_identity                       = var.ml_workload_identity
  should_assign_ml_workload_identity_roles   = var.should_assign_ml_workload_identity_roles

  // Role assignment configuration
  should_assign_workspace_managed_identity_roles = var.should_assign_workspace_managed_identity_roles

  // Private endpoint configuration
  should_enable_private_endpoint = var.should_enable_private_endpoint
  private_endpoint_subnet_id     = var.private_endpoint_subnet_id
  virtual_network_id             = try(var.virtual_network.id, null)
}

// Optional Registry for ML model and environment management
module "registry" {
  count = var.should_deploy_registry ? 1 : 0

  source = "./modules/registry"

  depends_on = [module.workspace]

  // Resource dependencies first
  resource_group = var.resource_group

  // Core parameters next
  resource_prefix     = var.resource_prefix
  environment         = var.environment
  instance            = var.instance
  location            = var.location
  resource_group_name = var.resource_group.name

  description = coalesce(var.registry_description, "Azure Machine Learning Registry for ${var.resource_prefix}-${var.environment}-${var.instance}")

  should_enable_public_network_access = var.registry_should_enable_public_network_access

  // Network configuration
  should_enable_private_endpoint = var.should_enable_private_endpoint
  private_endpoint_subnet_id     = var.private_endpoint_subnet_id

  // DNS integration (share workspace DNS zone)
  api_dns_zone_name = try(module.workspace.private_dns_zones["privatelink.api.azureml.ms"].name, null)

  // Dependencies from other cloud components
  storage_account = var.registry_storage_account
  acr             = var.registry_acr
}

// Optional Compute Cluster for ML training workloads
module "compute_cluster" {
  count = var.should_create_compute_cluster ? 1 : 0

  source = "./modules/compute-cluster"

  depends_on = [module.workspace, module.network]

  name                                 = var.compute_cluster_name
  resource_prefix                      = var.resource_prefix
  environment                          = var.environment
  instance                             = var.instance
  machine_learning_workspace_id        = module.workspace.workspace.id
  location                             = var.location
  vm_size                              = var.compute_cluster_vm_size
  vm_priority                          = var.compute_cluster_vm_priority
  snet_azureml                         = try(module.network[0].snet_azureml, var.compute_cluster_subnet)
  description                          = "Compute cluster for ML training workloads"
  min_node_count                       = var.compute_cluster_min_nodes
  max_node_count                       = var.compute_cluster_max_nodes
  scale_down_nodes_after_idle_duration = var.compute_cluster_idle_duration
  node_public_ip_enabled               = var.compute_cluster_node_public_ip_enabled
  ssh_public_access_enabled            = var.compute_cluster_ssh_public_access_enabled
}

// Optional AKS Cluster Integration with Azure ML Extension for ML workspace
module "inference_cluster_integration" {
  count = var.should_integrate_aks_cluster ? 1 : 0

  source = "./modules/inference-cluster-integration"

  depends_on = [module.workspace]

  extension_name                         = var.extension_name
  compute_target_name                    = var.aks_compute_target_name
  resource_prefix                        = var.resource_prefix
  environment                            = var.environment
  instance                               = var.instance
  machine_learning_workspace_id          = module.workspace.workspace.id
  kubernetes_cluster_id                  = var.kubernetes.id
  kubernetes_cluster_name                = var.kubernetes.name
  kubernetes_cluster_resource_group_name = var.kubernetes.resource_group_name
  location                               = var.location
  cluster_purpose                        = var.aks_cluster_purpose
  should_enable_aks_training             = var.should_enable_aks_training
  should_enable_aks_inference            = var.should_enable_aks_inference
  inference_router_service_type          = var.inference_router_service_type
  inference_router_ha                    = var.should_enable_inference_router_ha
  should_install_dcgm_exporter           = var.should_install_dcgm_exporter
  should_install_nvidia_device_plugin    = var.should_install_nvidia_device_plugin
  should_install_prom_op                 = var.should_install_prom_op
  should_install_volcano                 = var.should_install_volcano
  ssl_cname                              = var.ssl_cname
  ssl_cert_pem                           = var.ssl_cert_pem
  ssl_key_pem                            = var.ssl_key_pem
  workspace_identity_principal_id        = module.workspace.principal_id
  system_tolerations                     = var.system_tolerations
  workload_tolerations                   = var.workload_tolerations

  // Kubernetes compute configuration
  default_instance_type            = var.cluster_integration_default_instance_type
  extension_instance_release_train = var.cluster_integration_extension_instance_release_train
  instance_types                   = var.cluster_integration_instance_types
  kubernetes_namespace             = var.cluster_integration_kubernetes_namespace
  workspace_identity_id            = var.cluster_integration_workspace_identity_id
  vc_name                          = var.cluster_integration_vc_name

  ml_workload_identity                  = var.ml_workload_identity
  ml_workload_subjects                  = var.ml_workload_subjects
  should_configure_ml_workload_identity = var.should_assign_ml_workload_identity_roles
  resource_group_name                   = var.resource_group.name

  // App Configuration integration for volcano scheduler
  volcano_scheduler_configmap_name = try(var.kubernetes.app_configuration_configmap_name, null)

  // AKS integration specific configuration
  description        = coalesce(var.cluster_integration_description, "Azure ML AKS compute target for ${var.resource_prefix}-${var.environment}-${var.instance}")
  disable_local_auth = var.cluster_integration_disable_local_auth
}
