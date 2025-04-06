locals {
  aio_resource_group_name = coalesce(var.aio_resource_group_name, "rg-${var.resource_prefix}-${var.environment}-${var.instance}")
}

data "azurerm_user_assigned_identity" "arc" {
  count = var.arc_onboarding_identity_name != null ? 1 : 0

  name                = var.arc_onboarding_identity_name
  resource_group_name = local.aio_resource_group_name
}

module "edge_cncf_cluster" {
  source = "../../../src/100-edge/100-cncf-cluster/terraform"

  should_output_cluster_server_script = var.should_output_cluster_server_script
  should_output_cluster_node_script   = var.should_output_cluster_node_script
  should_deploy_script_to_vm          = false

  arc_onboarding_identity               = try(data.azurerm_user_assigned_identity.arc[0].principal_id, null)
  arc_onboarding_sp                     = var.arc_onboarding_sp
  environment                           = var.environment
  resource_prefix                       = var.resource_prefix
  resource_group                        = { name : local.aio_resource_group_name }
  cluster_server_host_machine_username  = var.cluster_server_host_machine_username
  custom_locations_oid                  = var.custom_locations_oid
  should_enable_arc_auto_upgrade        = var.enable_arc_auto_upgrade
  should_add_current_user_cluster_admin = var.should_add_current_user_cluster_admin
  should_assign_roles                   = var.should_assign_roles
  cluster_admin_oid                     = var.cluster_admin_oid
  script_output_filepath                = var.script_output_filepath
  should_get_custom_locations_oid       = var.should_get_custom_locations_oid
}
