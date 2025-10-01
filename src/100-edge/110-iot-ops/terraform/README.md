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
| azapi | >= 2.3.0 |
| azuread | >= 3.0.2 |
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
| role\_assignments | ./modules/role-assignment | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| adr\_namespace | Azure Device Registry namespace to use with Azure IoT Operations. Otherwise, not configured. | ```object({ id = string })``` | n/a | yes |
| adr\_schema\_registry | n/a | ```object({ id = string })``` | n/a | yes |
| aio\_identity | Azure IoT Operations managed identity for workspace access | ```object({ id = string client_id = string tenant_id = string })``` | n/a | yes |
| arc\_connected\_cluster | n/a | ```object({ name = string id = string location = string })``` | n/a | yes |
| resource\_group | Resource group object containing name and id where resources will be deployed | ```object({ name = string id = string location = string })``` | n/a | yes |
| secret\_sync\_identity | n/a | ```object({ id = string client_id = string principal_id = string })``` | n/a | yes |
| secret\_sync\_key\_vault | Azure Key Vault ID to use with Secret Sync Extension. | ```object({ name = string id = string })``` | n/a | yes |
| aio\_ca | CA certificate for the MQTT broker, can be either Root CA or Root CA with any number of Intermediate CAs. If not provided, a self-signed Root CA with a intermediate will be generated. Only valid when Trust Source is set to CustomerManaged | ```object({ root_ca_cert_pem = string ca_cert_chain_pem = string ca_key_pem = string })``` | `null` | no |
| aio\_features | AIO Instance features with mode ('Stable', 'Preview', 'Disabled') and settings ('Enabled', 'Disabled'). | ```map(object({ mode = optional(string) settings = optional(map(string)) }))``` | `null` | no |
| aio\_platform\_config | Install cert-manager and trust-manager extensions | ```object({ install_cert_manager = bool install_trust_manager = bool })``` | ```{ "install_cert_manager": true, "install_trust_manager": true }``` | no |
| broker\_listener\_anonymous\_config | Configuration for the insecure anonymous AIO MQ Broker Listener.  For additional information, refer to: <https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/howto-test-connection?tabs=bicep#node-port> | ```object({ serviceName = string port = number nodePort = number })``` | ```{ "nodePort": 31884, "port": 18884, "serviceName": "aio-broker-anon" }``` | no |
| byo\_issuer\_trust\_settings | Settings for CustomerManagedByoIssuer (Bring Your Own Issuer) trust configuration | ```object({ issuer_name = string issuer_kind = string configmap_name = string configmap_key = string })``` | `null` | no |
| dataflow\_instance\_count | Number of dataflow instances. Defaults to 1. | `number` | `1` | no |
| edge\_storage\_accelerator | n/a | ```object({ version = string train = string diskStorageClass = string faultToleranceEnabled = bool diskMountPoint = string })``` | ```{ "diskMountPoint": "/mnt", "diskStorageClass": "", "faultToleranceEnabled": false, "train": "stable", "version": "2.6.0" }``` | no |
| enable\_instance\_secret\_sync | Whether to enable secret sync on the Azure IoT Operations instance | `bool` | `true` | no |
| enable\_opc\_ua\_simulator | Deploy OPC UA Simulator to the cluster | `bool` | `true` | no |
| mqtt\_broker\_config | n/a | ```object({ brokerListenerServiceName = string brokerListenerPort = number serviceAccountAudience = string frontendReplicas = number frontendWorkers = number backendRedundancyFactor = number backendWorkers = number backendPartitions = number memoryProfile = string serviceType = string })``` | ```{ "backendPartitions": 1, "backendRedundancyFactor": 2, "backendWorkers": 1, "brokerListenerPort": 18883, "brokerListenerServiceName": "aio-broker", "frontendReplicas": 1, "frontendWorkers": 1, "memoryProfile": "Low", "serviceAccountAudience": "aio-internal", "serviceType": "ClusterIp" }``` | no |
| mqtt\_broker\_persistence\_config | Broker persistence configuration for disk-backed message storage | ```object({ enabled = bool max_size = string encryption_enabled = optional(bool) # Dynamic Settings dynamic_settings = optional(object({ user_property_key = string user_property_value = string })) # Retention Policy retain_policy = optional(object({ mode = string # "All", "None", "Custom" custom_settings = optional(object({ topics = optional(list(string)) dynamic_enabled = optional(bool) })) })) # State Store Policy state_store_policy = optional(object({ mode = string # "All", "None", "Custom" custom_settings = optional(object({ state_store_resources = optional(list(object({ key_type = string # "Pattern", "String", "Binary" keys = list(string) }))) dynamic_enabled = optional(bool) })) })) # Subscriber Queue Policy subscriber_queue_policy = optional(object({ mode = string # "All", "None", "Custom" custom_settings = optional(object({ subscriber_client_ids = optional(list(string)) topics = optional(list(string)) dynamic_enabled = optional(bool) })) })) # Persistent Volume Claim Specification persistent_volume_claim_spec = optional(object({ storage_class_name = optional(string) access_modes = optional(list(string)) volume_mode = optional(string) volume_name = optional(string) resources = optional(object({ requests = optional(map(string)) limits = optional(map(string)) })) data_source = optional(object({ api_group = optional(string) kind = string name = string })) selector = optional(object({ match_labels = optional(map(string)) match_expressions = optional(list(object({ key = string operator = string values = list(string) }))) })) })) })``` | `null` | no |
| operations\_config | n/a | ```object({ namespace = string kubernetesDistro = string version = string train = string agentOperationTimeoutInMinutes = number })``` | ```{ "agentOperationTimeoutInMinutes": 120, "kubernetesDistro": "K3s", "namespace": "azure-iot-operations", "train": "preview", "version": "1.2.36" }``` | no |
| platform | n/a | ```object({ version = string train = string })``` | ```{ "train": "preview", "version": "0.7.25" }``` | no |
| secret\_sync\_controller | n/a | ```object({ version = string train = string })``` | ```{ "train": "preview", "version": "0.10.0" }``` | no |
| should\_assign\_key\_vault\_roles | Whether to assign Key Vault roles to provided Secret Sync identity. | `bool` | `true` | no |
| should\_create\_anonymous\_broker\_listener | Whether to enable an insecure anonymous AIO MQ Broker Listener. Should only be used for dev or test environments | `bool` | `false` | no |
| should\_deploy\_resource\_sync\_rules | Deploys resource sync rules if set to true | `bool` | `false` | no |
| should\_enable\_otel\_collector | Whether to deploy the OpenTelemetry Collector and Azure Monitor ConfigMap | `bool` | `true` | no |
| trust\_config\_source | TrustConfig source must be one of 'SelfSigned', 'CustomerManagedByoIssuer' or 'CustomerManagedGenerateIssuer'. Defaults to SelfSigned. When choosing CustomerManagedGenerateIssuer, ensure connectedk8s proxy is enabled on the cluster for current user. When choosing CustomerManagedByoIssuer, ensure an Issuer and ConfigMap resources exist in the cluster. | `string` | `"SelfSigned"` | no |

## Outputs

| Name | Description |
|------|-------------|
| aio\_broker\_listener\_anonymous | The anonymous MQTT Broker Listener configuration details. |
| aio\_dataflow\_profile | The Azure IoT Operations dataflow profile. |
| aio\_instance | The Azure IoT Operations instance. |
| aio\_mqtt\_broker | The MQTT Broker configuration details. |
| aio\_namespace | The Azure IoT Operations namespace. |
| custom\_locations | The custom location details. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
