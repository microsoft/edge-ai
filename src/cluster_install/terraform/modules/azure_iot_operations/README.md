<!-- BEGIN_TF_DOCS -->
# Azure IoT Module

Deploys resources necessary to enable Azure IoT Operations (AIO) and creates an AIO instance.

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

- [azapi_resource.aio_device_registry_sync_rule](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) (resource)
- [azapi_resource.aio_sync_rule](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) (resource)
- [azapi_resource.broker](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) (resource)
- [azapi_resource.broker_authn](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) (resource)
- [azapi_resource.broker_listener](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) (resource)
- [azapi_resource.custom_location](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) (resource)
- [azapi_resource.data_endpoint](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) (resource)
- [azapi_resource.data_profiles](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) (resource)
- [azapi_resource.instance](https://registry.terraform.io/providers/Azure/azapi/2.1.0/docs/resources/resource) (resource)
- [azurerm_arc_kubernetes_cluster_extension.container_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) (resource)
- [azurerm_arc_kubernetes_cluster_extension.iot_operations](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) (resource)
- [azurerm_arc_kubernetes_cluster_extension.open_service_mesh](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) (resource)
- [azurerm_arc_kubernetes_cluster_extension.platform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) (resource)
- [azurerm_arc_kubernetes_cluster_extension.secret_store](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) (resource)
- [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) (data source)

## Required Inputs

The following input variables are required:

### connected\_cluster\_location

Description: The location of the connected cluster resource

Type: `string`

### connected\_cluster\_name

Description: The name of the connected cluster to deploy Azure IoT Operations to

Type: `string`

### resource\_group\_name

Description: Name of the pre-existing resource group in which to create resources

Type: `string`

### schema\_registry\_id

Description: The resource ID of the schema registry for Azure IoT Operations instance

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### dataflow\_instance\_count

Description: Number of dataflow instances. Defaults to 1.

Type: `number`

Default: `1`

### deploy\_resource\_sync\_rules

Description: Deploys resource sync rules if set to true

Type: `bool`

Default: `false`

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

Default:

```json
{
  "diskStorageClass": "",
  "faultToleranceEnabled": false,
  "train": "stable",
  "version": "2.2.2"
}
```

### metrics

Description: n/a

Type:

```hcl
object({
    enabled               = bool
    otelCollectorAddress  = string
    exportIntervalSeconds = number
  })
```

Default:

```json
{
  "enabled": false,
  "exportIntervalSeconds": 60,
  "otelCollectorAddress": ""
}
```

### mqtt\_broker\_config

Description: n/a

Type:

```hcl
object({
    brokerListenerServiceName = string
    brokerListenerPort        = number
    serviceAccountAudience    = string
    frontendReplicas          = number
    frontendWorkers           = number
    backendRedundancyFactor   = number
    backendWorkers            = number
    backendPartitions         = number
    memoryProfile             = string
    serviceType               = string
  })
```

Default:

```json
{
  "backendPartitions": 1,
  "backendRedundancyFactor": 2,
  "backendWorkers": 1,
  "brokerListenerPort": 18883,
  "brokerListenerServiceName": "aio-broker",
  "frontendReplicas": 1,
  "frontendWorkers": 1,
  "memoryProfile": "Low",
  "serviceAccountAudience": "aio-internal",
  "serviceType": "ClusterIp"
}
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

Default:

```json
{
  "train": "stable",
  "version": "1.2.10"
}
```

### operations\_config

Description: n/a

Type:

```hcl
object({
    namespace                      = string
    kubernetesDistro               = string
    version                        = string
    train                          = string
    agentOperationTimeoutInMinutes = number
  })
```

Default:

```json
{
  "agentOperationTimeoutInMinutes": 120,
  "kubernetesDistro": "K3s",
  "namespace": "azure-iot-operations",
  "train": "stable",
  "version": "1.0.9"
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

### secret\_sync\_controller

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
  "version": "0.6.7"
}
```

### trust\_config

Description: TrustConfig must be one of 'SelfSigned' or 'CustomerManaged'. Defaults to SelfSigned.

Type:

```hcl
object({
    source = string
    settings = optional(object({
      issuerName    = string
      issuerKind    = string
      configMapName = string
      configMapKey  = string
    }))
  })
```

Default:

```json
{
  "source": "SelfSigned"
}
```

<!-- END_TF_DOCS -->