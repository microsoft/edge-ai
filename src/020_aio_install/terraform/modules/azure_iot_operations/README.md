<!-- BEGIN_TF_DOCS -->
# Azure IoT Operations Module

Deploys resources necessary to enable Azure IoT Operations (AIO) and creates an AIO instance.

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

- azapi (2.1.0)

## Providers

The following providers are used by this module:

- azurerm

## Resources

The following resources are used by this module:

- [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) (data source)

## Required Inputs

The following input variables are required:

### aio\_root\_ca

Description: Root CA for the MQTT broker

Type:

```hcl
object({
    cert_pem        = string
    private_key_pem = string
  })
```

### connected\_cluster\_location

Description: The location of the connected cluster resource

Type: `string`

### connected\_cluster\_name

Description: The name of the connected cluster to deploy Azure IoT Operations to

Type: `string`

### key\_vault\_name

Description: The name of the existing key vault for Azure IoT Operations instance

Type: `string`

### resource\_group\_name

Description: Name of the pre-existing resource group in which to create resources

Type: `string`

### schema\_registry\_id

Description: The resource ID of the schema registry for Azure IoT Operations instance

Type: `string`

### sse\_user\_managed\_identity\_name

Description: Secret Sync Extension user managed identity name

Type: `string`

### trust\_config

Description: TrustConfig must be one of 'SelfSigned' or 'CustomerManaged'. Defaults to SelfSigned.

Type:

```hcl
object({
    source = string
  })
```

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

### enable\_instance\_secret\_sync

Description: Enable secret sync at the AIO instance level

Type: `bool`

Default: `true`

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

<!-- END_TF_DOCS -->