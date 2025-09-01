<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Azure IoT Operations

Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|arcConnectedClusterName|The resource name for the Arc connected cluster.|`string`|n/a|yes|
|containerStorageConfig|The settings for the Azure Container Store for Azure Arc Extension.|`[_1.ContainerStorageExtension](#user-defined-types)`|[variables('_1.containerStorageExtensionDefaults')]|no|
|openServiceMeshConfig|The settings for the Open Service Mesh Extension.|`[_1.OpenServiceMeshExtension](#user-defined-types)`|[variables('_1.openServiceMeshExtensionDefaults')]|no|
|aioPlatformConfig|The settings for the Azure IoT Operations Platform Extension.|`[_1.AioPlatformExtension](#user-defined-types)`|[variables('_1.aioPlatformExtensionDefaults')]|no|
|secretStoreConfig|The settings for the Secret Store Extension.|`[_1.SecretStoreExtension](#user-defined-types)`|[variables('_1.secretStoreExtensionDefaults')]|no|
|shouldInitAio|Whether to deploy the Azure IoT Operations initial connected cluster resources, Secret Sync, ACSA, OSM, AIO Platform.|`bool`|`true`|no|
|aioIdentityName|The name of the User Assigned Managed Identity for Azure IoT Operations.|`string`|n/a|yes|
|aioExtensionConfig|The settings for the Azure IoT Operations Extension.|`[_1.AioExtension](#user-defined-types)`|[variables('_1.aioExtensionDefaults')]|no|
|aioFeatures|AIO Instance features.|`[_1.AioFeatures](#user-defined-types)`|n/a|no|
|aioInstanceName|The name for the Azure IoT Operations Instance resource.|`string`|[format('{0}-ops-instance', parameters('arcConnectedClusterName'))]|no|
|aioDataFlowInstanceConfig|The settings for Azure IoT Operations Data Flow Instances.|`[_1.AioDataFlowInstance](#user-defined-types)`|[variables('_1.aioDataFlowInstanceDefaults')]|no|
|aioMqBrokerConfig|The settings for the Azure IoT Operations MQ Broker.|`[_1.AioMqBroker](#user-defined-types)`|[variables('_1.aioMqBrokerDefaults')]|no|
|brokerListenerAnonymousConfig|Configuration for the insecure anonymous AIO MQ Broker Listener.|`[_1.AioMqBrokerAnonymous](#user-defined-types)`|[variables('_1.aioMqBrokerAnonymousDefaults')]|no|
|schemaRegistryName|The resource name for the ADR Schema Registry for Azure IoT Operations.|`string`|n/a|yes|
|adrNamespaceName|The resource name for the ADR Namespace for Azure IoT Operations.|`string`|n/a|no|
|shouldDeployAio|Whether to deploy an Azure IoT Operations Instance and all of its required components into the connected cluster.|`bool`|`true`|no|
|shouldDeployResourceSyncRules|Whether or not to deploy the Custom Locations Resource Sync Rules for the Azure IoT Operations resources.|`bool`|`true`|no|
|shouldCreateAnonymousBrokerListener|Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)|`bool`|`false`|no|
|shouldEnableOtelCollector|Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.|`bool`|`true`|no|
|shouldEnableOpcUaSimulator|Whether or not to enable the OPC UA Simulator for Azure IoT Operations.|`bool`|`true`|no|
|shouldEnableOpcUaSimulatorAsset|Whether or not to create the OPC UA Simulator ADR Asset for Azure IoT Operations.|`bool`|[parameters('shouldEnableOpcUaSimulator')]|no|
|customLocationName|The name for the Custom Locations resource.|`string`|[format('{0}-cl', parameters('arcConnectedClusterName'))]|no|
|trustIssuerSettings|The trust issuer settings for Customer Managed Azure IoT Operations Settings.|`[_1.TrustIssuerConfig](#user-defined-types)`|{'trustSource': 'SelfSigned'}|no|
|sseKeyVaultName|The name of the Key Vault for Secret Sync. (Required when providing sseIdentityName)|`string`|n/a|yes|
|sseIdentityName|The name of the User Assigned Managed Identity for Secret Sync.|`string`|n/a|yes|
|sseKeyVaultResourceGroupName|The name of the Resource Group for the Key Vault for Secret Sync. (Required when providing sseIdentityName)|`string`|[resourceGroup().name]|no|
|shouldAssignSseKeyVaultRoles|Whether to assign roles for Key Vault to the provided Secret Sync Identity.|`bool`|`true`|no|
|shouldAssignDeployIdentityRoles|Whether to assign roles to the deploy identity.|`bool`|[not(empty(parameters('deployIdentityName')))]|no|
|deployIdentityName|The resource name for a managed identity that will be given deployment admin permissions.|`string`|n/a|no|
|shouldDeployAioDeploymentScripts|Whether to deploy DeploymentScripts for Azure IoT Operations.|`bool`|`false`|no|
|deployKeyVaultName|The name of the Key Vault that will have scripts and secrets for deployment.|`string`|[parameters('sseKeyVaultName')]|no|
|deployKeyVaultResourceGroupName|The resource group name where the Key Vault is located. Defaults to the current resource group.|`string`|[parameters('sseKeyVaultResourceGroupName')]|no|
|deployUserTokenSecretName|The name for the deploy user token secret in Key Vault.|`string`|deploy-user-token|no|
|deploymentScriptsSecretNamePrefix|The prefix used with constructing the secret name that will have the deployment script.|`string`|[format('{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|shouldAddDeployScriptsToKeyVault|Whether to add the deploy scripts for DeploymentScripts to Key Vault as secrets. (Required for DeploymentScripts)|`bool`|`false`|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|`false`|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|deployIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|sseIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|adrNamespace|`Microsoft.DeviceRegistry/namespaces`|2025-07-01-preview|
|deployArcK8sRoleAssignments|`Microsoft.Resources/deployments`|2022-09-01|
|deployKeyVaultRoleAssignments|`Microsoft.Resources/deployments`|2022-09-01|
|sseKeyVaultRoleAssignments|`Microsoft.Resources/deployments`|2022-09-01|
|iotOpsInit|`Microsoft.Resources/deployments`|2022-09-01|
|postInitScriptsSecrets|`Microsoft.Resources/deployments`|2022-09-01|
|postInitScripts|`Microsoft.Resources/deployments`|2022-09-01|
|iotOpsInstance|`Microsoft.Resources/deployments`|2022-09-01|
|postInstanceScriptsSecrets|`Microsoft.Resources/deployments`|2022-09-01|
|postInstanceScripts|`Microsoft.Resources/deployments`|2022-09-01|
|opcUaSimulator|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|deployArcK8sRoleAssignments|Assigns required Azure Arc roles to the deployment identity for cluster access.|
|deployKeyVaultRoleAssignments|Assigns required Key Vault roles to the deployment identity for script execution.|
|sseKeyVaultRoleAssignments|Assigns roles for Secret Sync to access Key Vault.|
|iotOpsInit|Initializes and configures the required Arc extensions for Azure IoT Operations including Secret Store, Open Service Mesh, Container Storage, and IoT Operations Platform.|
|postInitScriptsSecrets|Creates secrets in Key Vault for deployment script setup and initialization for Azure IoT Operations.|
|postInitScripts|Runs deployment scripts for IoT Operations using an Azure deploymentScript resource, including tool installation and script execution.|
|iotOpsInstance|Deploys Azure IoT Operations instance, broker, authentication, listeners, and data flow components on an Azure Arc-enabled Kubernetes cluster.|
|postInstanceScriptsSecrets|Creates secrets in Key Vault for deployment script setup and initialization for Azure IoT Operations.|
|postInstanceScripts|Runs deployment scripts for IoT Operations using an Azure deploymentScript resource, including tool installation and script execution.|
|opcUaSimulator|Deploy and configure the OPC UA Simulator|

## Module Details

### deployArcK8sRoleAssignments

Assigns required Azure Arc roles to the deployment identity for cluster access.

#### Parameters for deployArcK8sRoleAssignments

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|deployIdentityPrincipalId|The principal ID of the deployment identity that will be assigned the role.|`string`|n/a|yes|
|arcConnectedClusterName|The name of the Arc connected cluster.|`string`|n/a|yes|

#### Resources for deployArcK8sRoleAssignments

|Name|Type|API Version|
| :--- | :--- | :--- |
|[guid(resourceGroup().id, parameters('deployIdentityPrincipalId'), '63f0a09d-1495-4db4-a681-037d84835eb4')]|`Microsoft.Authorization/roleAssignments`|2022-04-01|
|[guid(resourceGroup().id, parameters('deployIdentityPrincipalId'), '00493d72-78f6-4148-b6c5-d3ce8e4799dd')]|`Microsoft.Authorization/roleAssignments`|2022-04-01|

#### Outputs for deployArcK8sRoleAssignments

|Name|Type|Description|
| :--- | :--- | :--- |
|arcViewerRoleId|`string`|The ID of the Azure Arc Kubernetes Viewer role assignment.|
|arcClusterUserRoleId|`string`|The ID of the Azure Arc Enabled Kubernetes Cluster User role assignment.|

### deployKeyVaultRoleAssignments

Assigns required Key Vault roles to the deployment identity for script execution.

#### Parameters for deployKeyVaultRoleAssignments

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|deployKeyVaultName|The name of the Key Vault that will have scripts and secrets for deployment.|`string`|n/a|yes|
|deployIdentityPrincipalId|The Principal Id for the Deploy User Assigned Managed Identity.|`string`|n/a|yes|

#### Resources for deployKeyVaultRoleAssignments

|Name|Type|API Version|
| :--- | :--- | :--- |
|[guid(resourceGroup().id, parameters('deployIdentityPrincipalId'), 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')]|`Microsoft.Authorization/roleAssignments`|2022-04-01|

#### Outputs for deployKeyVaultRoleAssignments

|Name|Type|Description|
| :--- | :--- | :--- |
|secretsOfficerRoleId|`string`|The ID of the Key Vault Secrets Officer role assignment.|

### sseKeyVaultRoleAssignments

Assigns roles for Secret Sync to access Key Vault.

#### Parameters for sseKeyVaultRoleAssignments

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|keyVaultName|The name of the Key Vault to scope the role assignments.|`string`|n/a|yes|
|sseIdentityPrincipalId|The Principal ID for the Secret Sync User Assigned Managed Identity.|`string`|n/a|yes|

#### Resources for sseKeyVaultRoleAssignments

|Name|Type|API Version|
| :--- | :--- | :--- |
|[guid(resourceGroup().id, parameters('sseIdentityPrincipalId'), '21090545-7ca7-4776-b22c-e363652d74d2')]|`Microsoft.Authorization/roleAssignments`|2022-04-01|
|[guid(resourceGroup().id, parameters('sseIdentityPrincipalId'), '4633458b-17de-408a-b874-0445c86b69e6')]|`Microsoft.Authorization/roleAssignments`|2022-04-01|

#### Outputs for sseKeyVaultRoleAssignments

|Name|Type|Description|
| :--- | :--- | :--- |
|readerRoleId|`string`|The ID of the Key Vault Reader role assignment.|
|secretsUserRoleId|`string`|The ID of the Key Vault Secrets User role assignment.|

### iotOpsInit

Initializes and configures the required Arc extensions for Azure IoT Operations including Secret Store, Open Service Mesh, Container Storage, and IoT Operations Platform.

#### Parameters for iotOpsInit

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|arcConnectedClusterName|The resource name for the Arc connected cluster.|`string`|n/a|yes|
|containerStorageConfig|The settings for the Azure Container Store for Azure Arc Extension.|`[_1.ContainerStorageExtension](#user-defined-types)`|n/a|yes|
|openServiceMeshConfig|The settings for the Open Service Mesh Extension.|`[_1.OpenServiceMeshExtension](#user-defined-types)`|n/a|yes|
|aioPlatformConfig|The settings for the Azure IoT Operations Platform Extension.|`[_1.AioPlatformExtension](#user-defined-types)`|n/a|yes|
|secretStoreConfig|The settings for the Secret Store Extension.|`[_1.SecretStoreExtension](#user-defined-types)`|n/a|yes|

#### Resources for iotOpsInit

|Name|Type|API Version|
| :--- | :--- | :--- |
|arcConnectedCluster|`Microsoft.Kubernetes/connectedClusters`|2021-03-01|
|aioPlatform|`Microsoft.KubernetesConfiguration/extensions`|2023-05-01|
|openServiceMesh|`Microsoft.KubernetesConfiguration/extensions`|2023-05-01|
|containerStorage|`Microsoft.KubernetesConfiguration/extensions`|2023-05-01|
|secretStore|`Microsoft.KubernetesConfiguration/extensions`|2023-05-01|

#### Outputs for iotOpsInit

|Name|Type|Description|
| :--- | :--- | :--- |
|containerStorageExtensionId|`string`|The ID of the Container Storage Extension.|
|containerStorageExtensionName|`string`|The name of the Container Storage Extension.|
|secretStoreExtensionId|`string`|The ID of the Secret Store Extension.|
|secretStoreExtensionName|`string`|The name of the Secret Store Extension.|
|openServiceMeshExtensionId|`string`|The ID of the Open Service Mesh Extension.|
|openServiceMeshExtensionName|`string`|The name of the Open Service Mesh Extension.|
|aioPlatformExtensionId|`string`|The ID of the Azure IoT Operations Platform Extension.|
|aioPlatformExtensionName|`string`|The name of the Azure IoT Operations Platform Extension.|

### postInitScriptsSecrets

Creates secrets in Key Vault for deployment script setup and initialization for Azure IoT Operations.

#### Parameters for postInitScriptsSecrets

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|arcConnectedClusterName|The name of the Arc connected cluster.|`string`|n/a|yes|
|resourceGroupName|The resource group name where the Arc connected cluster is located.|`string`|n/a|yes|
|aioNamespace|The namespace for Azure IoT Operations in the cluster.|`string`|n/a|yes|
|deployKeyVaultName|The name of the Key Vault that will have scripts and secrets for deployment.|`string`|n/a|yes|
|deployKeyVaultResourceGroupName|The resource group name where the Key Vault is located. Defaults to the current resource group.|`string`|n/a|yes|
|deploySecretNamePrefix|The prefix used with constructing the secret name that will have the deployment script. (e.g., ds-iot-ops-0, ds-iot-ops-1)|`string`|n/a|yes|
|deployUserTokenSecretName|The name of the secret in Key Vault that has the token for the deploy user with cluster-admin role.|`string`|n/a|yes|
|sseKeyVaultName|The name of the existing key vault for Azure IoT Operations instance.|`string`|n/a|yes|
|sseIdentityName|The name of the User Assigned Managed Identity for Secret Sync.|`string`|n/a|yes|
|trustIssuerSettings|The trust issuer settings for Customer Managed Azure IoT Operations Settings.|`[_1.TrustIssuerConfig](#user-defined-types)`|n/a|yes|
|shouldEnableOtelCollector|Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.|`bool`|n/a|yes|

#### Resources for postInitScriptsSecrets

|Name|Type|API Version|
| :--- | :--- | :--- |
|sseIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2024-11-30|
|scriptSecrets|`Microsoft.Resources/deployments`|2022-09-01|

#### Outputs for postInitScriptsSecrets

|Name|Type|Description|
| :--- | :--- | :--- |
|includeFilesSecretName|`string`|The name of the Key Vault include files secret, if created.|
|includeFilesSecretUri|`string`|The URI of the Key Vault include files secret, if created.|
|environmentVariablesSecretName|`string`|The name of the Key Vault environment variables secret, if created.|
|environmentVariablesSecretUri|`string`|The URI of the Key Vault environment variables secret, if created.|
|scriptSecretName|`string`|The name of the Key Vault script secret, if created.|
|scriptSecretUri|`string`|The URI of the Key Vault script secret, if created.|

### postInitScripts

Runs deployment scripts for IoT Operations using an Azure deploymentScript resource, including tool installation and script execution.

#### Parameters for postInitScripts

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|deployIdentityId|The resource ID of the deploy Managed Identity used to execute the scripts.|`string`|n/a|no|
|deploySpClientId|The Client ID for a Service Principal for deployment scripts.|`string`|n/a|no|
|deploySpSecret|The Client Secret for a Service Principal for deployment scripts.|`securestring`|n/a|no|
|deploySpTenantId|The Tenant ID for a Service Principal for deployment scripts.|`string`|n/a|no|
|deployKeyVaultName|The name of the Key Vault that will have scripts and secrets for deployment.|`string`|n/a|yes|
|deploymentScriptsSecretNamePrefix|The prefix used with constructing the secret name that will have the deployment script. (e.g., ds-iot-ops-0, ds-iot-ops-1)|`string`|n/a|yes|
|deploymentScriptName|The name of the DeploymentScript resource.|`string`|[format('ds-{0}', parameters('deploymentScriptsSecretNamePrefix'))]|no|
|scriptSecretNames|The names of Key Vault Secrets with scripts to deploy.|`array`|[]|no|
|environmentVariableSecretNames|The names of Key Vault Secrets with environment variable scripts to deploy.|`array`|[]|no|
|includeFileSecretNames|The names of Key Vault Secrets with include files scripts to deploy.|`array`|[]|no|

#### Resources for postInitScripts

|Name|Type|API Version|
| :--- | :--- | :--- |
|deploymentScript|`Microsoft.Resources/deploymentScripts`|2023-08-01|

#### Outputs for postInitScripts

|Name|Type|Description|
| :--- | :--- | :--- |
|deploymentScriptName|`string`|The name of the deployment script resource.|
|deploymentScriptId|`string`|The ID of the deployment script resource.|

### iotOpsInstance

Deploys Azure IoT Operations instance, broker, authentication, listeners, and data flow components on an Azure Arc-enabled Kubernetes cluster.

#### Parameters for iotOpsInstance

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|arcConnectedClusterName|Name of the existing arc-enabled cluster where AIO will be deployed.|`string`|n/a|yes|
|aioInstanceName|The name for the Azure IoT Operations Instance resource.|`string`|n/a|yes|
|aioIdentityName|The resource name for the User Assigned Identity for Azure IoT Operations.|`string`|n/a|yes|
|aioExtensionConfig|The settings for the Azure IoT Operations Extension.|`[_1.AioExtension](#user-defined-types)`|n/a|yes|
|aioPlatformExtensionId|The resource ID for the Azure IoT Operations Platform Extension.|`string`|n/a|yes|
|aioFeatures||`[_1.AioFeatures](#user-defined-types)`|n/a|no|
|sseIdentityName|The name of the User Assigned Managed Identity for Secret Sync.|`string`|n/a|yes|
|sseKeyVaultName|The name of the Key Vault for Secret Sync.|`string`|n/a|yes|
|secretStoreExtensionId|The resource ID for the Secret Store Extension.|`string`|n/a|yes|
|trustSource|The source for trust for Azure IoT Operations.|`[_1.TrustSource](#user-defined-types)`|n/a|yes|
|trustIssuerSettings|The trust settings for Azure IoT Operations.|`[_1.TrustSettingsConfig](#user-defined-types)`|n/a|no|
|schemaRegistryName|The resource name for the ADR Schema Registry for Azure IoT Operations.|`string`|n/a|yes|
|adrNamespaceId|The resource ID for the ADR Namespace for Azure IoT Operations.|`string`|n/a|no|
|shouldEnableOtelCollector|Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.|`bool`|n/a|yes|
|brokerListenerAnonymousConfig|Configuration for the insecure anonymous AIO MQ Broker Listener.|`[_1.AioMqBrokerAnonymous](#user-defined-types)`|n/a|yes|
|aioMqBrokerConfig|The settings for the Azure IoT Operations MQ Broker.|`[_1.AioMqBroker](#user-defined-types)`|n/a|yes|
|shouldCreateAnonymousBrokerListener|Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)|`bool`|False|no|
|aioDataFlowInstanceConfig|The settings for Azure IoT Operations Data Flow Instances.|`[_1.AioDataFlowInstance](#user-defined-types)`|n/a|yes|
|customLocationName|The name for the Custom Locations resource.|`string`|n/a|yes|
|shouldDeployResourceSyncRules|Whether or not to deploy the Custom Locations Resource Sync Rules for the Azure IoT Operations resources.|`bool`|n/a|yes|

#### Resources for iotOpsInstance

|Name|Type|API Version|
| :--- | :--- | :--- |
|sseIdentity::sseFedCred|`Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials`|2023-01-31|
|aioIdentity::aioFedCred|`Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials`|2023-01-31|
|schemaRegistry|`Microsoft.DeviceRegistry/schemaRegistries`|2024-09-01-preview|
|arcConnectedCluster|`Microsoft.Kubernetes/connectedClusters`|2024-12-01-preview|
|aioExtension|`Microsoft.KubernetesConfiguration/extensions`|2023-05-01|
|customLocation|`Microsoft.ExtendedLocation/customLocations`|2021-08-31-preview|
|aioSyncRule|`Microsoft.ExtendedLocation/customLocations/resourceSyncRules`|2021-08-31-preview|
|adrSyncRule|`Microsoft.ExtendedLocation/customLocations/resourceSyncRules`|2021-08-31-preview|
|sseIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|defaultSecretSyncSecretProviderClass|`Microsoft.SecretSyncController/azureKeyVaultSecretProviderClasses`|2024-08-21-preview|
|aioInstance|`Microsoft.IoTOperations/instances`|2025-07-01-preview|
|broker|`Microsoft.IoTOperations/instances/brokers`|2025-07-01-preview|
|brokerAuthn|`Microsoft.IoTOperations/instances/brokers/authentications`|2025-07-01-preview|
|brokerListener|`Microsoft.IoTOperations/instances/brokers/listeners`|2025-07-01-preview|
|brokerListenerAnonymous|`Microsoft.IoTOperations/instances/brokers/listeners`|2025-07-01-preview|
|dataFlowProfile|`Microsoft.IoTOperations/instances/dataflowProfiles`|2025-07-01-preview|
|dataFlowEndpoint|`Microsoft.IoTOperations/instances/dataflowEndpoints`|2025-07-01-preview|

#### Outputs for iotOpsInstance

|Name|Type|Description|
| :--- | :--- | :--- |
|aioInstanceName|`string`|The name of the deployed Azure IoT Operations Instance.|
|aioInstanceId|`string`|The ID of the deployed Azure IoT Operations Instance.|
|customLocationName|`string`|The name of the deployed Custom Location resource.|
|customLocationId|`string`|The ID of the deployed Custom Location resource.|
|dataFlowProfileName|`string`|The name of the deployed Azure IoT Operations Data Flow Profile.|
|dataFlowProfileId|`string`|The ID of the deployed Azure IoT Operations Data Flow Profile.|
|dataFlowEndpointName|`string`|The name of the deployed Azure IoT Operations Data Flow Endpoint.|
|dataFlowEndpointId|`string`|The ID of the deployed Azure IoT Operations Data Flow Endpoint.|
|aioExtensionName|`string`|The name of the deployed IoT Operations Extension.|
|aioExtensionId|`string`|The ID of the deployed IoT Operations Extension.|
|brokerListenerAnonymousName|`string`|The name of the deployed Anonymous Broker Listener, if created.|
|brokerListenerAnonymousId|`string`|The ID of the deployed Anonymous Broker Listener, if created.|
|aioSyncRuleName|`string`|The name of the deployed AIO Broker Sync Rule, if created.|
|aioSyncRuleId|`string`|The ID of the deployed AIO Broker Sync Rule, if created.|
|adrSyncRuleName|`string`|The name of the deployed ADR Sync Rule, if created.|
|adrSyncRuleId|`string`|The ID of the deployed ADR Sync Rule, if created.|
|brokerName|`string`|The name of the deployed AIO MQ Broker.|
|brokerId|`string`|The ID of the deployed AIO MQ Broker.|
|brokerAuthnName|`string`|The name of the deployed AIO MQ Broker Authentication.|
|brokerAuthnId|`string`|The ID of the deployed AIO MQ Broker Authentication.|
|brokerListenerName|`string`|The name of the deployed AIO MQ Broker Listener.|
|brokerListenerId|`string`|The ID of the deployed AIO MQ Broker Listener.|

### postInstanceScriptsSecrets

Creates secrets in Key Vault for deployment script setup and initialization for Azure IoT Operations.

#### Parameters for postInstanceScriptsSecrets

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|arcConnectedClusterName|The name of the Arc connected cluster.|`string`|n/a|yes|
|resourceGroupName|The resource group name where the Arc connected cluster is located.|`string`|n/a|yes|
|aioNamespace|The namespace for Azure IoT Operations in the cluster.|`string`|n/a|yes|
|deployKeyVaultName|The name of the Key Vault that will have scripts and secrets for deployment.|`string`|n/a|yes|
|deployKeyVaultResourceGroupName|The resource group name where the Key Vault is located. Defaults to the current resource group.|`string`|n/a|yes|
|deploySecretNamePrefix|The prefix used with constructing the secret name that will have the deployment script. (e.g., ds-iot-ops-0, ds-iot-ops-1)|`string`|n/a|yes|
|deployUserTokenSecretName|The name of the secret in Key Vault that has the token for the deploy user with cluster-admin role.|`string`|n/a|yes|
|shouldEnableOpcUaSimulator|Whether or not to enable the OPC UA Simulator for Azure IoT Operations.|`bool`|True|no|

#### Resources for postInstanceScriptsSecrets

|Name|Type|API Version|
| :--- | :--- | :--- |
|scriptSecrets|`Microsoft.Resources/deployments`|2022-09-01|

#### Outputs for postInstanceScriptsSecrets

|Name|Type|Description|
| :--- | :--- | :--- |
|includeFilesSecretName|`string`|The name of the Key Vault include files secret, if created.|
|includeFilesSecretUri|`string`|The URI of the Key Vault include files secret, if created.|
|environmentVariablesSecretName|`string`|The name of the Key Vault environment variables secret, if created.|
|environmentVariablesSecretUri|`string`|The URI of the Key Vault environment variables secret, if created.|
|scriptSecretName|`string`|The name of the Key Vault script secret, if created.|
|scriptSecretUri|`string`|The URI of the Key Vault script secret, if created.|

### postInstanceScripts

Runs deployment scripts for IoT Operations using an Azure deploymentScript resource, including tool installation and script execution.

#### Parameters for postInstanceScripts

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|deployIdentityId|The resource ID of the deploy Managed Identity used to execute the scripts.|`string`|n/a|no|
|deploySpClientId|The Client ID for a Service Principal for deployment scripts.|`string`|n/a|no|
|deploySpSecret|The Client Secret for a Service Principal for deployment scripts.|`securestring`|n/a|no|
|deploySpTenantId|The Tenant ID for a Service Principal for deployment scripts.|`string`|n/a|no|
|deployKeyVaultName|The name of the Key Vault that will have scripts and secrets for deployment.|`string`|n/a|yes|
|deploymentScriptsSecretNamePrefix|The prefix used with constructing the secret name that will have the deployment script. (e.g., ds-iot-ops-0, ds-iot-ops-1)|`string`|n/a|yes|
|deploymentScriptName|The name of the DeploymentScript resource.|`string`|[format('ds-{0}', parameters('deploymentScriptsSecretNamePrefix'))]|no|
|scriptSecretNames|The names of Key Vault Secrets with scripts to deploy.|`array`|[]|no|
|environmentVariableSecretNames|The names of Key Vault Secrets with environment variable scripts to deploy.|`array`|[]|no|
|includeFileSecretNames|The names of Key Vault Secrets with include files scripts to deploy.|`array`|[]|no|

#### Resources for postInstanceScripts

|Name|Type|API Version|
| :--- | :--- | :--- |
|deploymentScript|`Microsoft.Resources/deploymentScripts`|2023-08-01|

#### Outputs for postInstanceScripts

|Name|Type|Description|
| :--- | :--- | :--- |
|deploymentScriptName|`string`|The name of the deployment script resource.|
|deploymentScriptId|`string`|The ID of the deployment script resource.|

### opcUaSimulator

Deploy and configure the OPC UA Simulator

#### Parameters for opcUaSimulator

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|customLocationId|The ID of the custom location.|`string`|n/a|yes|
|adrNamespaceId|The ID of the ADR namespace.|`string`|n/a|yes|

#### Resources for opcUaSimulator

|Name|Type|API Version|
| :--- | :--- | :--- |
|device|`Microsoft.DeviceRegistry/namespaces/devices`|2025-07-01-preview|
|adrNamespace|`Microsoft.DeviceRegistry/namespaces`|2025-07-01-preview|
|asset|`Microsoft.DeviceRegistry/namespaces/assets`|2025-07-01-preview|

#### Outputs for opcUaSimulator

|Name|Type|Description|
| :--- | :--- | :--- |
|deviceId|`string`|The ID of the device.|
|assetId|`string`|The ID of the asset.|

## User Defined Types

### `_1.AioCaConfig`

Configuration for Azure IoT Operations Certificate Authority.

|Property|Type|Description|
| :--- | :--- | :--- |
|rootCaCertPem|`securestring`|The PEM-formatted root CA certificate.|
|caCertChainPem|`securestring`|The PEM-formatted CA certificate chain.|
|caKeyPem|`securestring`|The PEM-formatted CA private key.|

### `_1.AioDataFlowInstance`

The settings for Azure IoT Operations Data Flow Instances.

|Property|Type|Description|
| :--- | :--- | :--- |
|count|`int`|The number of data flow instances.|

### `_1.AioExtension`

The settings for the Azure IoT Operations Extension.

|Property|Type|Description|
| :--- | :--- | :--- |
|release|`[_1.Release](#user-defined-types)`|The common settings for the extension.|
|settings|`object`||

### `_1.AioFeatures`

AIO Instance features.

### `_1.AioMqBroker`

The settings for the Azure IoT Operations MQ Broker.

|Property|Type|Description|
| :--- | :--- | :--- |
|brokerListenerServiceName|`string`|The service name for the broker listener.|
|brokerListenerPort|`int`|The port for the broker listener.|
|serviceAccountAudience|`string`|The audience for the service account.|
|frontendReplicas|`int`|The number of frontend replicas for the broker.|
|frontendWorkers|`int`|The number of frontend workers for the broker.|
|backendRedundancyFactor|`int`|The redundancy factor for the backend of the broker.|
|backendWorkers|`int`|The number of backend workers for the broker.|
|backendPartitions|`int`|The number of partitions for the backend of the broker.|
|memoryProfile|`string`|The memory profile for the broker (Low, Medium, High).|
|serviceType|`string`|The service type for the broker (ClusterIP, LoadBalancer, NodePort).|
|persistence|`[_1.BrokerPersistence](#user-defined-types)`|Broker persistence configuration for disk-backed message storage.|

### `_1.AioMqBrokerAnonymous`

Configuration for the insecure anonymous AIO MQ Broker Listener.

|Property|Type|Description|
| :--- | :--- | :--- |
|serviceName|`string`|The service name for the anonymous broker listener.|
|port|`int`|The port for the anonymous broker listener.|
|nodePort|`int`|The node port for the anonymous broker listener.|

### `_1.AioPlatformExtension`

The settings for the Azure IoT Operations Platform Extension.

|Property|Type|Description|
| :--- | :--- | :--- |
|release|`[_1.Release](#user-defined-types)`|The common settings for the extension.|
|settings|`object`||

### `_1.BrokerPersistence`

Broker persistence configuration for disk-backed message storage.

|Property|Type|Description|
| :--- | :--- | :--- |
|enabled|`bool`|Whether persistence is enabled.|
|maxSize|`string`|Maximum size of the message buffer on disk (e.g., "500M", "1G").|
|encryption|`object`|Encryption configuration for the persistence database.|
|dynamicSettings|`object`|Dynamic settings for MQTTv5 user property-based persistence control.|
|retain|`object`|Controls which retained messages should be persisted to disk.|
|stateStore|`object`|Controls which state store keys should be persisted to disk.|
|subscriberQueue|`object`|Controls which subscriber queues should be persisted to disk.|
|persistentVolumeClaimSpec|`object`|Persistent volume claim specification for storage.|

### `_1.ContainerStorageExtension`

The settings for the Azure Container Store for Azure Arc Extension.

|Property|Type|Description|
| :--- | :--- | :--- |
|release|`[_1.Release](#user-defined-types)`|The common settings for the extension.|
|settings|`object`||

### `_1.CustomerManagedByoIssuerConfig`

The configuration for Customer Managed Bring Your Own Issuer for Azure IoT Operations certificates.

|Property|Type|Description|
| :--- | :--- | :--- |
|trustSource|`string`||
|trustSettings|`[_1.TrustSettingsConfig](#user-defined-types)`|The trust settings for Azure IoT Operations.|

### `_1.CustomerManagedGenerateIssuerConfig`

The configuration for the Customer Managed Generated trust source of Azure IoT Operations certificates.

|Property|Type|Description|
| :--- | :--- | :--- |
|trustSource|`string`||
|aioCa|`[_1.AioCaConfig](#user-defined-types)`|The CA certificate, chain, and key for Azure IoT Operations.|

### `_1.IncludeFileConfig`

Additional file configuration for deployment scripts.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|The name of the file to create.|
|content|`securestring`|The content of the file to create.|

### `_1.InstanceFeature`

Individual feature object within the AIO instance.

|Property|Type|Description|
| :--- | :--- | :--- |
|mode|`[_1.InstanceFeatureMode](#user-defined-types)`||
|settings|`object`||

### `_1.InstanceFeatureMode`

The mode of the AIO instance feature. Either "Stable", "Preview" or "Disabled".

### `_1.InstanceFeatureSettingValue`

The setting value of the AIO instance feature. Either "Enabled" or "Disabled".

### `_1.OpenServiceMeshExtension`

The settings for the Open Service Mesh Extension.

|Property|Type|Description|
| :--- | :--- | :--- |
|release|`[_1.Release](#user-defined-types)`|The common settings for the extension.|

### `_1.Release`

The common settings for Azure Arc Extensions.

|Property|Type|Description|
| :--- | :--- | :--- |
|version|`string`|The version of the extension.|
|train|`string`|The release train that has the version to deploy (ex., "preview", "stable").|

### `_1.ScriptConfig`

Script configuration for deployment scripts.

|Property|Type|Description|
| :--- | :--- | :--- |
|content|`securestring`|The script content to be executed.|
|env|`array`|Environment variables for the script.|

### `_1.ScriptEnvironmentVariable`

Environment variable configuration for scripts.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|The name of the environment variable.|
|value|`string`|The value of the environment variable.|
|secureValue|`securestring`|The secure value of the environment variable.|

### `_1.ScriptFilesConfig`

The script and additional configuration files for deployment scripts.

|Property|Type|Description|
| :--- | :--- | :--- |
|scripts|`array`|The script configuration for deployment scripts.|
|includeFiles|`array`|The additional file configuration for deployment scripts.s|

### `_1.SecretStoreExtension`

The settings for the Secret Store Extension.

|Property|Type|Description|
| :--- | :--- | :--- |
|release|`[_1.Release](#user-defined-types)`|The common settings for the extension.|

### `_1.SelfSignedIssuerConfig`

The configuration for Self-Signed Issuer for Azure IoT Operations certificates.

|Property|Type|Description|
| :--- | :--- | :--- |
|trustSource|`string`||

### `_1.TrustConfigSource`

The config source of trust for how to use or generate Azure IoT Operations certificates.

### `_1.TrustIssuerConfig`

The configuration for the trust source of Azure IoT Operations certificates.

### `_1.TrustSettingsConfig`

The configuration for the trust settings of Azure IoT Operations certificates.

|Property|Type|Description|
| :--- | :--- | :--- |
|issuerName|`string`||
|issuerKind|`string`||
|configMapName|`string`||
|configMapKey|`string`||

### `_1.TrustSource`

The source of trust for Azure IoT Operations certificates.

### `_2.Common`

Common settings for the components.

|Property|Type|Description|
| :--- | :--- | :--- |
|resourcePrefix|`string`|Prefix for all resources in this module|
|location|`string`|Location for all resources in this module|
|environment|`string`|Environment for all resources in this module: dev, test, or prod|
|instance|`string`|Instance identifier for naming resources: 001, 002, etc...|

## Outputs

|Name|Type|Description|
| :--- | :--- | :--- |
|containerStorageExtensionId|`string`|The ID of the Container Storage Extension.|
|containerStorageExtensionName|`string`|The name of the Container Storage Extension.|
|openServiceMeshExtensionId|`string`|The ID of the Open Service Mesh Extension.|
|openServiceMeshExtensionName|`string`|The name of the Open Service Mesh Extension.|
|aioPlatformExtensionId|`string`|The ID of the Azure IoT Operations Platform Extension.|
|aioPlatformExtensionName|`string`|The name of the Azure IoT Operations Platform Extension.|
|secretStoreExtensionId|`string`|The ID of the Secret Store Extension.|
|secretStoreExtensionName|`string`|The name of the Secret Store Extension.|
|customLocationId|`string`|The ID of the deployed Custom Location.|
|customLocationName|`string`|The name of the deployed Custom Location.|
|aioInstanceId|`string`|The ID of the deployed Azure IoT Operations instance.|
|aioInstanceName|`string`|The name of the deployed Azure IoT Operations instance.|
|dataFlowProfileId|`string`|The ID of the deployed Azure IoT Operations Data Flow Profile.|
|dataFlowProfileName|`string`|The name of the deployed Azure IoT Operations Data Flow Profile.|
|dataFlowEndpointId|`string`|The ID of the deployed Azure IoT Operations Data Flow Endpoint.|
|dataFlowEndpointName|`string`|The name of the deployed Azure IoT Operations Data Flow Endpoint.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->