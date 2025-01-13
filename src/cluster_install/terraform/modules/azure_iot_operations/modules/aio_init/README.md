<!-- BEGIN_TF_DOCS -->
# Azure IoT Module

Deploys resources necessary to enable Azure IoT Operations (AIO) and creates an AIO instance.

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

## Providers

The following providers are used by this module:

- azurerm

## Resources

The following resources are used by this module:

- [azurerm_arc_kubernetes_cluster_extension.platform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) (resource)

## Required Inputs

The following input variables are required:

### arc\_connected\_cluster\_id

Description: The resource ID of the connected cluster to deploy Azure IoT Operations Platform to

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### aio\_platform\_config

Description: Install cert-manager and trust-manager extensions

Type:

```hcl
object({
    install_cert_manager  = bool
    install_trust_manager = bool
  })
```

Default:

```json
{
  "install_cert_manager": true,
  "install_trust_manager": true
}
```

### platform

Description: n/a

Type:

```hcl
object({
    version = string
    train   = string
  })
```

Default:

```json
{
  "train": "preview",
  "version": "0.7.6"
}
```

<!-- END_TF_DOCS -->