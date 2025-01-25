<!-- BEGIN_TF_DOCS -->
# Azure IoT Instance post-installation enablement

Enables secret-sync on the Azure IoT instance after the instance is created.

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

- azapi (2.1.0)

## Providers

The following providers are used by this module:

- azapi (2.1.0)

- azurerm

## Resources

The following resources are used by this module:

- [azapi_resource.default_aio_keyvault_secret_provider_class](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) (resource)
- [azurerm_federated_identity_credential.federated_identity_cred_sse_aio](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential) (resource)
- [azapi_resource.cluster_oidc_issuer](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/data-sources/resource) (data source)
- [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) (data source)

## Required Inputs

The following input variables are required:

### aio\_namespace

Description: Azure IoT Operations namespace

Type: `string`

### connected\_cluster\_location

Description: The location of the connected cluster resource

Type: `string`

### connected\_cluster\_name

Description: The name of the connected cluster to deploy Azure IoT Operations to

Type: `string`

### custom\_location\_id

Description: The resource ID of the Custom Location.

Type: `string`

### enable\_instance\_secret\_sync

Description: Whether to enable secret sync on the Azure IoT Operations instance

Type: `bool`

### key\_vault

Description: The name and id of the existing key vault for Azure IoT Operations instance

Type:

```hcl
object({
    name = string
    id   = string
  })
```

### resource\_group

Description: Name and ID of the pre-existing resource group in which to create resources

Type:

```hcl
object({
    id   = string
    name = string
  })
```

### sse\_user\_managed\_identity

Description: Secret Sync Extension user managed identity id and client id

Type:

```hcl
object({
    id        = string
    client_id = string
  })
```
<!-- END_TF_DOCS -->
