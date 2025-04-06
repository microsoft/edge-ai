/**
 * # Apply Scripts
 *
 * Sets up an `az connectedk8s proxy`, if needed,  and then runs the corresponding
 * scripts passed into this module.
 */

locals {
  script_path        = "${path.module}/../../.."
  source_start_proxy = ["source ${local.script_path}/scripts/init-scripts.sh"]
  files              = distinct(concat(var.scripts[*].files...))
  formatted_files    = formatlist("${local.script_path}/scripts/%s", local.files)

  base_env_vars = {
    TF_MODULE_PATH            = local.script_path
    TF_CONNECTED_CLUSTER_NAME = var.connected_cluster_name
    TF_RESOURCE_GROUP_NAME    = var.resource_group_name
    TF_AIO_NAMESPACE          = var.aio_namespace
  }
  env_vars = merge(local.base_env_vars, var.scripts[*].environment...)
}

resource "terraform_data" "apply_scripts" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = join(" && ", concat(local.source_start_proxy, local.formatted_files))
    environment = local.env_vars
  }
}
