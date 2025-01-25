/**
 * # CNCF Cluster
 *
 * Sets up and deploys a script to a VM host that will setup the cluster,
 * Arc connect the cluster, Add cluster admins to the cluster, enable workload identity,
 * install extensions for cluster connect and custom locations.
 */

locals {
  arc_resource_name    = "${var.resource_prefix}-arc"
  custom_locations_oid = try(coalesce(var.custom_locations_oid), data.azuread_service_principal.custom_locations[0].object_id, "")
}

# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name = coalesce(
      var.resource_group_name,
      "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    )
  }
}

data "azurerm_client_config" "current" {}

data "azuread_service_principal" "custom_locations" {
  count = var.custom_locations_oid == null ? 1 : 0

  # ref: https://learn.microsoft.com/en-us/azure/iot-operations/deploy-iot-ops/howto-prepare-cluster?tabs=ubuntu#arc-enable-your-cluster
  client_id = "bc313c14-388c-4e7d-a58e-70017303ee3b" #gitleaks:allow
}

data "azurerm_resource_group" "this" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_virtual_machine" "this" {
  name                = coalesce(var.linux_virtual_machine_name, "${var.resource_prefix}-aio-edge-vm")
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_virtual_machine_extension" "linux_setup" {
  name                        = "linux-vm-setup"
  virtual_machine_id          = data.azurerm_virtual_machine.this.id
  publisher                   = "Microsoft.Azure.Extensions"
  type                        = "CustomScript"
  type_handler_version        = "2.1"
  automatic_upgrade_enabled   = false
  auto_upgrade_minor_version  = false
  failure_suppression_enabled = false
  protected_settings = <<SETTINGS
  {
    "script": "${base64encode(templatefile("${path.root}/../scripts/device-setup.sh", {
  "ENV_HOST_USERNAME"             = coalesce(var.vm_username, var.resource_prefix)
  "ENV_ARC_RESOURCE_GROUP"        = data.azurerm_resource_group.this.name
  "ENV_ARC_RESOURCE_NAME"         = local.arc_resource_name
  "ENV_CUSTOM_LOCATIONS_OID"      = local.custom_locations_oid
  "ENV_ENVIRONMENT"               = var.environment
  "ENV_ARC_AUTO_UPGRADE"          = var.arc_auto_upgrade
  "ENV_ADD_USER_AS_CLUSTER_ADMIN" = var.add_current_entra_user_cluster_admin
  "ENV_AAD_USER_ID"               = try(coalesce(data.azurerm_client_config.current.object_id), "")
  "ENV_ARC_SP_CLIENT_ID"          = try(coalesce(var.arc_onboarding_sp_client_id), "")
  "ENV_ARC_SP_SECRET"             = try(coalesce(var.arc_onboarding_sp_client_secret), "")
  "ENV_TENANT_ID"                 = data.azurerm_client_config.current.tenant_id
}))}"
  }
  SETTINGS
}
