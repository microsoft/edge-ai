<!-- BEGIN_TF_DOCS -->
# Azure IoT Schema Registry Module

Deploys a storage account and schema registry to be used for Azure IoT Operations deployments

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

- azapi (2.1.0)

## Providers

The following providers are used by this module:

- azapi (2.1.0)

- azurerm

- random

## Resources

The following resources are used by this module:

- [azapi_resource.schema_registry](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) (resource)
- [azurerm_role_assignment.registry_storage_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_storage_account.schema_registry_store](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) (resource)
- [azurerm_storage_container.schema_container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) (resource)
- [random_string.name](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) (data source)

## Required Inputs

The following input variables are required:

### location

Description: Location for all resources in this module

Type: `string`

### resource\_group\_name

Description: Name of the pre-existing resource group in which to create resources

Type: `string`

### resource\_prefix

Description: Prefix for the registry and registry namespace created in this module

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### storage\_account

Description: Storage account name, tier and replication\_type for the Storage Account to be created. Defaults to a randomly generated name, "Standard" tier and "LRS" replication\_type

Type:

```hcl
object({
    name             = string
    tier             = string
    replication_type = string
  })
```

Default:

```json
{
  "name": "",
  "replication_type": "LRS",
  "tier": "Standard"
}
```

## Outputs

The following outputs are exported:

### registry\_id

Description: n/a
<!-- END_TF_DOCS -->