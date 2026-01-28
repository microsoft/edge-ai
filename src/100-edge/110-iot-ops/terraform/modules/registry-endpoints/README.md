<!-- BEGIN_TF_DOCS -->
# Registry Endpoints

Manages container registry endpoints for Azure IoT Operations, including the default
MCR endpoint and custom registry endpoints with optional ACR role assignments.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| azapi     | >= 2.0          |
| azurerm   | >= 4.0          |

## Providers

| Name    | Version |
|---------|---------|
| azapi   | >= 2.0  |
| azurerm | >= 4.0  |

## Resources

| Name                                                                                                                                         | Type     |
|----------------------------------------------------------------------------------------------------------------------------------------------|----------|
| [azapi_resource.registry_endpoint](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource)                       | resource |
| [azapi_resource.registry_endpoint_mcr](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource)                   | resource |
| [azurerm_role_assignment.registry_acr_pull](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |

## Inputs

| Name                     | Description                                                                               | Type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | Default | Required |
|--------------------------|-------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|:--------:|
| aio\_instance\_id        | Azure IoT Operations instance ID (parent for registry endpoints)                          | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | n/a     |   yes    |
| custom\_location\_id     | Custom location ID for the Azure IoT Operations deployment                                | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | n/a     |   yes    |
| extension\_principal\_id | Principal ID of the AIO Arc extension's system-assigned identity for ACR role assignments | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | n/a     |   yes    |
| registry\_endpoints      | List of custom registry endpoints to configure.                                           | ```list(object({ name = string host = string acr_resource_id = optional(string) should_assign_acr_pull_for_aio = optional(bool, false) authentication = object({ method = string system_assigned_managed_identity_settings = optional(object({ audience = optional(string, "https://management.azure.com/") })) user_assigned_managed_identity_settings = optional(object({ client_id = string tenant_id = string scope = optional(string) })) artifact_pull_secret_settings = optional(object({ secret_ref = string })) }) }))``` | n/a     |   yes    |

## Outputs

| Name                   | Description                                     |
|------------------------|-------------------------------------------------|
| acr\_role\_assignments | Map of ACR role assignment IDs by endpoint name |
| custom\_endpoints      | Map of custom registry endpoints by name        |
| mcr\_endpoint          | Default MCR registry endpoint                   |
<!-- END_TF_DOCS -->
