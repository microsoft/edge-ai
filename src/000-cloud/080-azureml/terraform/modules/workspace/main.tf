/*
 * # Azure Machine Learning Workspace Module
 *
 * This module creates an Azure ML workspace with required dependencies
 * and optional private endpoint configuration.
 */

// Local variables for resource naming following Azure conventions
locals {
  workspace_name = coalesce(var.name, "mlw-${var.resource_prefix}-${var.environment}-${var.instance}")
}

/*
 * Role Assignments (Current User - Storage Scope)
 */

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  count = var.should_assign_current_user_workspace_roles ? 1 : 0

  principal_id         = var.current_user_object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = var.storage_account_id
}

/*
 * Azure Machine Learning Workspace
 */

resource "azurerm_machine_learning_workspace" "this" {
  depends_on = [azurerm_role_assignment.storage_blob_data_contributor]

  name                          = local.workspace_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  application_insights_id       = var.application_insights_id
  key_vault_id                  = var.key_vault_id
  storage_account_id            = var.storage_account_id
  container_registry_id         = var.container_registry_id
  public_network_access_enabled = var.public_network_access_enabled
  description                   = var.description
  friendly_name                 = var.friendly_name

  identity {
    type = "SystemAssigned"
  }
}

/*
 * Role Assignments (Current User - Workspace Scope)
 */

resource "azurerm_role_assignment" "workspace_contributor" {
  count = var.should_assign_current_user_workspace_roles ? 1 : 0

  principal_id         = var.current_user_object_id
  role_definition_name = "Contributor"
  scope                = azurerm_machine_learning_workspace.this.id
}

/*
 * Role Assignments (Workspace System-Assigned Managed Identity)
 */

// Storage Account - Contributor (control plane)
resource "azurerm_role_assignment" "workspace_storage_contributor" {
  count = var.should_assign_workspace_managed_identity_roles ? 1 : 0

  principal_id         = azurerm_machine_learning_workspace.this.identity[0].principal_id
  role_definition_name = "Contributor"
  scope                = var.storage_account_id
}

// Storage Account - Storage Blob Data Contributor (data plane)
resource "azurerm_role_assignment" "workspace_storage_blob_data_contributor" {
  count = var.should_assign_workspace_managed_identity_roles ? 1 : 0

  principal_id         = azurerm_machine_learning_workspace.this.identity[0].principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = var.storage_account_id
}

// Azure Container Registry - Contributor
resource "azurerm_role_assignment" "workspace_acr_contributor" {
  count = var.should_assign_workspace_managed_identity_roles ? 1 : 0

  principal_id         = azurerm_machine_learning_workspace.this.identity[0].principal_id
  role_definition_name = "Contributor"
  scope                = var.container_registry_id
}

// Key Vault - Contributor (control plane)
resource "azurerm_role_assignment" "workspace_keyvault_contributor" {
  count = var.should_assign_workspace_managed_identity_roles ? 1 : 0

  principal_id         = azurerm_machine_learning_workspace.this.identity[0].principal_id
  role_definition_name = "Contributor"
  scope                = var.key_vault_id
}

// Key Vault - Key Vault Administrator (data plane for RBAC permission model)
resource "azurerm_role_assignment" "workspace_keyvault_administrator" {
  count = var.should_assign_workspace_managed_identity_roles ? 1 : 0

  principal_id         = azurerm_machine_learning_workspace.this.identity[0].principal_id
  role_definition_name = "Key Vault Administrator"
  scope                = var.key_vault_id
}

// Application Insights - Contributor
resource "azurerm_role_assignment" "workspace_appinsights_contributor" {
  count = var.should_assign_workspace_managed_identity_roles ? 1 : 0

  principal_id         = azurerm_machine_learning_workspace.this.identity[0].principal_id
  role_definition_name = "Contributor"
  scope                = var.application_insights_id
}

/*
 * Role Assignments (Workload Managed Identity)
 */

resource "azurerm_role_assignment" "ml_workload_key_vault_user" {
  count = var.should_assign_ml_workload_identity_roles ? 1 : 0

  principal_id                     = var.ml_workload_identity.principal_id
  role_definition_name             = "Key Vault Secrets User"
  scope                            = var.key_vault_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "ml_workload_blob_contributor" {
  count = var.should_assign_ml_workload_identity_roles ? 1 : 0

  principal_id                     = var.ml_workload_identity.principal_id
  role_definition_name             = "Storage Blob Data Contributor"
  scope                            = var.storage_account_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "ml_workload_file_contributor" {
  count = var.should_assign_ml_workload_identity_roles ? 1 : 0

  principal_id                     = var.ml_workload_identity.principal_id
  role_definition_name             = "Storage File Data SMB Share Contributor"
  scope                            = var.storage_account_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "ml_workload_acr_pull" {
  count = var.should_assign_ml_workload_identity_roles ? 1 : 0

  principal_id                     = var.ml_workload_identity.principal_id
  role_definition_name             = "AcrPull"
  scope                            = var.container_registry_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "ml_workload_workspace_contributor" {
  count = var.should_assign_ml_workload_identity_roles ? 1 : 0

  principal_id                     = var.ml_workload_identity.principal_id
  role_definition_name             = "Contributor"
  scope                            = azurerm_machine_learning_workspace.this.id
  skip_service_principal_aad_check = true
  depends_on                       = [azurerm_machine_learning_workspace.this]
}

/*
 * Private Endpoint for Azure ML Workspace
 */

resource "azurerm_private_endpoint" "azureml_pe" {
  count = var.should_enable_private_endpoint ? 1 : 0

  name                = "pe-${azurerm_machine_learning_workspace.this.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "azureml-privatelink"
    private_connection_resource_id = azurerm_machine_learning_workspace.this.id
    is_manual_connection           = false
    subresource_names              = ["amlworkspace"]
  }

  private_dns_zone_group {
    name                 = "azureml-dns-zone-group"
    private_dns_zone_ids = [for zone in azurerm_private_dns_zone.azureml_zones : zone.id]
  }

  depends_on = [azurerm_private_dns_zone.azureml_zones]
}

// Private DNS zones for Azure ML workspace private endpoint
// Only create the two required zones per Microsoft documentation
locals {
  azureml_dns_zones = var.should_enable_private_endpoint ? [
    "privatelink.api.azureml.ms",
    "privatelink.notebooks.azure.net"
  ] : []
}

resource "azurerm_private_dns_zone" "azureml_zones" {
  for_each = toset(local.azureml_dns_zones)

  name                = each.value
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "azureml_vnet_links" {
  for_each = toset(local.azureml_dns_zones)

  name                  = "vnet-link-${replace(each.key, ".", "-")}-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.azureml_zones[each.key].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}
