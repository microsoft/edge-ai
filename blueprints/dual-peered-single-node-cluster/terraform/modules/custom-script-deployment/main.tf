/**
 * # Custom Script Deployment Module (Refactored)
 *
 * This module handles deployment of custom scripts to VMs using Azure VM extensions.
 * Scripts are stored in separate files for better maintainability and readability.
 */

locals {
  # Generate scripts using templatefile() for clean separation of concerns
  enterprise_script = templatefile("${path.module}/../../../scripts/enterprise.sh", {
    synced_certificates_secret_name     = var.enterprise_synced_certificates_secret_name
    enterprise_client_ca_configmap_name = var.enterprise_client_ca_configmap_name
  })

  site_script = templatefile("${path.module}/../../../scripts/site.sh", {
    synced_certificates_secret_name = var.site_synced_certificates_secret_name
    site_tls_ca_configmap_name      = var.site_tls_ca_configmap_name
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
