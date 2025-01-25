<!-- BEGIN_TF_DOCS -->
# Azure IoT Operations Customer Managed trust

Deploys resources necessary to enable Azure IoT Operations (AIO) with Customer Managed trust.

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

- [azurerm_federated_identity_credential.federated_identity_cred_sse_cert_manager](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential) (resource)
- [azurerm_key_vault_secret.aio_ca_cert_chain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_key_vault_secret.aio_ca_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_key_vault_secret.aio_root_ca_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azapi_resource.cluster_oidc_issuer](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/data-sources/resource) (data source)
- [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) (data source)

## Required Inputs

The following input variables are required:

### aio\_ca

Description: Intermediate CA with Root CA certificate for the MQTT broker

Type:

```hcl
object({
    root_ca_cert_pem  = string
    ca_cert_chain_pem = string
    ca_key_pem        = string
  })
```

### connected\_cluster\_name

Description: The name of the connected cluster to deploy Azure IoT Operations to

Type: `string`

### customer\_managed\_trust\_settings

Description: Values for AIO CustomerManaged trust resources

Type:

```hcl
object({
    issuer_name    = string
    issuer_kind    = string
    configmap_name = string
    configmap_key  = string
  })
```

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

## Outputs

The following outputs are exported:

### scripts

Description: n/a
<!-- END_TF_DOCS -->
