/**
 * # CNCF Cluster
 *
 * Sets up and deploys a script to a VM host that will setup the cluster,
 * Arc connect the cluster, Add cluster admins to the cluster, enable workload identity,
 * install extensions for cluster connect and custom locations.
 */

locals {
  arc_resource_name    = "arc-${var.resource_prefix}-${var.environment}-${var.instance}"
  custom_locations_oid = try(coalesce(var.custom_locations_oid), data.azuread_service_principal.custom_locations[0].object_id, "")
  current_user_oid     = var.should_add_current_user_cluster_admin ? data.azurerm_client_config.current.object_id : null
  env_var = {
    ENVIRONMENT             = var.environment
    ARC_RESOURCE_GROUP_NAME = var.aio_resource_group.name
    ARC_RESOURCE_NAME       = local.arc_resource_name

    K3S_VERSION          = "$${K3S_VERSION}"
    CLUSTER_ADMIN_OID    = try(coalesce(var.cluster_admin_oid, local.current_user_oid), "$${CLUSTER_ADMIN_OID}")
    ARC_AUTO_UPGRADE     = coalesce(var.enable_arc_auto_upgrade, lower(var.environment) != "prod")
    ARC_SP_CLIENT_ID     = try(coalesce(var.arc_onboarding_sp_client_id), "$${ARC_SP_CLIENT_ID}")
    ARC_SP_SECRET        = try(coalesce(var.arc_onboarding_sp_client_secret), "$${ARC_SP_SECRET}")
    ARC_TENANT_ID        = data.azurerm_client_config.current.tenant_id
    AZ_CLI_VER           = "$${AZ_CLI_VER}"
    AZ_CONNECTEDK8S_VER  = "$${AZ_CONNECTEDK8S_VER}"
    CUSTOM_LOCATIONS_OID = local.custom_locations_oid
    DEVICE_USERNAME      = coalesce(var.vm_username, var.resource_prefix)
    SKIP_INSTALL_AZ_CLI  = "$${SKIP_INSTALL_AZ_CLI}"
    SKIP_AZ_LOGIN        = "$${SKIP_AZ_LOGIN}"
    SKIP_INSTALL_K3S     = "$${SKIP_INSTALL_K3S}"
    SKIP_INSTALL_KUBECTL = "$${SKIP_INSTALL_KUBECTL}"
    SKIP_ARC_CONNECT     = "$${SKIP_ARC_CONNECT}"
  }

  # Read in script file and remove any carriage returns then split on separator in file '###\n' for parameters.
  script_file = split("###\n", replace(file("${path.module}/../scripts/k3s-device-setup.sh"), "\r", ""))
  # Apply Terraform templated variables to the parameters part of the script file.
  script_parameters = templatestring(local.script_file[0], local.env_var)
  # Join the script back together with the rendered parameters along with the rest of the file.
  script_rendered = join("###\n", concat([local.script_parameters], slice(local.script_file, 1, length(local.script_file))))
}

data "azurerm_client_config" "current" {
}

data "azuread_service_principal" "custom_locations" {
  count = var.custom_locations_oid == null ? 1 : 0

  # ref: https://learn.microsoft.com/en-us/azure/iot-operations/deploy-iot-ops/howto-prepare-cluster?tabs=ubuntu#arc-enable-your-cluster
  client_id = "bc313c14-388c-4e7d-a58e-70017303ee3b" #gitleaks:allow
}

resource "local_sensitive_file" "k3s_device_setup_script" {
  count = var.should_output_script ? 1 : 0

  filename        = coalesce(var.script_output_filepath, "${path.root}/out/k3s-device-setup.sh")
  content         = local.script_rendered
  file_permission = "755"
}

resource "azurerm_virtual_machine_extension" "linux_setup" {
  count = var.should_deploy_script_to_vm ? 1 : 0

  name                        = "linux-vm-setup"
  virtual_machine_id          = var.aio_virtual_machine.id
  publisher                   = "Microsoft.Azure.Extensions"
  type                        = "CustomScript"
  type_handler_version        = "2.1"
  automatic_upgrade_enabled   = false
  auto_upgrade_minor_version  = false
  failure_suppression_enabled = false
  protected_settings          = <<SETTINGS
  {
    "script": "${base64encode(local.script_rendered)}"
  }
  SETTINGS
}

data "azapi_resource" "arc_connected_cluster" {
  count = var.should_deploy_script_to_vm ? 1 : 0

  type      = "Microsoft.Kubernetes/connectedClusters@2024-01-01"
  parent_id = var.aio_resource_group.id
  name      = "arc-${var.resource_prefix}-${var.environment}-${var.instance}"

  depends_on = [azurerm_virtual_machine_extension.linux_setup]

  response_export_values = ["name", "id", "location", "properties.oidcIssuerProfile.issuerUrl"]
}
