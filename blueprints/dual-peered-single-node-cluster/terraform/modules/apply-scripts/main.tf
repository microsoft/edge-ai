/**
 * # Apply Scripts
 *
 * Sets up an `az connectedk8s proxy`, if needed,  and then runs the corresponding
 * scripts passed into this module.

 * This module is a copy of the `apply-scripts` module from the 110-iot-ops module to quickly enable developers
 * to connect to the arc cluster via 110-iot-ops/scripts/init-scripts.sh and execute their custom scripts.
 */

data "azurerm_subscription" "current" {}

locals {
  local_script_path   = "${path.module}/../../.."
  init_script_path    = "${path.module}/../../../../../src/100-edge/110-iot-ops"
  source_start_proxy  = ["source ${local.init_script_path}/scripts/init-scripts.sh"]
  filename_site       = ["${local.local_script_path}/scripts/site.sh"]
  filename_enterprise = ["${local.local_script_path}/scripts/enterprise.sh"]

  base_env_vars_site = {
    TF_MODULE_PATH            = local.init_script_path
    TF_CONNECTED_CLUSTER_NAME = var.arc_connected_cluster_a.name
    TF_RESOURCE_GROUP_NAME    = var.cluster_a_resource_group.name
    TF_AIO_NAMESPACE          = var.aio_namespace
  }
  base_env_vars_enterprise = {
    TF_MODULE_PATH            = local.init_script_path
    TF_CONNECTED_CLUSTER_NAME = var.arc_connected_cluster_b.name
    TF_RESOURCE_GROUP_NAME    = var.cluster_b_resource_group.name
    TF_AIO_NAMESPACE          = var.aio_namespace
  }
  local_env_vars_site = {
    SYNCED_CERTIFICATES_SECRET_NAME = var.site_synced_certificates_secret_name
    SITE_TLS_CA_CONFIGMAP_NAME      = var.site_tls_ca_configmap_name
    TF_SSE_USER_ASSIGNED_CLIENT_ID  = var.cluster_a_secret_sync_identity.client_id
    TF_KEY_VAULT_NAME               = var.cluster_a_key_vault.name
    TF_AZURE_TENANT_ID              = data.azurerm_subscription.current.tenant_id
    TF_LOCAL_MODULE_PATH            = local.local_script_path
  }
  local_env_vars_enterprise = {
    SYNCED_CERTIFICATES_SECRET_NAME     = var.enterprise_synced_certificates_secret_name
    ENTERPRISE_CLIENT_CA_CONFIGMAP_NAME = var.enterprise_client_ca_configmap_name
    TF_SSE_USER_ASSIGNED_CLIENT_ID      = var.cluster_b_secret_sync_identity.client_id
    TF_KEY_VAULT_NAME                   = var.cluster_b_key_vault.name
    TF_AZURE_TENANT_ID                  = data.azurerm_subscription.current.tenant_id
    TF_LOCAL_MODULE_PATH                = local.local_script_path
  }

  env_vars_site       = merge(local.base_env_vars_site, local.local_env_vars_site)
  env_vars_enterprise = merge(local.base_env_vars_enterprise, local.local_env_vars_enterprise)
}

resource "terraform_data" "apply_scripts_site" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = join(" && ", concat(local.source_start_proxy, local.filename_site))
    environment = local.env_vars_site
  }
}

resource "terraform_data" "apply_scripts_enterprise" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = join(" && ", concat(local.source_start_proxy, local.filename_enterprise))
    environment = local.env_vars_enterprise
  }

  depends_on = [terraform_data.apply_scripts_site]
}
