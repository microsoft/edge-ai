/**
 * # CNCF Cluster
 *
 * Sets up and deploys a script to a VM host that will setup the cluster,
 * Arc connect the cluster, Add cluster admins to the cluster, enable workload identity,
 * install extensions for cluster connect and custom locations.
 */

locals {
  arc_resource_name            = "arck-${var.resource_prefix}-${var.environment}-${var.instance}"
  custom_locations_oid         = try(coalesce(var.custom_locations_oid), data.azuread_service_principal.custom_locations[0].object_id, "")
  current_user_oid             = var.should_add_current_user_cluster_admin ? data.azurerm_client_config.current.object_id : null
  should_use_principal_ids     = var.arc_onboarding_principal_ids != null
  arc_onboarding_principal_ids = local.should_use_principal_ids ? var.arc_onboarding_principal_ids : [try(var.arc_onboarding_identity.principal_id, var.arc_onboarding_sp.object_id, null)]
}

/*
 * Data Sources
 */

data "azurerm_client_config" "current" {
}

data "azuread_service_principal" "custom_locations" {
  count = alltrue([var.should_get_custom_locations_oid, try(length(var.custom_locations_oid), 0) == 0]) ? 1 : 0

  // ref: https://learn.microsoft.com/azure/iot-operations/deploy-iot-ops/howto-prepare-cluster?tabs=ubuntu#arc-enable-your-cluster
  client_id = "bc313c14-388c-4e7d-a58e-70017303ee3b" #gitleaks:allow
}

/*
 * Role Assignments
 */

module "role_assignments" {
  source = "./modules/role-assignments"
  count  = var.should_assign_roles ? 1 : 0

  resource_group               = var.resource_group
  key_vault                    = var.key_vault
  should_upload_to_key_vault   = var.should_upload_to_key_vault
  arc_onboarding_principal_ids = local.arc_onboarding_principal_ids
}

/*
 * Ubuntu K3s Cluster Setup
 */

module "ubuntu_k3s" {
  source = "./modules/ubuntu-k3s"

  depends_on = [module.role_assignments]

  aio_resource_group                        = var.resource_group
  arc_onboarding_sp                         = var.arc_onboarding_sp
  arc_resource_name                         = local.arc_resource_name
  arc_tenant_id                             = data.azurerm_client_config.current.tenant_id
  cluster_admin_oid                         = try(coalesce(var.cluster_admin_oid, local.current_user_oid), null)
  custom_locations_oid                      = local.custom_locations_oid
  should_enable_arc_auto_upgrade            = var.should_enable_arc_auto_upgrade
  environment                               = var.environment
  cluster_server_ip                         = var.cluster_server_ip
  cluster_server_token                      = var.cluster_server_token
  script_output_filepath                    = var.script_output_filepath
  should_generate_cluster_server_token      = var.should_generate_cluster_server_token
  should_output_cluster_node_script         = var.should_output_cluster_node_script
  should_output_cluster_server_script       = var.should_output_cluster_server_script
  should_skip_az_cli_login                  = var.should_skip_az_cli_login
  should_skip_installing_az_cli             = var.should_skip_installing_az_cli
  cluster_server_host_machine_username      = coalesce(var.cluster_server_host_machine_username, var.resource_prefix)
  key_vault                                 = var.key_vault
  should_upload_to_key_vault                = var.should_upload_to_key_vault
  should_use_script_from_secrets_for_deploy = var.should_use_script_from_secrets_for_deploy
}

data "azapi_resource" "arc_connected_cluster" {
  count = var.should_deploy_script_to_vm ? 1 : 0

  type      = "Microsoft.Kubernetes/connectedClusters@2024-01-01"
  parent_id = var.resource_group.id
  name      = local.arc_resource_name

  depends_on = [module.cluster_server_script_deployment, module.cluster_server_arc_script_deployment]

  response_export_values = ["name", "id", "location", "properties.oidcIssuerProfile.issuerUrl"]
}

/*
 * Virtual Machine Extensions
 */

module "cluster_server_script_deployment" {
  source = "./modules/vm-script-deployment"
  count  = var.should_deploy_script_to_vm && !var.should_deploy_arc_machines ? 1 : 0

  depends_on = [module.ubuntu_k3s]

  extension_name = "linux-cluster-server-setup"
  machine_id     = try(var.cluster_server_machine.id, null)
  script_content = module.ubuntu_k3s.server_script_content

  // Key Vault script deployment parameters
  should_use_script_from_secrets_for_deploy = var.should_use_script_from_secrets_for_deploy
  kubernetes_distro                         = "k3s"
  node_type                                 = "server"
  secret_name_prefix                        = var.key_vault_script_secret_prefix
  key_vault                                 = var.key_vault
}

module "cluster_node_script_deployment" {
  source = "./modules/vm-script-deployment"
  count  = var.should_deploy_script_to_vm && !var.should_deploy_arc_machines ? try(length(var.cluster_node_machine), 0) : 0

  depends_on = [module.cluster_server_script_deployment, module.ubuntu_k3s]

  extension_name = "linux-cluster-node-setup"
  machine_id     = try(var.cluster_node_machine[count.index].id, null)
  script_content = module.ubuntu_k3s.node_script_content

  // Key Vault script deployment parameters
  should_use_script_from_secrets_for_deploy = var.should_use_script_from_secrets_for_deploy
  kubernetes_distro                         = "k3s"
  node_type                                 = "node"
  secret_name_prefix                        = var.key_vault_script_secret_prefix
  key_vault                                 = var.key_vault
}

/*
 * Arc-Connected Server Extensions
 */

module "cluster_server_arc_script_deployment" {
  source = "./modules/arc-server-script-deployment"
  count  = var.should_deploy_arc_machines ? 1 : 0

  depends_on = [module.ubuntu_k3s]

  extension_name = "linux-cluster-server-setup"
  arc_machine_id = var.cluster_server_machine.id
  location       = var.cluster_server_machine.location
  script_content = module.ubuntu_k3s.server_script_content

  // Key Vault script deployment parameters
  should_use_script_from_secrets_for_deploy = var.should_use_script_from_secrets_for_deploy
  kubernetes_distro                         = "k3s"
  node_type                                 = "server"
  secret_name_prefix                        = var.key_vault_script_secret_prefix
  key_vault                                 = var.key_vault
}

module "cluster_node_arc_script_deployment" {
  source = "./modules/arc-server-script-deployment"
  count  = var.should_deploy_arc_machines ? try(length(var.cluster_node_machine), 0) : 0

  depends_on = [module.cluster_server_arc_script_deployment, module.ubuntu_k3s]

  extension_name = "linux-cluster-node-setup"
  arc_machine_id = var.cluster_node_machine[count.index].id
  location       = var.cluster_node_machine[count.index].location
  script_content = module.ubuntu_k3s.node_script_content

  // Key Vault script deployment parameters
  should_use_script_from_secrets_for_deploy = var.should_use_script_from_secrets_for_deploy
  kubernetes_distro                         = "k3s"
  node_type                                 = "node"
  secret_name_prefix                        = var.key_vault_script_secret_prefix
  key_vault                                 = var.key_vault
}
