<!-- BEGIN_TF_DOCS -->
# Azure IoT Instance

Deploys an AIO instance.

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
- [azurerm_arc_kubernetes_cluster_extension.iot_operations](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) (resource)

## Required Inputs

The following input variables are required:

### aio\_uami\_id

Description: The principal ID of the User Assigned Managed Identity for the Azure IoT Operations instance

Type: `string`

### arc\_connected\_cluster\_id

Description: The resource ID of the connected cluster to deploy Azure IoT Operations Platform to

Type: `string`

### connected\_cluster\_location

Description: The location of the connected cluster resource

Type: `string`

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

### dataflow\_instance\_count

Description: Number of dataflow instances. Defaults to 1.

Type: `number`

### deploy\_resource\_sync\_rules

Description: Deploys resource sync rules if set to true

Type: `bool`

### enable\_otel\_collector

Description: Deploy the OpenTelemetry Collector and Azure Monitor ConfigMap (optionally used)

Type: `bool`

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

### platform\_cluster\_extension\_id

Description: The resource ID of the AIO Platform cluster extension

Type: `string`

### resource\_group\_id

Description: ID of the resource group to create resources in

Type: `string`

### schema\_registry\_id

Description: The resource ID of the schema registry for Azure IoT Operations instance

Type: `string`

### secret\_store\_cluster\_extension\_id

Description: The resource ID of the Secret Store cluster extension

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### trust\_source

Description: Trust source must be one of 'SelfSigned' or 'CustomerManaged'. Defaults to SelfSigned.

Type: `string`

Default: `"SelfSigned"`

## Outputs

The following outputs are exported:

### custom\_location\_id

Description: n/a

### instance\_name

Description: n/a
<!-- END_TF_DOCS -->
