<!-- BEGIN_TF_DOCS -->
# Azure IoT Enablement Module

Deploys resources necessary to enable Azure IoT Operations (AIO) and creates an AIO instance.

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

## Providers

The following providers are used by this module:

- azurerm

## Resources

The following resources are used by this module:

- [azurerm_arc_kubernetes_cluster_extension.container_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) (resource)
- [azurerm_arc_kubernetes_cluster_extension.open_service_mesh](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) (resource)
- [azurerm_arc_kubernetes_cluster_extension.platform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) (resource)
- [azurerm_arc_kubernetes_cluster_extension.secret_store](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) (resource)

## Required Inputs

The following input variables are required:

### aio\_platform\_config

Description: Install cert-manager and trust-manager extensions

Type:

```hcl
object({
    install_cert_manager  = bool
    install_trust_manager = bool
  })
```

### arc\_connected\_cluster\_id

Description: The resource ID of the connected cluster to deploy Azure IoT Operations Platform to

Type: `string`

### edge\_storage\_accelerator

Description: n/a

Type:

```hcl
object({
    version               = string
    train                 = string
    diskStorageClass      = string
    faultToleranceEnabled = bool
  })
```

### open\_service\_mesh

Description: n/a

Type:

```hcl
object({
    version = string
    train   = string
  })
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

### secret\_sync\_controller

Description: n/a

Type:

```hcl
object({
    version = string
    train   = string
  })
```

## Outputs

The following outputs are exported:

### platform\_cluster\_extension\_id

Description: n/a

### secret\_store\_extension\_cluster\_id

Description: n/a
<!-- END_TF_DOCS -->
