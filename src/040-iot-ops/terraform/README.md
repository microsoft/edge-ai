<!-- BEGIN_TF_DOCS -->
# Azure IoT Operations

Sets up Azure IoT Operations in a connected cluster and includes
an resources or configuration that must be created before an IoT Operations
Instance can be created, and after.

## Requirements

The following requirements are needed by this module:

- terraform (>= 1.9.8, < 2.0)

- azapi (>= 2.1.0)

- azurerm (>= 4.8.0)

## Providers

The following providers are used by this module:

- azapi (>= 2.1.0)

- azurerm (>= 4.8.0)

- terraform

## Resources

The following resources are used by this module:

- [terraform_data.defer](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)
- [azapi_resource.schema_registry](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) (data source)
- [azurerm_key_vault.sse_key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) (data source)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) (data source)
- [azurerm_user_assigned_identity.sse_uami](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/user_assigned_identity) (data source)

## Modules

The following Modules are called:

### apply\_scripts\_post\_init

Source: ./modules/apply-scripts

Version:

### customer\_managed\_self\_signed\_ca

Source: ./modules/self-signed-ca

Version:

### customer\_managed\_trust\_issuer

Source: ./modules/customer-managed-trust-issuer

Version:

### iot\_ops\_init

Source: ./modules/iot-ops-init

Version:

### iot\_ops\_instance

Source: ./modules/iot-ops-instance

Version:

### iot\_ops\_instance\_post

Source: ./modules/iot-ops-instance-post

Version:

### opc\_ua\_simulator

Source: ./modules/opc-ua-simulator

Version:

## Required Inputs

The following input variables are required:

### environment

Description: Environment for all resources in this module: dev, test, or prod

Type: `string`

### location

Description: Location for all resources in this module

Type: `string`

### resource\_prefix

Description: Prefix for all resources in this module

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### aio\_ca

Description: CA certificate for the MQTT broker, can be either Root CA or Root CA with any number of Intermediate CAs. If not provided, a self-signed Root CA with a intermediate will be generated. Only valid when Trust Source is set to CustomerManaged

Type:

```hcl
object({
    root_ca_cert_pem  = string
    ca_cert_chain_pem = string
    ca_key_pem        = string
  })
```

Default: `null`

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

### byo\_issuer\_trust\_settings

Description: Settings for CustomerManagedByoIssuer (Bring Your Own Issuer) trust configuration

Type:

```hcl
object({
    issuer_name    = string
    issuer_kind    = string
    configmap_name = string
    configmap_key  = string
  })
```

Default: `null`

### connected\_cluster\_location

Description: The location of the connected cluster resource. (Otherwise, 'var.location')

Type: `string`

Default: `null`

### connected\_cluster\_name

Description: The name of the Azure Arc connected cluster resource for Azure IoT Operations. (Otherwise, '{var.resource\_prefix}-arc')

Type: `string`

Default: `null`

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

### enable\_opc\_ua\_simulator

Description: Deploy OPC UA Simulator to the cluster

Type: `bool`

Default: `false`

### enable\_otel\_collector

Description: Deploy the OpenTelemetry Collector and Azure Monitor ConfigMap (optionally used)

Type: `bool`

Default: `false`

### existing\_key\_vault\_name

Description: Name of the Azure Key Vault to use by Secret Sync Extension. If not provided, will create a new Key Vault. Will fail if Key Vault does not exist in provided resource group.

Type: `string`

Default: `null`

### instance

Description: Instance identifier for naming resources: 001, 002, etc...

Type: `string`

Default: `"001"`

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

### resource\_group\_name

Description: The name for the resource group. (Otherwise, 'rg-{var.resource\_prefix}-{var.environment}-{var.instance}')

Type: `string`

Default: `null`

### schema\_registry\_name

Description: The name of the Azure Device Registry Schema Registry resource. (Otherwise, '{var.resource\_prefix}-registry')

Type: `string`

Default: `null`

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

### sse\_uami\_name

Description: The name of the User Assigned Managed Identity that was federated for Secret Sync Extension. (Otherwise, '{var.resource\_prefix}-sse-umi'

Type: `string`

Default: `null`

### trust\_config\_source

Description: TrustConfig source must be one of 'SelfSigned', 'CustomerManagedByoIssuer' or 'CustomerManagedGenerateIssuer'. Defaults to SelfSigned. When choosing CustomerManagedGenerateIssuer, ensure connectedk8s proxy is enabled on the cluster for current user. When choosing CustomerManagedByoIssuer, ensure an Issuer and ConfigMap resources exist in the cluster.

Type: `string`

Default: `"SelfSigned"`

## Outputs

The following outputs are exported:

### aio\_extension\_name

Description: n/a

### aio\_instance\_name

Description: n/a

### custom\_location\_id

Description: n/a
<!-- END_TF_DOCS -->
