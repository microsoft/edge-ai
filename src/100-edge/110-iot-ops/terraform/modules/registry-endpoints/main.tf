/**
 * # Registry Endpoints
 *
 * Manages container registry endpoints for Azure IoT Operations, including the default
 * MCR endpoint and custom registry endpoints with optional ACR role assignments.
 */

// Default MCR endpoint (always created)
resource "azapi_resource" "registry_endpoint_mcr" {
  type      = "Microsoft.IoTOperations/instances/registryEndpoints@2025-10-01"
  name      = "mcr"
  parent_id = var.aio_instance_id

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = {
      host = "mcr.microsoft.com"
      authentication = {
        method            = "Anonymous"
        anonymousSettings = {}
      }
    }
  }

  response_export_values    = ["name", "id"]
  schema_validation_enabled = false
}

// Custom registry endpoints
resource "azapi_resource" "registry_endpoint" {
  for_each  = { for endpoint in var.registry_endpoints : endpoint.name => endpoint }
  type      = "Microsoft.IoTOperations/instances/registryEndpoints@2025-10-01"
  name      = each.value.name
  parent_id = var.aio_instance_id

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = {
      host = each.value.host
      authentication = merge(
        { method = each.value.authentication.method },
        each.value.authentication.method == "SystemAssignedManagedIdentity" ? {
          systemAssignedManagedIdentitySettings = each.value.authentication.system_assigned_managed_identity_settings != null ? {
            audience = coalesce(each.value.authentication.system_assigned_managed_identity_settings.audience, "https://management.azure.com/")
            } : {
            audience = "https://management.azure.com/"
          }
        } : {},
        each.value.authentication.method == "UserAssignedManagedIdentity" ? {
          userAssignedManagedIdentitySettings = {
            clientId = each.value.authentication.user_assigned_managed_identity_settings.client_id
            tenantId = each.value.authentication.user_assigned_managed_identity_settings.tenant_id
            scope    = each.value.authentication.user_assigned_managed_identity_settings.scope
          }
        } : {},
        each.value.authentication.method == "ArtifactPullSecret" ? {
          artifactPullSecretSettings = {
            secretRef = each.value.authentication.artifact_pull_secret_settings.secret_ref
          }
        } : {},
        each.value.authentication.method == "Anonymous" ? {
          anonymousSettings = {}
        } : {}
      )
    }
  }

  response_export_values    = ["name", "id"]
  schema_validation_enabled = false
}

// ACR role assignments for SystemAssignedManagedIdentity endpoints with should_assign_acr_pull_for_aio enabled
resource "azurerm_role_assignment" "registry_acr_pull" {
  for_each = {
    for endpoint in var.registry_endpoints : endpoint.name => endpoint
    if endpoint.authentication.method == "SystemAssignedManagedIdentity" && endpoint.should_assign_acr_pull_for_aio
  }

  scope                            = each.value.acr_resource_id
  role_definition_name             = "AcrPull"
  principal_id                     = var.extension_principal_id
  skip_service_principal_aad_check = true
}
