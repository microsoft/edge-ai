locals {
  aio_resource_group_name = coalesce(var.aio_resource_group_name, "rg-${var.resource_prefix}-${var.environment}-${var.instance}")

}

module "cncf_cluster_install" {
  source = "../../../src/020-cncf-cluster/terraform"

  should_output_cluster_server_script = var.should_output_cluster_server_script
  should_output_cluster_node_script   = var.should_output_cluster_node_script

  environment                           = var.environment
  resource_prefix                       = var.resource_prefix
  aio_resource_group                    = { name : local.aio_resource_group_name }
  cluster_server_host_machine_username  = var.cluster_server_host_machine_username
  custom_locations_oid                  = var.custom_locations_oid
  should_enable_arc_auto_upgrade        = var.enable_arc_auto_upgrade
  should_add_current_user_cluster_admin = var.should_add_current_user_cluster_admin
  cluster_admin_oid                     = var.cluster_admin_oid
  script_output_filepath                = var.script_output_filepath
}
