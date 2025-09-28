/**
 * # Azure ML Unified Blueprint
 *
 * Adds Azure Machine Learning capabilities with optional foundational resource creation and scenario-driven deployment.
 */

// Defer computation to prevent `data` objects from querying for state on `terraform plan`.
// Needed for testing and build system compatibility.
resource "terraform_data" "defer" {
  input = {
    // Core existing resource names (resource group will often pre-exist)
    resource_group_name = coalesce(var.resource_group_name, "rg-${var.resource_prefix}-${var.environment}-${var.instance}")

    // Foundational (networking + acr) names
    acr_name             = coalesce(var.acr_name, "acr${replace(var.resource_prefix, "-", "")}${var.environment}${var.instance}")
    virtual_network_name = coalesce(var.virtual_network_name, "vnet-${var.resource_prefix}-${var.environment}-${var.instance}")
    subnet_name          = coalesce(var.subnet_name, "snet-${var.resource_prefix}-${var.environment}-${var.instance}")

    // Kubernetes / Arc naming (workspace integration in later phase)
    aks_cluster_name           = coalesce(var.aks_cluster_name, "aks-${var.resource_prefix}-${var.environment}-${var.instance}")
    arc_connected_cluster_name = coalesce(var.arc_connected_cluster_name, "arck-${var.resource_prefix}-${var.environment}-${var.instance}")
    azureml_workspace_name     = coalesce(var.azureml_workspace_name, "mlw-${var.resource_prefix}-${var.environment}-${var.instance}")
    key_vault_name             = coalesce(var.key_vault_name, "kv-${var.resource_prefix}-${var.environment}-${var.instance}")
    application_insights_name  = coalesce(var.application_insights_name, "appi-${var.resource_prefix}-${var.environment}-${var.instance}")
    storage_account_name       = var.storage_account_name
  }
}

locals {
  default_outbound_access_enabled = var.should_enable_managed_outbound_access == false
}

/*
 * Data Sources for Existing Resources (fabric-rti style)
 */

data "azurerm_resource_group" "existing" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_virtual_network" "existing" {
  count               = var.should_create_networking ? 0 : 1
  name                = terraform_data.defer.output.virtual_network_name
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_subnet" "existing" {
  count                = var.should_create_networking ? 0 : 1
  name                 = terraform_data.defer.output.subnet_name
  virtual_network_name = terraform_data.defer.output.virtual_network_name
  resource_group_name  = data.azurerm_resource_group.existing.name
}

data "azurerm_container_registry" "existing" {
  count               = var.should_create_acr ? 0 : 1
  name                = terraform_data.defer.output.acr_name
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_kubernetes_cluster" "existing" {
  count               = var.should_create_aks_cluster ? 0 : 1
  name                = terraform_data.defer.output.aks_cluster_name
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_key_vault" "existing" {
  count               = var.should_create_security_identity ? 0 : 1
  name                = terraform_data.defer.output.key_vault_name
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_application_insights" "existing" {
  count               = var.should_create_observability ? 0 : 1
  name                = terraform_data.defer.output.application_insights_name
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_storage_account" "existing" {
  count               = !var.should_create_storage ? 1 : 0
  name                = terraform_data.defer.output.storage_account_name
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azapi_resource" "arc_connected_cluster" {
  count     = var.should_deploy_edge_extension ? 1 : 0
  type      = "Microsoft.Kubernetes/connectedClusters@2024-01-01"
  parent_id = data.azurerm_resource_group.existing.id
  name      = terraform_data.defer.output.arc_connected_cluster_name

  response_export_values = ["name", "id", "location"]
}

// Conditional foundational modules

module "cloud_networking" {
  count  = var.should_create_networking ? 1 : 0
  source = "../../../src/000-cloud/050-networking/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group         = data.azurerm_resource_group.existing
  virtual_network_config = var.virtual_network_config

  // Private Resolver configuration
  should_enable_private_resolver   = var.should_enable_private_resolver
  resolver_subnet_address_prefix   = var.resolver_subnet_address_prefix
  default_outbound_access_enabled  = local.default_outbound_access_enabled
  should_enable_nat_gateway        = var.should_enable_managed_outbound_access
  nat_gateway_idle_timeout_minutes = var.nat_gateway_idle_timeout_minutes
  nat_gateway_public_ip_count      = var.nat_gateway_public_ip_count
  nat_gateway_zones                = var.nat_gateway_zones
}

module "cloud_security_identity" {
  count  = var.should_create_security_identity ? 1 : 0
  source = "../../../src/000-cloud/010-security-identity/terraform"

  depends_on = [module.cloud_networking]

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  aio_resource_group = data.azurerm_resource_group.existing

  should_create_identities           = true
  should_create_aio_identity         = false
  should_create_secret_sync_identity = false
  onboard_identity_type              = "skip"
  should_create_aks_identity         = var.should_create_aks_identity
  should_create_ml_workload_identity = var.should_create_ml_workload_identity

  # Private endpoint configuration
  should_create_key_vault_private_endpoint = var.should_enable_private_endpoints
  key_vault_private_endpoint_subnet_id     = try(module.cloud_networking[0].subnet_id, data.azurerm_subnet.existing[0].id, null)
  key_vault_virtual_network_id             = try(module.cloud_networking[0].virtual_network.id, data.azurerm_virtual_network.existing[0].id, null)
  should_enable_public_network_access      = var.should_enable_public_network_access
}

module "cloud_vpn_gateway" {
  count  = var.should_enable_vpn_gateway ? 1 : 0
  source = "../../../src/000-cloud/055-vpn-gateway/terraform"

  depends_on = [module.cloud_networking, module.cloud_security_identity]

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  aio_resource_group                  = data.azurerm_resource_group.existing
  virtual_network                     = try(module.cloud_networking[0].virtual_network, data.azurerm_virtual_network.existing[0])
  key_vault                           = try(module.cloud_security_identity[0].key_vault, data.azurerm_key_vault.existing[0], null)
  vpn_gateway_config                  = var.vpn_gateway_config
  vpn_gateway_subnet_address_prefixes = var.vpn_gateway_subnet_address_prefixes
  should_use_azure_ad_auth            = var.vpn_gateway_should_use_azure_ad_auth
  azure_ad_config                     = var.vpn_gateway_azure_ad_config
  should_generate_ca                  = var.vpn_gateway_should_generate_ca
  existing_certificate_name           = var.existing_certificate_name
  certificate_validity_days           = var.certificate_validity_days
  certificate_subject                 = var.certificate_subject
  default_outbound_access_enabled     = local.default_outbound_access_enabled
  vpn_site_connections                = var.vpn_site_connections
  vpn_site_default_ipsec_policy       = var.vpn_site_default_ipsec_policy
  vpn_site_shared_keys                = var.vpn_site_shared_keys
}

module "cloud_observability" {
  count  = var.should_create_observability ? 1 : 0
  source = "../../../src/000-cloud/020-observability/terraform"

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  azmon_resource_group            = data.azurerm_resource_group.existing
  should_enable_private_endpoints = var.should_enable_private_endpoints
  private_endpoint_subnet_id      = try(module.cloud_networking[0].subnet_id, data.azurerm_subnet.existing[0].id, null)
  virtual_network_id              = try(module.cloud_networking[0].virtual_network.id, data.azurerm_virtual_network.existing[0].id, null)
}

module "cloud_data" {
  count  = var.should_create_storage ? 1 : 0
  source = "../../../src/000-cloud/030-data/terraform"

  depends_on = [module.cloud_networking]

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group = data.azurerm_resource_group.existing

  should_create_schema_registry  = false
  storage_account_is_hns_enabled = false

  # Private endpoint configuration
  should_enable_private_endpoint      = var.should_enable_private_endpoints
  private_endpoint_subnet_id          = try(module.cloud_networking[0].subnet_id, data.azurerm_subnet.existing[0].id, null)
  virtual_network_id                  = try(module.cloud_networking[0].virtual_network.id, data.azurerm_virtual_network.existing[0].id, null)
  should_enable_public_network_access = var.should_enable_public_network_access
}

// Conditional foundational modules

module "cloud_acr" {
  count  = var.should_create_acr ? 1 : 0
  source = "../../../src/000-cloud/060-acr/terraform"

  depends_on = [module.cloud_networking]

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group                     = data.azurerm_resource_group.existing
  network_security_group             = try(module.cloud_networking[0].network_security_group, null)
  virtual_network                    = try(module.cloud_networking[0].virtual_network, data.azurerm_virtual_network.existing[0], null)
  should_create_acr_private_endpoint = var.should_enable_private_endpoints
  sku                                = var.acr_sku
  subnet_address_prefixes_acr        = var.subnet_address_prefixes_acr
  default_outbound_access_enabled    = local.default_outbound_access_enabled
  nat_gateway                        = try(module.cloud_networking[0].nat_gateway, null)
}

module "cloud_kubernetes" {
  count  = var.should_create_aks_cluster ? 1 : 0
  source = "../../../src/000-cloud/070-kubernetes/terraform"

  depends_on = [module.cloud_networking, module.cloud_acr]

  environment     = var.environment
  resource_prefix = var.resource_prefix
  location        = var.location
  instance        = var.instance

  should_create_aks = true

  // AKS cluster configuration
  dns_prefix                      = var.dns_prefix
  node_count                      = var.node_count
  node_vm_size                    = var.node_vm_size
  enable_auto_scaling             = var.enable_auto_scaling
  min_count                       = var.min_count
  max_count                       = var.max_count
  subnet_address_prefixes_aks     = var.subnet_address_prefixes_aks
  subnet_address_prefixes_aks_pod = var.subnet_address_prefixes_aks_pod
  node_pools                      = var.node_pools

  // Private cluster configuration
  should_enable_private_cluster             = var.aks_should_enable_private_cluster
  should_enable_private_cluster_public_fqdn = var.aks_should_enable_private_cluster_public_fqdn
  private_dns_zone_id                       = var.aks_private_dns_zone_id
  should_enable_private_endpoint            = var.should_enable_private_endpoints
  private_endpoint_subnet_id                = try(module.cloud_networking[0].subnet_id, data.azurerm_subnet.existing[0].id, null)
  virtual_network_id                        = try(module.cloud_networking[0].virtual_network.id, data.azurerm_virtual_network.existing[0].id, null)

  resource_group         = data.azurerm_resource_group.existing
  network_security_group = try(module.cloud_networking[0].network_security_group, null)
  virtual_network        = try(module.cloud_networking[0].virtual_network, data.azurerm_virtual_network.existing[0], null)
  acr                    = try(module.cloud_acr[0].acr, data.azurerm_container_registry.existing[0], null)
  aks_identity           = try(module.cloud_security_identity[0].aks_identity, null)

  // Azure Monitor configuration
  log_analytics_workspace      = try(module.cloud_observability[0].log_analytics_workspace, null)
  metrics_data_collection_rule = try(module.cloud_observability[0].metrics_data_collection_rule, null)

  // Enable workload identity by default for Azure ML scenarios
  should_enable_workload_identity = true
  should_enable_oidc_issuer       = true

  default_outbound_access_enabled = local.default_outbound_access_enabled
  nat_gateway                     = try(module.cloud_networking[0].nat_gateway, null)

  // AKS Command Invoke Configuration for chart installation
  aks_command_invoke_configurations = var.should_install_charts ? {
    "install-charts" = {
      command     = "./${var.charts_install_script_name}"
      folder_path = coalesce(var.charts_scripts_folder_path, "${path.module}/../scripts")
    }
  } : {}
}

module "cloud_azureml" {
  source = "../../../src/000-cloud/080-azureml/terraform"

  depends_on = [module.cloud_kubernetes, module.cloud_acr, module.cloud_data, module.cloud_observability]

  environment     = var.environment
  location        = var.location
  resource_prefix = var.resource_prefix
  instance        = var.instance

  resource_group = data.azurerm_resource_group.existing

  workspace_name                             = terraform_data.defer.output.azureml_workspace_name
  workspace_friendly_name                    = var.workspace_friendly_name
  should_assign_current_user_workspace_roles = true
  should_enable_public_network_access        = var.should_enable_public_network_access

  // Compute cluster configuration
  should_create_compute_cluster = var.should_create_compute_cluster
  compute_cluster_name          = var.compute_cluster_name
  compute_cluster_idle_duration = var.compute_cluster_idle_duration
  compute_cluster_max_nodes     = var.compute_cluster_max_nodes
  compute_cluster_min_nodes     = var.compute_cluster_min_nodes
  compute_cluster_vm_priority   = var.compute_cluster_vm_priority
  compute_cluster_vm_size       = var.compute_cluster_vm_size

  key_vault            = try(module.cloud_security_identity[0].key_vault, data.azurerm_key_vault.existing[0], null)
  application_insights = try(module.cloud_observability[0].application_insights, data.azurerm_application_insights.existing[0], null)
  storage_account      = try(module.cloud_data[0].storage_account, data.azurerm_storage_account.existing[0], null)

  acr                    = try(module.cloud_acr[0].acr, data.azurerm_container_registry.existing[0], null)
  network_security_group = try(module.cloud_networking[0].network_security_group, null)
  virtual_network        = try(module.cloud_networking[0].virtual_network, data.azurerm_virtual_network.existing[0], null)
  nat_gateway            = try(module.cloud_networking[0].nat_gateway, null)
  kubernetes             = try(module.cloud_kubernetes[0].aks, data.azurerm_kubernetes_cluster.existing[0], null)

  default_outbound_access_enabled     = local.default_outbound_access_enabled
  extension_name                      = var.extension_name
  aks_compute_target_name             = var.aks_compute_target_name
  should_enable_aks_training          = var.should_enable_cluster_training
  should_enable_aks_inference         = var.should_enable_cluster_inference
  should_enable_inference_router_ha   = var.should_enable_inference_router_ha
  inference_router_service_type       = var.inference_router_service_type
  should_install_dcgm_exporter        = var.should_install_dcgm_exporter
  should_install_nvidia_device_plugin = var.should_install_nvidia_device_plugin
  should_install_prom_op              = var.should_install_prom_op
  should_install_volcano              = var.should_install_volcano
  aks_cluster_purpose                 = var.aks_cluster_purpose
  ssl_cname                           = var.ssl_cname
  ssl_cert_pem                        = var.ssl_cert_pem
  ssl_key_pem                         = var.ssl_key_pem
  ml_workload_identity                = try(module.cloud_security_identity[0].ml_workload_identity, null)
  ml_workload_subjects                = var.ml_workload_subjects

  should_integrate_aks_cluster = var.should_integrate_aks_cluster

  // Toleration configuration
  system_tolerations   = var.system_tolerations
  workload_tolerations = var.workload_tolerations

  // Kubernetes compute configuration
  cluster_integration_default_instance_type = var.cluster_integration_default_instance_type
  cluster_integration_instance_types        = var.cluster_integration_instance_types

  // AKS integration specific configuration
  cluster_integration_description        = var.cluster_integration_description
  cluster_integration_disable_local_auth = var.cluster_integration_disable_local_auth

  // Private endpoint configuration
  should_enable_private_endpoint = var.should_enable_private_endpoints
  private_endpoint_subnet_id     = try(module.cloud_networking[0].subnet_id, data.azurerm_subnet.existing[0].id, null)
  virtual_network_id             = try(module.cloud_networking[0].virtual_network.id, data.azurerm_virtual_network.existing[0].id, null)

  // Registry configuration
  should_deploy_registry                       = var.should_deploy_azureml_registry
  registry_should_enable_public_network_access = var.registry_should_enable_public_network_access

  // Registry dependencies
  registry_storage_account = try(module.cloud_data[0].storage_account, data.azurerm_storage_account.existing[0], null)
  registry_acr             = try(module.cloud_acr[0].acr, data.azurerm_container_registry.existing[0], null)
}

module "edge_azureml" {
  count  = var.should_deploy_edge_extension ? 1 : 0
  source = "../../../src/100-edge/140-azureml/terraform"

  depends_on = [module.cloud_azureml]

  environment     = var.environment
  resource_prefix = var.resource_prefix
  instance        = var.instance
  location        = var.location

  extension_name                    = var.extension_name
  should_enable_training            = var.should_enable_cluster_training
  should_enable_inference           = var.should_enable_cluster_inference
  should_enable_inference_router_ha = var.should_enable_inference_router_ha
  inference_router_service_type     = var.inference_router_service_type
  ssl_cname                         = var.ssl_cname
  ssl_cert_pem                      = var.ssl_cert_pem
  ssl_key_pem                       = var.ssl_key_pem

  connected_cluster               = data.azapi_resource.arc_connected_cluster[0]
  resource_group                  = data.azurerm_resource_group.existing
  workspace_identity_principal_id = module.cloud_azureml.workspace_principal_id
  machine_learning_workspace      = module.cloud_azureml.azureml_workspace
  arc_compute_target_name         = var.arc_compute_target_name
  arc_cluster_purpose             = var.arc_cluster_purpose

  // Toleration configuration
  system_tolerations   = var.system_tolerations
  workload_tolerations = var.workload_tolerations
  ml_workload_identity = try(module.cloud_security_identity[0].ml_workload_identity, null)
  ml_workload_subjects = var.ml_workload_subjects

  // Kubernetes compute configuration
  cluster_integration_default_instance_type = var.cluster_integration_default_instance_type
  cluster_integration_instance_types        = var.cluster_integration_instance_types
  cluster_integration_description           = var.cluster_integration_description
  cluster_integration_disable_local_auth    = var.cluster_integration_disable_local_auth
}
