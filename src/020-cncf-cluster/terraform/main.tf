/**
 * # CNCF Cluster
 *
 * Sets up and deploys a script to a VM host that will setup the cluster,
 * Arc connect the cluster, Add cluster admins to the cluster, enable workload identity,
 * install extensions for cluster connect and custom locations.
 */

locals {
  arc_resource_name    = "arc-${var.resource_prefix}-${var.environment}-${var.instance}"
  custom_locations_oid = try(coalesce(var.custom_locations_oid, data.azuread_service_principal.custom_locations[0].object_id), "")
  current_user_oid     = var.should_add_current_user_cluster_admin ? data.azurerm_client_config.current.object_id : null
}

data "azurerm_client_config" "current" {
}

data "azuread_service_principal" "custom_locations" {
  count = alltrue([var.should_get_custom_locations_oid, var.custom_locations_oid == null]) ? 1 : 0

  # ref: https://learn.microsoft.com/azure/iot-operations/deploy-iot-ops/howto-prepare-cluster?tabs=ubuntu#arc-enable-your-cluster
  client_id = "bc313c14-388c-4e7d-a58e-70017303ee3b" #gitleaks:allow
}

module "ubuntu_k3s" {
  source = "./modules/ubuntu-k3s"

  aio_resource_group                   = var.aio_resource_group
  arc_onboarding_sp_client_id          = var.arc_onboarding_sp_client_id
  arc_onboarding_sp_client_secret      = var.arc_onboarding_sp_client_secret
  arc_resource_name                    = local.arc_resource_name
  arc_tenant_id                        = data.azurerm_client_config.current.tenant_id
  cluster_admin_oid                    = try(coalesce(var.cluster_admin_oid, local.current_user_oid), null)
  custom_locations_oid                 = local.custom_locations_oid
  should_enable_arc_auto_upgrade       = var.should_enable_arc_auto_upgrade
  environment                          = var.environment
  cluster_node_virtual_machines        = var.cluster_node_virtual_machines
  cluster_server_ip                    = var.cluster_server_ip
  cluster_server_token                 = var.cluster_server_token
  cluster_server_virtual_machine       = var.cluster_server_virtual_machine
  script_output_filepath               = var.script_output_filepath
  should_deploy_script_to_vm           = var.should_deploy_script_to_vm
  should_generate_cluster_server_token = var.should_generate_cluster_server_token
  should_output_cluster_node_script    = var.should_output_cluster_node_script
  should_output_cluster_server_script  = var.should_output_cluster_server_script
  should_skip_az_cli_login             = var.should_skip_az_cli_login
  should_skip_installing_az_cli        = var.should_skip_installing_az_cli
  cluster_server_host_machine_username = coalesce(var.cluster_server_host_machine_username, var.resource_prefix)
}

data "azapi_resource" "arc_connected_cluster" {
  count = var.should_deploy_script_to_vm ? 1 : 0

  type      = "Microsoft.Kubernetes/connectedClusters@2024-01-01"
  parent_id = var.aio_resource_group.id
  name      = local.arc_resource_name

  depends_on = [module.ubuntu_k3s]

  response_export_values = ["name", "id", "location", "properties.oidcIssuerProfile.issuerUrl"]
}
