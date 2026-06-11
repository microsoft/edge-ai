<!-- BEGIN_BICEP_DOCS -->
<!-- markdownlint-disable MD033 -->

# Only Edge IoT Ops Blueprint

Deploys Azure IoT Operations on an existing Arc-enabled Kubernetes cluster without setting up cloud resources.

## Parameters

| Name                                | Description                                                                                                                        | Type                                               | Default                                                                                                                                 | Required |
|:------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------|:---------------------------------------------------|:----------------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                              | The common component configuration.                                                                                                | `[_3.Common](#user-defined-types)`                 | n/a                                                                                                                                     | yes      |
| telemetry_opt_out                   | Whether to opt-out of telemetry. Set to true to disable telemetry.                                                                 | `bool`                                             | `false`                                                                                                                                 | no       |
| customLocationName                  | The name for the Custom Locations resource.                                                                                        | `string`                                           | [format('{0}-cl', parameters('arcConnectedClusterName'))]                                                                               | no       |
| trustIssuerSettings                 | The trust issuer settings for Customer Managed Azure IoT Operations Settings.                                                      | `[_1.TrustIssuerConfig](#user-defined-types)`      | {'trustSource': 'SelfSigned'}                                                                                                           | no       |
| sseIdentityName                     | The name of the User Assigned Managed Identity for Secret Sync Extension.                                                          | `string`                                           | [format('id-{0}-sse-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]    | no       |
| sseKeyVaultName                     | The name of the Key Vault for Secret Sync Extension. Required when providing sseIdentityName.                                      | `string`                                           | [format('kv-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]        | no       |
| sseKeyVaultResourceGroupName        | The name of the Resource Group for the Key Vault for Secret Sync Extension. Required when providing sseIdentityName.               | `string`                                           | [resourceGroup().name]                                                                                                                  | no       |
| shouldAssignSseKeyVaultRoles        | Whether to assign roles for Key Vault to the provided Secret Sync Identity.                                                        | `bool`                                             | `true`                                                                                                                                  | no       |
| deployKeyVaultName                  | The name of the Key Vault that will have scripts and secrets for deployment.                                                       | `string`                                           | [parameters('sseKeyVaultName')]                                                                                                         | no       |
| deployIdentityName                  | The resource name for a managed identity that will be given deployment admin permissions.                                          | `string`                                           | [format('id-{0}-deploy-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| deployKeyVaultResourceGroupName     | The resource group name where the Key Vault is located. Defaults to the current resource group.                                    | `string`                                           | [parameters('sseKeyVaultResourceGroupName')]                                                                                            | no       |
| deployUserTokenSecretName           | The name of the secret in Key Vault that has the token for the deploy user with cluster-admin role.                                | `string`                                           | n/a                                                                                                                                     | no       |
| deploymentScriptsSecretNamePrefix   | The prefix used with constructing the secret name that will have the deployment script.                                            | `string`                                           | [format('{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]           | no       |
| shouldDeployAioDeploymentScripts    | Whether to deploy DeploymentScripts for Azure IoT Operations.                                                                      | `bool`                                             | `false`                                                                                                                                 | no       |
| shouldAssignDeployIdentityRoles     | Whether to assign roles to the deploy identity.                                                                                    | `bool`                                             | `true`                                                                                                                                  | no       |
| shouldInitAio                       | Whether to init Azure IoT Operations. (For debugging)                                                                              | `bool`                                             | `true`                                                                                                                                  | no       |
| aioIdentityName                     | The name of the User Assigned Managed Identity for Azure IoT Operations.                                                           | `string`                                           | [format('id-{0}-aio-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]    | no       |
| aioInstanceName                     | The name for the Azure IoT Operations Instance resource.                                                                           | `string`                                           | [format('{0}-ops-instance', parameters('arcConnectedClusterName'))]                                                                     | no       |
| arcConnectedClusterName             | The resource name for the Arc-enabled Kubernetes cluster.                                                                          | `string`                                           | [format('arck-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]      | no       |
| schemaRegistryName                  | The resource name for the Azure Data Registry Schema Registry for Azure IoT Operations.                                            | `string`                                           | [format('sr-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]        | no       |
| adrNamespaceName                    | The resource name for the ADR Namespace for Azure IoT Operations. Optional parameter for referencing an existing ADR namespace.    | `string`                                           | n/a                                                                                                                                     | no       |
| shouldDeployAio                     | Whether to deploy Azure IoT Operations. (For debugging)                                                                            | `bool`                                             | `true`                                                                                                                                  | no       |
| shouldCreateAnonymousBrokerListener | Whether to enable an insecure anonymous Azure IoT Operations MQ Broker Listener. Should only be used for dev or test environments. | `bool`                                             | `false`                                                                                                                                 | no       |
| shouldDeployResourceSyncRules       | Whether to deploy Custom Locations Resource Sync Rules for the Azure IoT Operations resources.                                     | `bool`                                             | `true`                                                                                                                                  | no       |
| shouldEnableOtelCollector           | Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.                                                    | `bool`                                             | `true`                                                                                                                                  | no       |
| shouldEnableOpcUaSimulator          | Whether or not to enable the OPC UA Simulator and deploy ADR Asset for Azure IoT Operations.                                       | `bool`                                             | `false`                                                                                                                                 | no       |
| namespacedDevices                   | List of namespaced devices to create.                                                                                              | `[_2.NamespacedDevice](#user-defined-types)[]`     | []                                                                                                                                      | no       |
| assetEndpointProfiles               | List of asset endpoint profiles to create.                                                                                         | `[_2.AssetEndpointProfile](#user-defined-types)[]` | []                                                                                                                                      | no       |
| legacyAssets                        | List of legacy assets to create.                                                                                                   | `[_2.LegacyAsset](#user-defined-types)[]`          | []                                                                                                                                      | no       |
| namespacedAssets                    | List of namespaced assets to create.                                                                                               | `[_2.NamespacedAsset](#user-defined-types)[]`      | []                                                                                                                                      | no       |
| shouldCreateDefaultNamespacedAsset  | Whether to create a default namespaced asset and device.                                                                           | `bool`                                             | `true`                                                                                                                                  | no       |

## Resources

| Name              | Type                              | API Version |
|:------------------|:----------------------------------|:------------|
| edgeArcExtensions | `Microsoft.Resources/deployments` | 2025-04-01  |
| edgeIotOps        | `Microsoft.Resources/deployments` | 2025-04-01  |
| edgeAssets        | `Microsoft.Resources/deployments` | 2025-04-01  |

## Modules

| Name              | Description                                                                                                                                                                                    |
|:------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| edgeArcExtensions | Deploys foundational Arc-enabled Kubernetes cluster extensions including cert-manager and Azure Container Storage (ACSA).                                                                      |
| edgeIotOps        | Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.                                                                               |
| edgeAssets        | Deploys Kubernetes asset definitions to a connected cluster using the namespaced Device Registry model. This component facilitates the management of devices and assets within ADR namespaces. |

## Module Details

### edgeArcExtensions

Deploys foundational Arc-enabled Kubernetes cluster extensions including cert-manager and Azure Container Storage (ACSA).

#### Parameters for edgeArcExtensions

| Name                    | Description                                                           | Type                                                  | Default                                             | Required |
|:------------------------|:----------------------------------------------------------------------|:------------------------------------------------------|:----------------------------------------------------|:---------|
| arcConnectedClusterName | The resource name for the Arc connected cluster.                      | `string`                                              | n/a                                                 | yes      |
| certManagerConfig       | The settings for the cert-manager Extension.                          | `[_1.CertManagerExtension](#user-defined-types)`      | [variables('_1.certManagerExtensionDefaults')]      | no       |
| containerStorageConfig  | The settings for the Azure Container Storage for Azure Arc Extension. | `[_1.ContainerStorageExtension](#user-defined-types)` | [variables('_1.containerStorageExtensionDefaults')] | no       |

#### Resources for edgeArcExtensions

| Name             | Type                                           | API Version |
|:-----------------|:-----------------------------------------------|:------------|
| aioCertManager   | `Microsoft.KubernetesConfiguration/extensions` | 2024-11-01  |
| containerStorage | `Microsoft.KubernetesConfiguration/extensions` | 2024-11-01  |

#### Outputs for edgeArcExtensions

| Name                          | Type     | Description                                               |
|:------------------------------|:---------|:----------------------------------------------------------|
| certManagerExtensionId        | `string` | The resource ID of the cert-manager extension.            |
| certManagerExtensionName      | `string` | The name of the cert-manager extension.                   |
| containerStorageExtensionId   | `string` | The resource ID of the Azure Container Storage extension. |
| containerStorageExtensionName | `string` | The name of the Azure Container Storage extension.        |

### edgeIotOps

Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.

#### Parameters for edgeIotOps

| Name                                | Description                                                                                                                                                  | Type                                             | Default                                                                                                                       | Required |
|:------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                              | The common component configuration.                                                                                                                          | `[_2.Common](#user-defined-types)`               | n/a                                                                                                                           | yes      |
| arcConnectedClusterName             | The resource name for the Arc connected cluster.                                                                                                             | `string`                                         | n/a                                                                                                                           | yes      |
| secretStoreConfig                   | The settings for the Secret Store Extension.                                                                                                                 | `[_1.SecretStoreExtension](#user-defined-types)` | [variables('_1.secretStoreExtensionDefaults')]                                                                                | no       |
| shouldInitAio                       | Whether to deploy the Azure IoT Operations initial connected cluster resources, Secret Sync, ACSA, OSM, AIO Platform.                                        | `bool`                                           | `true`                                                                                                                        | no       |
| aioIdentityName                     | The name of the User Assigned Managed Identity for Azure IoT Operations.                                                                                     | `string`                                         | n/a                                                                                                                           | yes      |
| aioExtensionConfig                  | The settings for the Azure IoT Operations Extension.                                                                                                         | `[_1.AioExtension](#user-defined-types)`         | [variables('_1.aioExtensionDefaults')]                                                                                        | no       |
| aioFeatures                         | AIO Instance features.                                                                                                                                       | `[_1.AioFeatures](#user-defined-types)`          | n/a                                                                                                                           | no       |
| aioInstanceName                     | The name for the Azure IoT Operations Instance resource.                                                                                                     | `string`                                         | [format('{0}-ops-instance', parameters('arcConnectedClusterName'))]                                                           | no       |
| aioDataFlowInstanceConfig           | The settings for Azure IoT Operations Data Flow Instances.                                                                                                   | `[_1.AioDataFlowInstance](#user-defined-types)`  | [variables('_1.aioDataFlowInstanceDefaults')]                                                                                 | no       |
| aioMqBrokerConfig                   | The settings for the Azure IoT Operations MQ Broker.                                                                                                         | `[_1.AioMqBroker](#user-defined-types)`          | [variables('_1.aioMqBrokerDefaults')]                                                                                         | no       |
| brokerListenerAnonymousConfig       | Configuration for the insecure anonymous AIO MQ Broker Listener.                                                                                             | `[_1.AioMqBrokerAnonymous](#user-defined-types)` | [variables('_1.aioMqBrokerAnonymousDefaults')]                                                                                | no       |
| configurationSettingsOverride       | Optional configuration settings to override default IoT Operations extension configuration. Use the same key names as the az iot ops --ops-config parameter. | `object`                                         | {}                                                                                                                            | no       |
| schemaRegistryName                  | The resource name for the ADR Schema Registry for Azure IoT Operations.                                                                                      | `string`                                         | n/a                                                                                                                           | yes      |
| adrNamespaceName                    | The resource name for the ADR Namespace for Azure IoT Operations.                                                                                            | `string`                                         | n/a                                                                                                                           | no       |
| shouldDeployAio                     | Whether to deploy an Azure IoT Operations Instance and all of its required components into the connected cluster.                                            | `bool`                                           | `true`                                                                                                                        | no       |
| shouldDeployResourceSyncRules       | Whether or not to deploy the Custom Locations Resource Sync Rules for the Azure IoT Operations resources.                                                    | `bool`                                           | `true`                                                                                                                        | no       |
| shouldCreateAnonymousBrokerListener | Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)                                           | `bool`                                           | `false`                                                                                                                       | no       |
| shouldEnableOtelCollector           | Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.                                                                              | `bool`                                           | `true`                                                                                                                        | no       |
| shouldEnableOpcUaSimulator          | Whether or not to enable the OPC UA Simulator for Azure IoT Operations.                                                                                      | `bool`                                           | `true`                                                                                                                        | no       |
| shouldEnableAkriRestConnector       | Deploy Akri REST HTTP Connector template to the IoT Operations instance.                                                                                     | `bool`                                           | `false`                                                                                                                       | no       |
| shouldEnableAkriMediaConnector      | Deploy Akri Media Connector template to the IoT Operations instance.                                                                                         | `bool`                                           | `false`                                                                                                                       | no       |
| shouldEnableAkriOnvifConnector      | Deploy Akri ONVIF Connector template to the IoT Operations instance.                                                                                         | `bool`                                           | `false`                                                                                                                       | no       |
| shouldEnableAkriSseConnector        | Deploy Akri SSE Connector template to the IoT Operations instance.                                                                                           | `bool`                                           | `false`                                                                                                                       | no       |
| customAkriConnectors                | List of custom Akri connector templates with user-defined endpoint types and container images.                                                               | `array`                                          | []                                                                                                                            | no       |
| registryEndpoints                   | List of additional container registry endpoints for pulling custom artifacts. MCR is always added automatically.                                             | `array`                                          | []                                                                                                                            | no       |
| akriMqttSharedConfig                | Shared MQTT connection configuration for all Akri connectors.                                                                                                | `[_1.AkriMqttConfig](#user-defined-types)`       | {'host': 'aio-broker:18883', 'audience': 'aio-internal', 'caConfigmap': 'azure-iot-operations-aio-ca-trust-bundle'}           | no       |
| customLocationName                  | The name for the Custom Locations resource.                                                                                                                  | `string`                                         | [format('{0}-cl', parameters('arcConnectedClusterName'))]                                                                     | no       |
| additionalClusterExtensionIds       | Additional cluster extension IDs to include in the custom location. (Appended to the default Secret Store and IoT Operations extension IDs)                  | `array`                                          | []                                                                                                                            | no       |
| trustIssuerSettings                 | The trust issuer settings for Customer Managed Azure IoT Operations Settings.                                                                                | `[_1.TrustIssuerConfig](#user-defined-types)`    | {'trustSource': 'SelfSigned'}                                                                                                 | no       |
| sseKeyVaultName                     | The name of the Key Vault for Secret Sync. (Required when providing sseIdentityName)                                                                         | `string`                                         | n/a                                                                                                                           | yes      |
| sseIdentityName                     | The name of the User Assigned Managed Identity for Secret Sync.                                                                                              | `string`                                         | n/a                                                                                                                           | yes      |
| sseKeyVaultResourceGroupName        | The name of the Resource Group for the Key Vault for Secret Sync. (Required when providing sseIdentityName)                                                  | `string`                                         | [resourceGroup().name]                                                                                                        | no       |
| shouldAssignSseKeyVaultRoles        | Whether to assign roles for Key Vault to the provided Secret Sync Identity.                                                                                  | `bool`                                           | `true`                                                                                                                        | no       |
| shouldAssignDeployIdentityRoles     | Whether to assign roles to the deploy identity.                                                                                                              | `bool`                                           | [not(empty(parameters('deployIdentityName')))]                                                                                | no       |
| deployIdentityName                  | The resource name for a managed identity that will be given deployment admin permissions.                                                                    | `string`                                         | n/a                                                                                                                           | no       |
| shouldDeployAioDeploymentScripts    | Whether to deploy DeploymentScripts for Azure IoT Operations.                                                                                                | `bool`                                           | `false`                                                                                                                       | no       |
| deployKeyVaultName                  | The name of the Key Vault that will have scripts and secrets for deployment.                                                                                 | `string`                                         | [parameters('sseKeyVaultName')]                                                                                               | no       |
| deployKeyVaultResourceGroupName     | The resource group name where the Key Vault is located. Defaults to the current resource group.                                                              | `string`                                         | [parameters('sseKeyVaultResourceGroupName')]                                                                                  | no       |
| deployUserTokenSecretName           | The name for the deploy user token secret in Key Vault.                                                                                                      | `string`                                         | deploy-user-token                                                                                                             | no       |
| deploymentScriptsSecretNamePrefix   | The prefix used with constructing the secret name that will have the deployment script.                                                                      | `string`                                         | [format('{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| shouldAddDeployScriptsToKeyVault    | Whether to add the deploy scripts for DeploymentScripts to Key Vault as secrets. (Required for DeploymentScripts)                                            | `bool`                                           | `false`                                                                                                                       | no       |
| telemetry_opt_out                   | Whether to opt out of telemetry data collection.                                                                                                             | `bool`                                           | `false`                                                                                                                       | no       |

#### Resources for edgeIotOps

| Name                          | Type                              | API Version |
|:------------------------------|:----------------------------------|:------------|
| deployArcK8sRoleAssignments   | `Microsoft.Resources/deployments` | 2025-04-01  |
| deployKeyVaultRoleAssignments | `Microsoft.Resources/deployments` | 2025-04-01  |
| sseKeyVaultRoleAssignments    | `Microsoft.Resources/deployments` | 2025-04-01  |
| iotOpsInit                    | `Microsoft.Resources/deployments` | 2025-04-01  |
| postInitScriptsSecrets        | `Microsoft.Resources/deployments` | 2025-04-01  |
| postInitScripts               | `Microsoft.Resources/deployments` | 2025-04-01  |
| iotOpsInstance                | `Microsoft.Resources/deployments` | 2025-04-01  |
| akriConnectors                | `Microsoft.Resources/deployments` | 2025-04-01  |
| registryEndpointsModule       | `Microsoft.Resources/deployments` | 2025-04-01  |
| postInstanceScriptsSecrets    | `Microsoft.Resources/deployments` | 2025-04-01  |
| postInstanceScripts           | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for edgeIotOps

| Name                       | Type     | Description                                                           |
|:---------------------------|:---------|:----------------------------------------------------------------------|
| aioPlatformExtensionId     | `string` | The ID of the Azure IoT Operations Platform Extension.                |
| aioPlatformExtensionName   | `string` | The name of the Azure IoT Operations Platform Extension.              |
| aioNamespace               | `string` | The namespace in the cluster where Azure IoT Operations is installed. |
| secretStoreExtensionId     | `string` | The ID of the Secret Store Extension.                                 |
| secretStoreExtensionName   | `string` | The name of the Secret Store Extension.                               |
| customLocationId           | `string` | The ID of the deployed Custom Location.                               |
| customLocationName         | `string` | The name of the deployed Custom Location.                             |
| aioInstanceId              | `string` | The ID of the deployed Azure IoT Operations instance.                 |
| aioInstanceName            | `string` | The name of the deployed Azure IoT Operations instance.               |
| dataFlowProfileId          | `string` | The ID of the deployed Azure IoT Operations Data Flow Profile.        |
| dataFlowProfileName        | `string` | The name of the deployed Azure IoT Operations Data Flow Profile.      |
| dataFlowEndpointId         | `string` | The ID of the deployed Azure IoT Operations Data Flow Endpoint.       |
| dataFlowEndpointName       | `string` | The name of the deployed Azure IoT Operations Data Flow Endpoint.     |
| akriConnectorTemplates     | `array`  | Map of deployed Akri connector templates by name with id and type.    |
| akriConnectorTypesDeployed | `array`  | List of Akri connector types that were deployed.                      |

### edgeAssets

Deploys Kubernetes asset definitions to a connected cluster using the namespaced Device Registry model. This component facilitates the management of devices and assets within ADR namespaces.

#### Parameters for edgeAssets

| Name                               | Description                                                                                   | Type                               | Default | Required |
|:-----------------------------------|:----------------------------------------------------------------------------------------------|:-----------------------------------|:--------|:---------|
| common                             | The common component configuration.                                                           | `[_2.Common](#user-defined-types)` | n/a     | yes      |
| customLocationId                   | The ID (resource ID) of the custom location to retrieve.                                      | `string`                           | n/a     | yes      |
| adrNamespaceName                   | Azure Device Registry namespace name to use with Azure IoT Operations.                        | `string`                           | n/a     | yes      |
| namespacedDevices                  | List of namespaced devices to create.                                                         | `array`                            | []      | no       |
| assetEndpointProfiles              | List of asset endpoint profiles to create.                                                    | `array`                            | []      | no       |
| legacyAssets                       | List of legacy assets to create.                                                              | `array`                            | []      | no       |
| namespacedAssets                   | List of namespaced assets to create.                                                          | `array`                            | []      | no       |
| shouldCreateDefaultAsset           | Whether to create a default legacy asset and endpoint profile.                                | `bool`                             | `false` | no       |
| shouldCreateDefaultNamespacedAsset | Whether to create a default namespaced asset and device.                                      | `bool`                             | `false` | no       |
| k8sBridgePrincipalId               | The principal ID of the K8 Bridge for Azure IoT Operations. Required for OPC asset discovery. | `string`                           | n/a     | no       |

#### Resources for edgeAssets

| Name                   | Type                                             | API Version |
|:-----------------------|:-------------------------------------------------|:------------|
| namespacedDevice       | `Microsoft.DeviceRegistry/namespaces/devices`    | 2026-04-01  |
| namespacedAsset        | `Microsoft.DeviceRegistry/namespaces/assets`     | 2026-04-01  |
| assetEndpointProfile   | `Microsoft.DeviceRegistry/assetEndpointProfiles` | 2026-04-01  |
| legacyAsset            | `Microsoft.DeviceRegistry/assets`                | 2026-04-01  |
| k8BridgeRoleAssignment | `Microsoft.Resources/deployments`                | 2025-04-01  |

#### Outputs for edgeAssets

| Name                          | Type    | Description                                                                 |
|:------------------------------|:--------|:----------------------------------------------------------------------------|
| assetEndpointProfiles         | `array` | Array of legacy asset endpoint profiles created by this component.          |
| legacyAssets                  | `array` | Array of legacy assets created by this component.                           |
| namespacedDevices             | `array` | Array of namespaced devices created by this component.                      |
| namespacedAssets              | `array` | Array of namespaced assets created by this component.                       |
| shouldEnableOpcAssetDiscovery | `bool`  | Whether OPC simulation asset discovery is enabled for any endpoint profile. |

## User Defined Types

### `_1.AioCaConfig`

Configuration for Azure IoT Operations Certificate Authority.

| Property       | Type           | Description                             |
|:---------------|:---------------|:----------------------------------------|
| rootCaCertPem  | `securestring` | The PEM-formatted root CA certificate.  |
| caCertChainPem | `securestring` | The PEM-formatted CA certificate chain. |
| caKeyPem       | `securestring` | The PEM-formatted CA private key.       |

### `_1.AioDataFlowInstance`

The settings for Azure IoT Operations Data Flow Instances.

| Property | Type  | Description                        |
|:---------|:------|:-----------------------------------|
| count    | `int` | The number of data flow instances. |

### `_1.AioExtension`

The settings for the Azure IoT Operations Extension.

| Property | Type                                | Description                            |
|:---------|:------------------------------------|:---------------------------------------|
| release  | `[_1.Release](#user-defined-types)` | The common settings for the extension. |
| settings | `object`                            |                                        |

### `_1.AioFeatures`

AIO Instance features.

### `_1.AioMqBroker`

The settings for the Azure IoT Operations MQ Broker.

| Property                  | Type                                                | Description                                                          |
|:--------------------------|:----------------------------------------------------|:---------------------------------------------------------------------|
| brokerListenerServiceName | `string`                                            | The service name for the broker listener.                            |
| brokerListenerPort        | `int`                                               | The port for the broker listener.                                    |
| serviceAccountAudience    | `string`                                            | The audience for the service account.                                |
| frontendReplicas          | `int`                                               | The number of frontend replicas for the broker.                      |
| frontendWorkers           | `int`                                               | The number of frontend workers for the broker.                       |
| backendRedundancyFactor   | `int`                                               | The redundancy factor for the backend of the broker.                 |
| backendWorkers            | `int`                                               | The number of backend workers for the broker.                        |
| backendPartitions         | `int`                                               | The number of partitions for the backend of the broker.              |
| memoryProfile             | `string`                                            | The memory profile for the broker (Low, Medium, High).               |
| serviceType               | `string`                                            | The service type for the broker (ClusterIP, LoadBalancer, NodePort). |
| logsLevel                 | `string`                                            | The log level for broker diagnostics (info, debug, trace).           |
| persistence               | `[_1.BrokerPersistence](#user-defined-types)`       | Broker persistence configuration for disk-backed message storage.    |
| advanced                  | `[_1.BrokerAdvancedConfig](#user-defined-types)`    | Advanced broker settings.                                            |
| diskBackedMessageBuffer   | `[_1.BrokerDiskBufferConfig](#user-defined-types)`  | Disk-backed message buffer configuration.                            |
| diagnosticsConfig         | `[_1.BrokerDiagnosticsConfig](#user-defined-types)` | Extended diagnostics configuration (metrics, self-check, traces).    |

### `_1.AioMqBrokerAnonymous`

Configuration for the insecure anonymous AIO MQ Broker Listener.

| Property    | Type     | Description                                         |
|:------------|:---------|:----------------------------------------------------|
| serviceName | `string` | The service name for the anonymous broker listener. |
| port        | `int`    | The port for the anonymous broker listener.         |
| nodePort    | `int`    | The node port for the anonymous broker listener.    |

### `_1.AkriAllocationPolicy`

Resource allocation policy for Akri connector pods.

| Property   | Type     | Description                         |
|:-----------|:---------|:------------------------------------|
| policy     | `string` | Allocation policy type.             |
| bucketSize | `int`    | Bucket size for allocation (1-100). |

### `_1.AkriConnectorTemplate`

Akri connector template configuration.

| Property                   | Type                                             | Description                                                                   |
|:---------------------------|:-------------------------------------------------|:------------------------------------------------------------------------------|
| name                       | `string`                                         | Unique name for the connector (lowercase letters, numbers, and hyphens only). |
| type                       | `string`                                         | Connector type.                                                               |
| customEndpointType         | `string`                                         | Custom endpoint type (required for custom connectors).                        |
| customImageName            | `string`                                         | Custom image name (required for custom connectors).                           |
| customEndpointVersion      | `string`                                         | Custom endpoint version.                                                      |
| customConnectorMetadataRef | `string`                                         | Custom connector metadata reference.                                          |
| registry                   | `string`                                         | Container registry for pulling connector images.                              |
| imageTag                   | `string`                                         | Image tag for the connector.                                                  |
| replicas                   | `int`                                            | Number of connector replicas.                                                 |
| imagePullPolicy            | `string`                                         | Image pull policy.                                                            |
| logLevel                   | `string`                                         | Log level for connector diagnostics.                                          |
| mqttConfig                 | `[_1.AkriMqttConfig](#user-defined-types)`       | MQTT configuration override for this connector.                               |
| aioMinVersion              | `string`                                         | Minimum AIO version requirement.                                              |
| aioMaxVersion              | `string`                                         | Maximum AIO version requirement.                                              |
| allocation                 | `[_1.AkriAllocationPolicy](#user-defined-types)` | Resource allocation policy.                                                   |
| additionalConfiguration    | `object`                                         | Additional configuration key-value pairs.                                     |
| secrets                    | `array`                                          | Secret configurations.                                                        |
| trustSettings              | `[_1.AkriTrustSettings](#user-defined-types)`    | Trust settings configuration.                                                 |

### `_1.AkriMqttConfig`

MQTT connection configuration for Akri connectors.

| Property             | Type     | Description                                        |
|:---------------------|:---------|:---------------------------------------------------|
| host                 | `string` | MQTT broker host address.                          |
| audience             | `string` | Service account token audience for authentication. |
| caConfigmap          | `string` | ConfigMap reference for trusted CA certificates.   |
| keepAliveSeconds     | `int`    | Keep alive interval in seconds.                    |
| maxInflightMessages  | `int`    | Maximum number of in-flight messages.              |
| sessionExpirySeconds | `int`    | Session expiry interval in seconds.                |

### `_1.AkriSecretConfig`

Secret configuration for Akri connector.

| Property    | Type     | Description                       |
|:------------|:---------|:----------------------------------|
| secretAlias | `string` | Alias for the secret.             |
| secretKey   | `string` | Key within the secret.            |
| secretRef   | `string` | Reference to the secret resource. |

### `_1.AkriTrustSettings`

Trust settings for Akri connector.

| Property           | Type     | Description                         |
|:-------------------|:---------|:------------------------------------|
| trustListSecretRef | `string` | Reference to the trust list secret. |

### `_1.ArtifactPullSecretSettings`

Authentication settings for Artifact Pull Secret.

| Property  | Type     | Description                                                               |
|:----------|:---------|:--------------------------------------------------------------------------|
| secretRef | `string` | The name of the kubernetes secret that contains the artifact pull secret. |

### `_1.BrokerAdvancedConfig`

Advanced broker settings for client limits, internal traffic encryption, and internal certificate configuration.

| Property               | Type     | Description                                           |
|:-----------------------|:---------|:------------------------------------------------------|
| encryptInternalTraffic | `string` | Encrypt internal broker traffic. Defaults to Enabled. |
| internalCerts          | `object` | Internal certificate configuration.                   |
| clients                | `object` | Client configuration for MQTT sessions.               |

### `_1.BrokerDiagnosticsConfig`

Extended broker diagnostics configuration for metrics, self-check, and distributed tracing.

| Property  | Type     | Description                          |
|:----------|:---------|:-------------------------------------|
| metrics   | `object` | Metrics configuration.               |
| selfCheck | `object` | Self-check diagnostic configuration. |
| traces    | `object` | Distributed tracing configuration.   |

### `_1.BrokerDiskBufferConfig`

Disk-backed message buffer configuration for broker in-memory overflow to disk.

| Property                  | Type     | Description                                                         |
|:--------------------------|:---------|:--------------------------------------------------------------------|
| maxSize                   | `string` | Maximum buffer size (e.g. "500M", "1G"). Pattern: ^[0-9]+[KMGTPE]$. |
| ephemeralVolumeClaimSpec  | `object` | Ephemeral volume claim spec for message buffer (preferred).         |
| persistentVolumeClaimSpec | `object` | Persistent volume claim spec for message buffer.                    |

### `_1.BrokerPersistence`

Broker persistence configuration for disk-backed message storage.

| Property                  | Type     | Description                                                      |
|:--------------------------|:---------|:-----------------------------------------------------------------|
| maxSize                   | `string` | Maximum size of the message buffer on disk (e.g., "500M", "1G"). |
| encryption                | `object` | Encryption configuration for the persistence database.           |
| retain                    | `object` | Controls which retained messages should be persisted to disk.    |
| stateStore                | `object` | Controls which state store keys should be persisted to disk.     |
| subscriberQueue           | `object` | Controls which subscriber queues should be persisted to disk.    |
| persistentVolumeClaimSpec | `object` | Persistent volume claim specification for storage.               |

### `_1.CustomerManagedByoIssuerConfig`

The configuration for Customer Managed Bring Your Own Issuer for Azure IoT Operations certificates.

| Property      | Type                                            | Description                                  |
|:--------------|:------------------------------------------------|:---------------------------------------------|
| trustSource   | `string`                                        |                                              |
| trustSettings | `[_1.TrustSettingsConfig](#user-defined-types)` | The trust settings for Azure IoT Operations. |

### `_1.CustomerManagedGenerateIssuerConfig`

The configuration for the Customer Managed Generated trust source of Azure IoT Operations certificates.

| Property    | Type                                    | Description                                                  |
|:------------|:----------------------------------------|:-------------------------------------------------------------|
| trustSource | `string`                                |                                                              |
| aioCa       | `[_1.AioCaConfig](#user-defined-types)` | The CA certificate, chain, and key for Azure IoT Operations. |

### `_1.IncludeFileConfig`

Additional file configuration for deployment scripts.

| Property | Type           | Description                        |
|:---------|:---------------|:-----------------------------------|
| name     | `string`       | The name of the file to create.    |
| content  | `securestring` | The content of the file to create. |

### `_1.InstanceFeature`

Individual feature object within the AIO instance.

| Property | Type                                            | Description |
|:---------|:------------------------------------------------|:------------|
| mode     | `[_1.InstanceFeatureMode](#user-defined-types)` |             |
| settings | `object`                                        |             |

### `_1.InstanceFeatureMode`

The mode of the AIO instance feature. Either "Stable", "Preview" or "Disabled".

### `_1.InstanceFeatureSettingValue`

The setting value of the AIO instance feature. Either "Enabled" or "Disabled".

### `_1.RegistryAuthAnonymous`

Anonymous authentication for registry endpoint.

| Property          | Type     | Description                                       |
|:------------------|:---------|:--------------------------------------------------|
| method            | `string` | Authentication method.                            |
| anonymousSettings | `object` | Anonymous authentication settings (empty object). |

### `_1.RegistryAuthArtifactPullSecret`

Artifact Pull Secret authentication for registry endpoint.

| Property                   | Type                                                   | Description                    |
|:---------------------------|:-------------------------------------------------------|:-------------------------------|
| method                     | `string`                                               | Authentication method.         |
| artifactPullSecretSettings | `[_1.ArtifactPullSecretSettings](#user-defined-types)` | Artifact pull secret settings. |

### `_1.RegistryAuthentication`

Authentication configuration for a registry endpoint.

### `_1.RegistryAuthSystemAssignedManagedIdentity`

System-Assigned Managed Identity authentication for registry endpoint.

| Property                              | Type                                                              | Description                                |
|:--------------------------------------|:------------------------------------------------------------------|:-------------------------------------------|
| method                                | `string`                                                          | Authentication method.                     |
| systemAssignedManagedIdentitySettings | `[_1.SystemAssignedManagedIdentitySettings](#user-defined-types)` | System-assigned managed identity settings. |

### `_1.RegistryAuthUserAssignedManagedIdentity`

User-Assigned Managed Identity authentication for registry endpoint.

| Property                            | Type                                                            | Description                              |
|:------------------------------------|:----------------------------------------------------------------|:-----------------------------------------|
| method                              | `string`                                                        | Authentication method.                   |
| userAssignedManagedIdentitySettings | `[_1.UserAssignedManagedIdentitySettings](#user-defined-types)` | User-assigned managed identity settings. |

### `_1.RegistryEndpointConfig`

Container registry endpoint configuration for AIO instance.

| Property       | Type                                               | Description                                                                                                                                  |
|:---------------|:---------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------|
| name           | `string`                                           | Unique name for the registry endpoint (3-63 chars, lowercase alphanumeric and hyphens).                                                      |
| host           | `string`                                           | Container registry hostname (e.g., myregistry.azurecr.io).                                                                                   |
| acrResourceId  | `string`                                           | Optional ACR resource ID for automatic AcrPull role assignment. Only applicable when authentication.method is SystemAssignedManagedIdentity. |
| authentication | `[_1.RegistryAuthentication](#user-defined-types)` | Authentication configuration for the registry.                                                                                               |

### `_1.Release`

The common settings for Azure Arc Extensions.

| Property | Type     | Description                                                                  |
|:---------|:---------|:-----------------------------------------------------------------------------|
| version  | `string` | The version of the extension.                                                |
| train    | `string` | The release train that has the version to deploy (ex., "preview", "stable"). |

### `_1.ScriptConfig`

Script configuration for deployment scripts.

| Property | Type           | Description                           |
|:---------|:---------------|:--------------------------------------|
| content  | `securestring` | The script content to be executed.    |
| env      | `array`        | Environment variables for the script. |

### `_1.ScriptEnvironmentVariable`

Environment variable configuration for scripts.

| Property    | Type           | Description                                   |
|:------------|:---------------|:----------------------------------------------|
| name        | `string`       | The name of the environment variable.         |
| value       | `string`       | The value of the environment variable.        |
| secureValue | `securestring` | The secure value of the environment variable. |

### `_1.ScriptFilesConfig`

The script and additional configuration files for deployment scripts.

| Property     | Type    | Description                                                |
|:-------------|:--------|:-----------------------------------------------------------|
| scripts      | `array` | The script configuration for deployment scripts.           |
| includeFiles | `array` | The additional file configuration for deployment scripts.s |

### `_1.SecretStoreExtension`

The settings for the Secret Store Extension.

| Property | Type                                | Description                            |
|:---------|:------------------------------------|:---------------------------------------|
| release  | `[_1.Release](#user-defined-types)` | The common settings for the extension. |

### `_1.SelfSignedIssuerConfig`

The configuration for Self-Signed Issuer for Azure IoT Operations certificates.

| Property    | Type     | Description |
|:------------|:---------|:------------|
| trustSource | `string` |             |

### `_1.SystemAssignedManagedIdentitySettings`

Authentication settings for System-Assigned Managed Identity.

| Property | Type     | Description                                                                                             |
|:---------|:---------|:--------------------------------------------------------------------------------------------------------|
| audience | `string` | Audience of the service to authenticate against. Defaults to "<https://management.azure.com/>" for ACR. |

### `_1.TrustConfigSource`

The config source of trust for how to use or generate Azure IoT Operations certificates.

### `_1.TrustIssuerConfig`

The configuration for the trust source of Azure IoT Operations certificates.

### `_1.TrustSettingsConfig`

The configuration for the trust settings of Azure IoT Operations certificates.

| Property      | Type     | Description |
|:--------------|:---------|:------------|
| issuerName    | `string` |             |
| issuerKind    | `string` |             |
| configMapName | `string` |             |
| configMapKey  | `string` |             |

### `_1.TrustSource`

The source of trust for Azure IoT Operations certificates.

### `_1.UserAssignedManagedIdentitySettings`

Authentication settings for User-Assigned Managed Identity.

| Property | Type     | Description                                                    |
|:---------|:---------|:---------------------------------------------------------------|
| clientId | `string` | Client ID for the user-assigned managed identity.              |
| tenantId | `string` | Tenant ID where the managed identity is located.               |
| scope    | `string` | Resource identifier (application ID URI) with .default suffix. |

### `_2.AssetAction`

Management action configuration for assets.

| Property            | Type     | Description                                               |
|:--------------------|:---------|:----------------------------------------------------------|
| name                | `string` | Name of the action.                                       |
| actionType          | `string` | Type of the action. Must be one of: Call, Read, or Write. |
| targetUri           | `string` | Target URI for the action.                                |
| topic               | `string` | MQTT topic for the action.                                |
| timeoutInSeconds    | `int`    | Timeout in seconds for the action.                        |
| actionConfiguration | `string` | Action configuration as JSON string.                      |
| typeRef             | `string` | Type reference for the action.                            |

### `_2.AssetDataPoint`

Data point configuration for asset datasets.

| Property               | Type     | Description                                           |
|:-----------------------|:---------|:------------------------------------------------------|
| name                   | `string` | Name of the data point.                               |
| dataSource             | `string` | Data source address.                                  |
| dataPointConfiguration | `string` | Data point configuration as JSON string.              |
| samplingIntervalMs     | `int`    | Sampling interval in milliseconds for REST endpoints. |
| mqttTopic              | `string` | MQTT topic for REST state store.                      |
| includeStateStore      | `bool`   | Whether to include state store for REST endpoints.    |
| stateStoreKey          | `string` | State store key for REST endpoints.                   |

### `_2.AssetDataset`

Dataset configuration for assets.

| Property             | Type     | Description                           |
|:---------------------|:---------|:--------------------------------------|
| name                 | `string` | Name of the dataset.                  |
| datasetConfiguration | `string` | Dataset configuration as JSON string. |
| dataSource           | `string` | Data source address for the dataset.  |
| typeRef              | `string` | Type reference for the dataset.       |
| dataPoints           | `array`  | Data points in the dataset.           |
| destinations         | `array`  | Destinations for the dataset.         |

### `_2.AssetEndpointProfile`

Legacy asset endpoint profile configuration.

| Property                      | Type     | Description                                         |
|:------------------------------|:---------|:----------------------------------------------------|
| name                          | `string` | Name of the asset endpoint profile.                 |
| endpointProfileType           | `string` | Type of the endpoint profile: Microsoft.OpcUa, etc. |
| method                        | `string` | Authentication method: Anonymous, etc.              |
| targetAddress                 | `string` | Target address of the endpoint.                     |
| opcAdditionalConfigString     | `string` | Additional OPC configuration as JSON string.        |
| shouldEnableOpcAssetDiscovery | `bool`   | Whether to enable OPC asset discovery.              |

### `_2.AssetEvent`

Event configuration for assets.

| Property           | Type     | Description                         |
|:-------------------|:---------|:------------------------------------|
| name               | `string` | Name of the event.                  |
| dataSource         | `string` | Data source address for the event.  |
| eventConfiguration | `string` | Event configuration as JSON string. |
| typeRef            | `string` | Type reference for the event.       |
| destinations       | `array`  | Destinations for the event.         |

### `_2.AssetEventDestination`

Event destination configuration.

| Property      | Type     | Description                            |
|:--------------|:---------|:---------------------------------------|
| target        | `string` | Target for the destination: Mqtt, etc. |
| configuration | `object` | Configuration for the destination.     |

### `_2.AssetEventGroup`

Event group configuration for assets.

| Property                | Type     | Description                                   |
|:------------------------|:---------|:----------------------------------------------|
| name                    | `string` | Name of the event group.                      |
| dataSource              | `string` | Data source address for the event group.      |
| eventGroupConfiguration | `string` | Event group configuration as JSON string.     |
| typeRef                 | `string` | Type reference for the event group.           |
| defaultDestinations     | `array`  | Default destinations for events in the group. |
| events                  | `array`  | Events in the event group.                    |

### `_2.AssetManagementGroup`

Management group configuration for assets.

| Property                     | Type     | Description                                          |
|:-----------------------------|:---------|:-----------------------------------------------------|
| name                         | `string` | Name of the management group.                        |
| dataSource                   | `string` | Data source address for the management group.        |
| managementGroupConfiguration | `string` | Management group configuration as JSON string.       |
| typeRef                      | `string` | Type reference for the management group.             |
| defaultTopic                 | `string` | Default MQTT topic for actions in the group.         |
| defaultTimeoutInSeconds      | `int`    | Default timeout in seconds for actions in the group. |
| actions                      | `array`  | Actions in the management group.                     |

### `_2.AssetStream`

Stream configuration for assets.

| Property            | Type     | Description                          |
|:--------------------|:---------|:-------------------------------------|
| name                | `string` | Name of the stream.                  |
| streamConfiguration | `string` | Stream configuration as JSON string. |
| typeRef             | `string` | Type reference for the stream.       |
| destinations        | `array`  | Destinations for the stream set.     |

### `_2.DatasetDestination`

Dataset destination configuration.

| Property      | Type     | Description                            |
|:--------------|:---------|:---------------------------------------|
| target        | `string` | Target for the destination: Mqtt, etc. |
| configuration | `object` | Configuration for the destination.     |

### `_2.DeviceEndpoint`

Endpoint configuration for devices.

| Property                | Type                                               | Description                                    |
|:------------------------|:---------------------------------------------------|:-----------------------------------------------|
| endpointType            | `string`                                           | Type of the endpoint: Microsoft.OpcUa, etc.    |
| address                 | `string`                                           | Address of the endpoint.                       |
| version                 | `string`                                           | Version of the endpoint protocol.              |
| additionalConfiguration | `string`                                           | Additional configuration as JSON string.       |
| authentication          | `[_2.EndpointAuthentication](#user-defined-types)` | Authentication configuration for the endpoint. |
| trustSettings           | `[_2.TrustSettings](#user-defined-types)`          | Trust settings for the endpoint.               |

### `_2.DeviceEndpoints`

Device endpoints configuration.

| Property | Type     | Description                      |
|:---------|:---------|:---------------------------------|
| outbound | `object` | Outbound endpoint configuration. |
| inbound  | `object` | Inbound endpoint configurations. |

### `_2.DeviceReference`

Device reference for namespaced assets.

| Property     | Type     | Description                         |
|:-------------|:---------|:------------------------------------|
| deviceName   | `string` | Name of the device.                 |
| endpointName | `string` | Name of the endpoint on the device. |

### `_2.EndpointAuthentication`

Endpoint authentication configuration for assets.

| Property                    | Type     | Description                                                 |
|:----------------------------|:---------|:------------------------------------------------------------|
| method                      | `string` | Authentication method: Anonymous, UsernamePassword, or X509 |
| usernamePasswordCredentials | `object` | Username and password credentials for authentication.       |
| x509Credentials             | `object` | X509 certificate credentials for authentication.            |

### `_2.LegacyAsset`

Legacy asset configuration.

| Property                     | Type     | Description                                    |
|:-----------------------------|:---------|:-----------------------------------------------|
| name                         | `string` | Name of the asset.                             |
| assetEndpointProfileRef      | `string` | Reference to the asset endpoint profile.       |
| displayName                  | `string` | Display name of the asset.                     |
| description                  | `string` | Description of the asset.                      |
| documentationUri             | `string` | Documentation URI for the asset.               |
| isEnabled                    | `bool`   | Whether the asset is enabled.                  |
| hardwareRevision             | `string` | Hardware revision of the asset.                |
| manufacturer                 | `string` | Manufacturer of the asset.                     |
| manufacturerUri              | `string` | Manufacturer URI of the asset.                 |
| model                        | `string` | Model of the asset.                            |
| productCode                  | `string` | Product code of the asset.                     |
| serialNumber                 | `string` | Serial number of the asset.                    |
| softwareRevision             | `string` | Software revision of the asset.                |
| datasets                     | `array`  | Datasets for the asset.                        |
| defaultDatasetsConfiguration | `string` | Default datasets configuration as JSON string. |

### `_2.LegacyAssetDataPoint`

Legacy asset data point configuration.

| Property               | Type     | Description                              |
|:-----------------------|:---------|:-----------------------------------------|
| name                   | `string` | Name of the data point.                  |
| dataSource             | `string` | Data source address.                     |
| dataPointConfiguration | `string` | Data point configuration as JSON string. |
| observabilityMode      | `string` | Observability mode: None, etc.           |

### `_2.LegacyAssetDataset`

Legacy asset dataset configuration.

| Property   | Type     | Description                 |
|:-----------|:---------|:----------------------------|
| name       | `string` | Name of the dataset.        |
| dataPoints | `array`  | Data points in the dataset. |

### `_2.NamespacedAsset`

Namespaced asset configuration.

| Property                     | Type                                        | Description                                         |
|:-----------------------------|:--------------------------------------------|:----------------------------------------------------|
| name                         | `string`                                    | Name of the asset.                                  |
| displayName                  | `string`                                    | Display name of the asset.                          |
| deviceRef                    | `[_2.DeviceReference](#user-defined-types)` | Reference to the device and endpoint.               |
| description                  | `string`                                    | Description of the asset.                           |
| documentationUri             | `string`                                    | Documentation URI for the asset.                    |
| externalAssetId              | `string`                                    | Asset Id provided by external system for the asset. |
| isEnabled                    | `bool`                                      | Whether the asset is enabled.                       |
| hardwareRevision             | `string`                                    | Hardware revision of the asset.                     |
| manufacturer                 | `string`                                    | Manufacturer of the asset.                          |
| manufacturerUri              | `string`                                    | Manufacturer URI of the asset.                      |
| model                        | `string`                                    | Model of the asset.                                 |
| productCode                  | `string`                                    | Product code of the asset.                          |
| serialNumber                 | `string`                                    | Serial number of the asset.                         |
| softwareRevision             | `string`                                    | Software revision of the asset.                     |
| attributes                   | `object`                                    | Custom attributes for the asset.                    |
| datasets                     | `array`                                     | Datasets for the asset.                             |
| streams                      | `array`                                     | Streams for the asset.                              |
| eventGroups                  | `array`                                     | Event groups for the asset.                         |
| managementGroups             | `array`                                     | Management groups for the asset.                    |
| defaultDatasetsConfiguration | `string`                                    | Default datasets configuration as JSON string.      |
| defaultStreamsConfiguration  | `string`                                    | Default streams configuration as JSON string.       |
| defaultEventsConfiguration   | `string`                                    | Default events configuration as JSON string.        |

### `_2.NamespacedDevice`

Namespaced device configuration.

| Property  | Type                                        | Description                             |
|:----------|:--------------------------------------------|:----------------------------------------|
| name      | `string`                                    | Name of the device.                     |
| isEnabled | `bool`                                      | Whether the device is enabled.          |
| endpoints | `[_2.DeviceEndpoints](#user-defined-types)` | Endpoint configurations for the device. |

### `_2.TrustSettings`

Trust settings for endpoint connections.

| Property  | Type     | Description               |
|:----------|:---------|:--------------------------|
| trustList | `string` | Trust list configuration. |

### `_3.Common`

Common settings for the components.

| Property       | Type     | Description                                                      |
|:---------------|:---------|:-----------------------------------------------------------------|
| resourcePrefix | `string` | Prefix for all resources in this module                          |
| location       | `string` | Location for all resources in this module                        |
| environment    | `string` | Environment for all resources in this module: dev, test, or prod |
| instance       | `string` | Instance identifier for naming resources: 001, 002, etc...       |

## Outputs

| Name                        | Type     | Description                                                       |
|:----------------------------|:---------|:------------------------------------------------------------------|
| aioCertManagerExtensionId   | `string` | The ID of the Azure IoT Operations Cert-Manager Extension.        |
| aioCertManagerExtensionName | `string` | The name of the Azure IoT Operations Cert-Manager Extension.      |
| secretStoreExtensionId      | `string` | The ID of the Secret Store Extension.                             |
| secretStoreExtensionName    | `string` | The name of the Secret Store Extension.                           |
| customLocationId            | `string` | The ID of the deployed Custom Location.                           |
| customLocationName          | `string` | The name of the deployed Custom Location.                         |
| aioInstanceId               | `string` | The ID of the deployed Azure IoT Operations instance.             |
| aioInstanceName             | `string` | The name of the deployed Azure IoT Operations instance.           |
| dataFlowProfileId           | `string` | The ID of the deployed Azure IoT Operations Data Flow Profile.    |
| dataFlowProfileName         | `string` | The name of the deployed Azure IoT Operations Data Flow Profile.  |
| dataFlowEndpointId          | `string` | The ID of the deployed Azure IoT Operations Data Flow Endpoint.   |
| dataFlowEndpointName        | `string` | The name of the deployed Azure IoT Operations Data Flow Endpoint. |

<!-- END_BICEP_DOCS -->