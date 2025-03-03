<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Azure IoT Operations

Sets up Azure IoT Operations in a connected cluster and includes
an resources or configuration that must be created before an IoT Operations
Instance can be created, and after.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.2.0 |
| azurerm | >= 4.8.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| apply\_scripts\_post\_init | ./modules/apply-scripts | n/a |
| customer\_managed\_self\_signed\_ca | ./modules/self-signed-ca | n/a |
| customer\_managed\_trust\_issuer | ./modules/customer-managed-trust-issuer | n/a |
| iot\_ops\_init | ./modules/iot-ops-init | n/a |
| iot\_ops\_instance | ./modules/iot-ops-instance | n/a |
| iot\_ops\_instance\_post | ./modules/iot-ops-instance-post | n/a |
| opc\_ua\_simulator | ./modules/opc-ua-simulator | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| adr\_schema\_registry | n/a | ```object({ id = string })``` | n/a | yes |
| aio\_resource\_group | n/a | ```object({ name = string id = string location = string })``` | n/a | yes |
| aio\_user\_assigned\_identity | n/a | ```object({ id = string })``` | n/a | yes |
| arc\_connected\_cluster | n/a | ```object({ name = string id = string location = string })``` | n/a | yes |
| sse\_key\_vault | Azure Key Vault ID to use with Secret Sync Extension. | ```object({ name = string id = string })``` | n/a | yes |
| sse\_user\_assigned\_identity | n/a | ```object({ id = string client_id = string })``` | n/a | yes |
| aio\_ca | CA certificate for the MQTT broker, can be either Root CA or Root CA with any number of Intermediate CAs. If not provided, a self-signed Root CA with a intermediate will be generated. Only valid when Trust Source is set to CustomerManaged | ```object({ root_ca_cert_pem = string ca_cert_chain_pem = string ca_key_pem = string })``` | `null` | no |
| aio\_platform\_config | Install cert-manager and trust-manager extensions | ```object({ install_cert_manager = bool install_trust_manager = bool })``` | ```{ "install_cert_manager": true, "install_trust_manager": true }``` | no |
| byo\_issuer\_trust\_settings | Settings for CustomerManagedByoIssuer (Bring Your Own Issuer) trust configuration | ```object({ issuer_name = string issuer_kind = string configmap_name = string configmap_key = string })``` | `null` | no |
| dataflow\_instance\_count | Number of dataflow instances. Defaults to 1. | `number` | `1` | no |
| deploy\_resource\_sync\_rules | Deploys resource sync rules if set to true | `bool` | `false` | no |
| edge\_storage\_accelerator | n/a | ```object({ version = string train = string diskStorageClass = string faultToleranceEnabled = bool })``` | ```{ "diskStorageClass": "", "faultToleranceEnabled": false, "train": "stable", "version": "2.2.2" }``` | no |
| enable\_instance\_secret\_sync | Whether to enable secret sync on the Azure IoT Operations instance | `bool` | `true` | no |
| enable\_opc\_ua\_simulator | Deploy OPC UA Simulator to the cluster | `bool` | `true` | no |
| enable\_otel\_collector | Deploy the OpenTelemetry Collector and Azure Monitor ConfigMap (optionally used) | `bool` | `true` | no |
| mqtt\_broker\_config | n/a | ```object({ brokerListenerServiceName = string brokerListenerPort = number serviceAccountAudience = string frontendReplicas = number frontendWorkers = number backendRedundancyFactor = number backendWorkers = number backendPartitions = number memoryProfile = string serviceType = string })``` | ```{ "backendPartitions": 1, "backendRedundancyFactor": 2, "backendWorkers": 1, "brokerListenerPort": 18883, "brokerListenerServiceName": "aio-broker", "frontendReplicas": 1, "frontendWorkers": 1, "memoryProfile": "Low", "serviceAccountAudience": "aio-internal", "serviceType": "ClusterIp" }``` | no |
| open\_service\_mesh | n/a | ```object({ version = string train = string })``` | ```{ "train": "stable", "version": "1.2.10" }``` | no |
| operations\_config | n/a | ```object({ namespace = string kubernetesDistro = string version = string train = string agentOperationTimeoutInMinutes = number })``` | ```{ "agentOperationTimeoutInMinutes": 120, "kubernetesDistro": "K3s", "namespace": "azure-iot-operations", "train": "stable", "version": "1.0.9" }``` | no |
| platform | n/a | ```object({ version = string train = string })``` | ```{ "train": "preview", "version": "0.7.6" }``` | no |
| secret\_sync\_controller | n/a | ```object({ version = string train = string })``` | ```{ "train": "preview", "version": "0.6.7" }``` | no |
| trust\_config\_source | TrustConfig source must be one of 'SelfSigned', 'CustomerManagedByoIssuer' or 'CustomerManagedGenerateIssuer'. Defaults to SelfSigned. When choosing CustomerManagedGenerateIssuer, ensure connectedk8s proxy is enabled on the cluster for current user. When choosing CustomerManagedByoIssuer, ensure an Issuer and ConfigMap resources exist in the cluster. | `string` | `"SelfSigned"` | no |

## Outputs

| Name | Description |
|------|-------------|
| aio\_dataflow\_profile | n/a |
| aio\_instance | n/a |
| aio\_instance\_name | n/a |
| custom\_location\_id | n/a |
| custom\_locations | n/a |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
