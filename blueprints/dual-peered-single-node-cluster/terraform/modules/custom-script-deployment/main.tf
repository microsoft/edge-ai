/**
 * # Custom Script Deployment Module (Refactored)
 *
 * This module handles deployment of custom scripts to VMs using Azure VM extensions.
 * Scripts are stored in separate files for better maintainability and readability.
 */

data "azurerm_subscription" "current" {}

locals {
  script_path = "${path.module}/../../.."

  # Generate scripts using templatefile() for clean separation of concerns
  enterprise_script = templatefile("${local.script_path}/scripts/enterprise.sh", {
    synced_certificates_secret_name     = var.enterprise_synced_certificates_secret_name
    enterprise_client_ca_configmap_name = var.enterprise_client_ca_configmap_name
    cluster_name                        = var.cluster_b_name
    tf_sse_user_assigned_client_id      = var.cluster_b_secret_sync_identity.client_id
    tf_key_vault_name                   = var.cluster_b_key_vault.name
    tf_azure_tenant_id                  = data.azurerm_subscription.current.tenant_id
    tf_module_path                      = local.script_path
  })

  site_script = templatefile("${local.script_path}/scripts/site.sh", {
    synced_certificates_secret_name = var.site_synced_certificates_secret_name
    site_tls_ca_configmap_name      = var.site_tls_ca_configmap_name
    cluster_name                    = var.cluster_a_name
    tf_sse_user_assigned_client_id  = var.cluster_a_secret_sync_identity.client_id
    tf_key_vault_name               = var.cluster_a_key_vault.name
    tf_azure_tenant_id              = data.azurerm_subscription.current.tenant_id
    tf_module_path                  = local.script_path
  })
}

// Deploy enterprise script to VM via Custom Script Extension
resource "azurerm_virtual_machine_extension" "enterprise_deployment" {
  count = var.should_deploy_server_central_script ? 1 : 0

  name                        = "enterprise-script-deployment"
  virtual_machine_id          = var.server_vm_id
  publisher                   = "Microsoft.Azure.Extensions"
  type                        = "CustomScript"
  type_handler_version        = "2.1"
  automatic_upgrade_enabled   = false
  auto_upgrade_minor_version  = false
  failure_suppression_enabled = false

  protected_settings = jsonencode({
    script = base64encode(local.enterprise_script)
  })
}

// Deploy site script to VM via Custom Script Extension
resource "azurerm_virtual_machine_extension" "site_deployment" {
  count = var.should_deploy_client_technology_script ? 1 : 0

  name                        = "site-script-deployment"
  virtual_machine_id          = var.client_vm_id
  publisher                   = "Microsoft.Azure.Extensions"
  type                        = "CustomScript"
  type_handler_version        = "2.1"
  automatic_upgrade_enabled   = false
  auto_upgrade_minor_version  = false
  failure_suppression_enabled = false

  protected_settings = jsonencode({
    script = base64encode(local.site_script)
  })
}
