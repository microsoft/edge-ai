<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure IoT Instance

Deploys an AIO instance.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | n/a |
| azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.aio_device_registry_sync_rule](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.aio_sync_rule](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.broker](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.broker_authn](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.broker_listener](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.custom_location](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.data_endpoint](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.data_profiles](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.instance](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_arc_kubernetes_cluster_extension.iot_operations](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/arc_kubernetes_cluster_extension) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_uami\_id | The principal ID of the User Assigned Managed Identity for the Azure IoT Operations instance | `string` | n/a | yes |
| arc\_connected\_cluster\_id | The resource ID of the connected cluster to deploy Azure IoT Operations Platform to | `string` | n/a | yes |
| connected\_cluster\_location | The location of the connected cluster resource | `string` | n/a | yes |
| connected\_cluster\_name | The name of the connected cluster to deploy Azure IoT Operations to | `string` | n/a | yes |
| customer\_managed\_trust\_settings | Values for AIO CustomerManaged trust resources | ```object({ issuer_name = string issuer_kind = string configmap_name = string configmap_key = string })``` | n/a | yes |
| dataflow\_instance\_count | Number of dataflow instances. Defaults to 1. | `number` | n/a | yes |
| deploy\_resource\_sync\_rules | Deploys resource sync rules if set to true | `bool` | n/a | yes |
| enable\_otel\_collector | Deploy the OpenTelemetry Collector and Azure Monitor ConfigMap (optionally used) | `bool` | n/a | yes |
| mqtt\_broker\_config | n/a | ```object({ brokerListenerServiceName = string brokerListenerPort = number serviceAccountAudience = string frontendReplicas = number frontendWorkers = number backendRedundancyFactor = number backendWorkers = number backendPartitions = number memoryProfile = string serviceType = string })``` | n/a | yes |
| operations\_config | n/a | ```object({ namespace = string kubernetesDistro = string version = string train = string agentOperationTimeoutInMinutes = number })``` | n/a | yes |
| platform\_cluster\_extension\_id | The resource ID of the AIO Platform cluster extension | `string` | n/a | yes |
| resource\_group\_id | The ID for the Resource Group for the resources. | `string` | n/a | yes |
| schema\_registry\_id | The resource ID of the schema registry for Azure IoT Operations instance | `string` | n/a | yes |
| secret\_store\_cluster\_extension\_id | The resource ID of the Secret Store cluster extension | `string` | n/a | yes |
| trust\_source | Trust source must be one of 'SelfSigned' or 'CustomerManaged'. Defaults to SelfSigned. | `string` | `"SelfSigned"` | no |

## Outputs

| Name | Description |
|------|-------------|
| aio\_dataflow\_profile | n/a |
| aio\_instance | n/a |
| custom\_location\_id | n/a |
| custom\_locations | n/a |
| instance\_name | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
