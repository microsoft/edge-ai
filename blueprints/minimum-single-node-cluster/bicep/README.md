<!-- BEGIN_BICEP_DOCS -->
<!-- markdownlint-disable MD033 -->

# Minimum Single Node Cluster Blueprint

Deploys the minimal set of resources required for Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster.

## Parameters

| Name                                | Description                                                                                                                                                                                                                                   | Type                               | Default                                                                                                                          | Required |
|:------------------------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------|:---------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                              | The common component configuration.                                                                                                                                                                                                           | `[_2.Common](#user-defined-types)` | n/a                                                                                                                              | yes      |
| resourceGroupName                   | The name for the resource group. If not provided, a default name will be generated.                                                                                                                                                           | `string`                           | [format('rg-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| telemetry_opt_out                   | Whether to opt-out of telemetry. Set to true to disable telemetry.                                                                                                                                                                            | `bool`                             | `false`                                                                                                                          | no       |
| adminPassword                       | Password used for the host VM.                                                                                                                                                                                                                | `securestring`                     | n/a                                                                                                                              | yes      |
| customLocationsOid                  | The object id of the Custom Locations Entra ID application for your tenant.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre> | `string`                           | n/a                                                                                                                              | yes      |
| shouldCreateAnonymousBrokerListener | Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)                                                                                                                            | `bool`                             | `false`                                                                                                                          | no       |
| shouldInitAio                       | Whether to deploy the Azure IoT Operations initial connected cluster resources, Secret Sync, ACSA, OSM, AIO Platform.                                                                                                                         | `bool`                             | `true`                                                                                                                           | no       |
| shouldDeployAio                     | Whether to deploy an Azure IoT Operations Instance and all of its required components into the connected cluster.                                                                                                                             | `bool`                             | `true`                                                                                                                           | no       |
| namespacedDevices                   | List of namespaced devices to create.                                                                                                                                                                                                         | `array`                            | []                                                                                                                               | no       |
| assetEndpointProfiles               | List of asset endpoint profiles to create.                                                                                                                                                                                                    | `array`                            | []                                                                                                                               | no       |
| legacyAssets                        | List of legacy assets to create.                                                                                                                                                                                                              | `array`                            | []                                                                                                                               | no       |
| namespacedAssets                    | List of namespaced assets to create.                                                                                                                                                                                                          | `array`                            | []                                                                                                                               | no       |
| shouldCreateDefaultNamespacedAsset  | Whether to create a default namespaced asset and device.                                                                                                                                                                                      | `bool`                             | `true`                                                                                                                           | no       |

## Resources

| Name                  | Type                              | API Version |
|:----------------------|:----------------------------------|:------------|
| cloudResourceGroup    | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudSecurityIdentity | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudData             | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudNetworking       | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudVmHost           | `Microsoft.Resources/deployments` | 2025-04-01  |
| edgeCncfCluster       | `Microsoft.Resources/deployments` | 2025-04-01  |
| edgeIotOps            | `Microsoft.Resources/deployments` | 2025-04-01  |
| edgeAssets            | `Microsoft.Resources/deployments` | 2025-04-01  |

## Modules

| Name                  | Description                                                                                                                                                                                                                                                                                                      |
|:----------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| cloudResourceGroup    | Creates the required resources needed for an edge IaC deployment.                                                                                                                                                                                                                                                |
| cloudSecurityIdentity | Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.                                                                                                                                                        |
| cloudData             | Creates storage resources including Azure Storage Account and Schema Registry for data in the Edge AI solution.                                                                                                                                                                                                  |
| cloudNetworking       | Creates virtual network, subnet, and network security group resources for Azure deployments.                                                                                                                                                                                                                     |
| cloudVmHost           | Provisions virtual machines and networking infrastructure for hosting Azure IoT Operations edge deployments.                                                                                                                                                                                                     |
| edgeCncfCluster       | This module provisions and deploys automation scripts to a VM host that create and configure a K3s Kubernetes cluster with Arc connectivity.<br>The scripts handle primary and secondary node(s) setup, cluster administration, workload identity enablement, and installation of required Azure Arc extensions. |
| edgeIotOps            | Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.                                                                                                                                                                                                 |
| edgeAssets            | Deploys Kubernetes asset definitions to a connected cluster using the namespaced Device Registry model. This component facilitates the management of devices and assets within ADR namespaces.                                                                                                                   |

## Module Details

### cloudResourceGroup

Creates the required resources needed for an edge IaC deployment.

#### Parameters for cloudResourceGroup

| Name                     | Description                                                                         | Type                               | Default                                                                                                                          | Required |
|:-------------------------|:------------------------------------------------------------------------------------|:-----------------------------------|:---------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                   | The common component configuration.                                                 | `[_1.Common](#user-defined-types)` | n/a                                                                                                                              | yes      |
| resourceGroupName        | The name for the resource group. If not provided, a default name will be generated. | `string`                           | [format('rg-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| useExistingResourceGroup | Whether to use an existing resource group instead of creating a new one.            | `bool`                             | `false`                                                                                                                          | no       |
| telemetry_opt_out        | Whether to opt out of telemetry data collection.                                    | `bool`                             | `false`                                                                                                                          | no       |
| tags                     | Additional tags to add to the resources.                                            | `object`                           | {}                                                                                                                               | no       |

#### Outputs for cloudResourceGroup

| Name              | Type     | Description                         |
|:------------------|:---------|:------------------------------------|
| resourceGroupId   | `string` | The ID of the resource group.       |
| resourceGroupName | `string` | The name of the resource group.     |
| location          | `string` | The location of the resource group. |

### cloudSecurityIdentity

Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.

#### Parameters for cloudSecurityIdentity

| Name                                    | Description                                                                                | Type                               | Default                                                                                                                          | Required |
|:----------------------------------------|:-------------------------------------------------------------------------------------------|:-----------------------------------|:---------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                                  | The common component configuration.                                                        | `[_1.Common](#user-defined-types)` | n/a                                                                                                                              | yes      |
| shouldCreateArcOnboardingUami           | Whether to create a User Assigned Managed Identity for onboarding a cluster to Azure Arc.  | `bool`                             | `true`                                                                                                                           | no       |
| shouldCreateKeyVault                    | Whether or not to create a new Key Vault for the Secret Sync Extension.                    | `bool`                             | `true`                                                                                                                           | no       |
| keyVaultName                            | The name of the Key Vault.                                                                 | `string`                           | [format('kv-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| keyVaultResourceGroupName               | The name for the Resource Group for the Key Vault.                                         | `string`                           | [resourceGroup().name]                                                                                                           | no       |
| shouldAssignAdminUserRole               | Whether or not to create a role assignment for an admin user.                              | `bool`                             | `true`                                                                                                                           | no       |
| adminUserObjectId                       | The Object ID for an admin user that will be granted the "Key Vault Secrets Officer" role. | `string`                           | [deployer().objectId]                                                                                                            | no       |
| shouldCreateKeyVaultPrivateEndpoint     | Whether to create a private endpoint for the Key Vault.                                    | `bool`                             | `false`                                                                                                                          | no       |
| keyVaultPrivateEndpointSubnetId         | Subnet resource ID for the Key Vault private endpoint.                                     | `string`                           | n/a                                                                                                                              | no       |
| keyVaultVirtualNetworkId                | Virtual network resource ID for the Key Vault private DNS link.                            | `string`                           | n/a                                                                                                                              | no       |
| shouldEnableKeyVaultPublicNetworkAccess | Whether to enable public network access on the Key Vault.                                  | `bool`                             | `true`                                                                                                                           | no       |
| telemetry_opt_out                       | Whether to opt out of telemetry data collection.                                           | `bool`                             | `false`                                                                                                                          | no       |

#### Resources for cloudSecurityIdentity

| Name     | Type                              | API Version |
|:---------|:----------------------------------|:------------|
| identity | `Microsoft.Resources/deployments` | 2025-04-01  |
| keyVault | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for cloudSecurityIdentity

| Name                        | Type     | Description                                                                                           |
|:----------------------------|:---------|:------------------------------------------------------------------------------------------------------|
| keyVaultName                | `string` | The name of the Secret Store Extension Key Vault.                                                     |
| keyVaultId                  | `string` | The resource ID of the Secret Store Extension Key Vault.                                              |
| keyVaultPrivateEndpointId   | `string` | The Key Vault private endpoint ID when created.                                                       |
| keyVaultPrivateEndpointName | `string` | The Key Vault private endpoint name when created.                                                     |
| keyVaultPrivateEndpointIp   | `string` | The Key Vault private endpoint IP address when created.                                               |
| keyVaultPrivateDnsZoneId    | `string` | The Key Vault private DNS zone ID when created.                                                       |
| keyVaultPrivateDnsZoneName  | `string` | The Key Vault private DNS zone name when created.                                                     |
| sseIdentityName             | `string` | The Secret Store Extension User Assigned Managed Identity name.                                       |
| sseIdentityId               | `string` | The Secret Store Extension User Assigned Managed Identity ID.                                         |
| sseIdentityPrincipalId      | `string` | The Secret Store Extension User Assigned Managed Identity Principal ID.                               |
| aioIdentityName             | `string` | The Azure IoT Operations User Assigned Managed Identity name.                                         |
| aioIdentityId               | `string` | The Azure IoT Operations User Assigned Managed Identity ID.                                           |
| aioIdentityPrincipalId      | `string` | The Azure IoT Operations User Assigned Managed Identity Principal ID.                                 |
| deployIdentityName          | `string` | The Deployment User Assigned Managed Identity name.                                                   |
| deployIdentityId            | `string` | The Deployment User Assigned Managed Identity ID.                                                     |
| deployIdentityPrincipalId   | `string` | The Deployment User Assigned Managed Identity Principal ID.                                           |
| arcOnboardingIdentityId     | `string` | The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.   |
| arcOnboardingIdentityName   | `string` | The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions. |

### cloudData

Creates storage resources including Azure Storage Account and Schema Registry for data in the Edge AI solution.

#### Parameters for cloudData

| Name                                   | Description                                                                                                        | Type                                                       | Default                                                                                                                                                                         | Required |
|:---------------------------------------|:-------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                                 | The common component configuration.                                                                                | `[_2.Common](#user-defined-types)`                         | n/a                                                                                                                                                                             | yes      |
| shouldCreateStorageAccount             | Whether to create the Storage Account.                                                                             | `bool`                                                     | `true`                                                                                                                                                                          | no       |
| storageAccountResourceGroupName        | The name for the Resource Group for the Storage Account.                                                           | `string`                                                   | [if(parameters('shouldCreateStorageAccount'), resourceGroup().name, fail('storageAccountResourceGroupName required when shouldCreateStorageAccount is false'))]                 | no       |
| storageAccountName                     | The name for the Storage Account used by the Schema Registry.                                                      | `string`                                                   | [if(parameters('shouldCreateStorageAccount'), format('st{0}', uniqueString(resourceGroup().id)), fail('storageAccountName required when shouldCreateStorageAccount is false'))] | no       |
| storageAccountSettings                 | The settings for the new Storage Account.                                                                          | `[_1.StorageAccountSettings](#user-defined-types)`         | [variables('_1.storageAccountSettingsDefaults')]                                                                                                                                | no       |
| shouldEnableStoragePrivateEndpoint     | Whether to enable a private endpoint for the Storage Account.                                                      | `bool`                                                     | `false`                                                                                                                                                                         | no       |
| storagePrivateEndpointSubnetId         | Subnet resource ID used when deploying the Storage Account private endpoint.                                       | `string`                                                   | n/a                                                                                                                                                                             | no       |
| storageVirtualNetworkId                | Virtual network resource ID for Storage Account private DNS links.                                                 | `string`                                                   | n/a                                                                                                                                                                             | no       |
| shouldEnableStoragePublicNetworkAccess | Whether to enable public network access for the Storage Account.                                                   | `bool`                                                     | `true`                                                                                                                                                                          | no       |
| shouldCreateBlobPrivateDnsZone         | Whether to create the blob private DNS zone. Set to false if using a shared DNS zone from observability component. | `bool`                                                     | `true`                                                                                                                                                                          | no       |
| blobPrivateDnsZoneId                   | Existing blob Private DNS zone ID to reuse when private endpoints are enabled.                                     | `string`                                                   | n/a                                                                                                                                                                             | no       |
| shouldCreateSchemaRegistry             | Whether to create the ADR Schema Registry.                                                                         | `bool`                                                     | `true`                                                                                                                                                                          | no       |
| shouldCreateSchemaContainer            | Whether to create the Blob Container for schemas.                                                                  | `bool`                                                     | `true`                                                                                                                                                                          | no       |
| schemaContainerName                    | The name for the Blob Container for schemas.                                                                       | `string`                                                   | schemas                                                                                                                                                                         | no       |
| schemaRegistryName                     | The name for the ADR Schema Registry.                                                                              | `string`                                                   | [format('sr-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]                                                | no       |
| schemaRegistryNamespace                | The ADLS Gen2 namespace for the ADR Schema Registry.                                                               | `string`                                                   | [format('srns-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]                                              | no       |
| shouldCreateAdrNamespace               | Whether to create the ADR Namespace.                                                                               | `bool`                                                     | `true`                                                                                                                                                                          | no       |
| adrNamespaceName                       | The name for the ADR Namespace.                                                                                    | `string`                                                   | [format('adrns-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]                                             | no       |
| adrNamespaceMessagingEndpoints         | Dictionary of messaging endpoints for the ADR namespace.                                                           | `[_1.AdrNamespaceMessagingEndpoints](#user-defined-types)` | n/a                                                                                                                                                                             | no       |
| adrNamespaceEnableIdentity             | Whether to enable system-assigned managed identity for the ADR namespace.                                          | `bool`                                                     | `true`                                                                                                                                                                          | no       |
| telemetry_opt_out                      | Whether to opt out of telemetry data collection.                                                                   | `bool`                                                     | `false`                                                                                                                                                                         | no       |

#### Resources for cloudData

| Name                         | Type                              | API Version |
|:-----------------------------|:----------------------------------|:------------|
| storageAccount               | `Microsoft.Resources/deployments` | 2025-04-01  |
| schemaRegistry               | `Microsoft.Resources/deployments` | 2025-04-01  |
| schemaRegistryRoleAssignment | `Microsoft.Resources/deployments` | 2025-04-01  |
| adrNamespace                 | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for cloudData

| Name                         | Type     | Description                                                                |
|:-----------------------------|:---------|:---------------------------------------------------------------------------|
| schemaRegistryName           | `string` | The ADR Schema Registry Name.                                              |
| schemaRegistryId             | `string` | The ADR Schema Registry ID.                                                |
| storageAccountName           | `string` | The Storage Account Name.                                                  |
| storageAccountId             | `string` | The Storage Account ID.                                                    |
| schemaContainerName          | `string` | The Schema Container Name.                                                 |
| storageBlobPrivateEndpointId | `string` | The blob private endpoint ID for the Storage Account when created.         |
| storageBlobPrivateEndpointIp | `string` | The blob private endpoint IP address for the Storage Account when created. |
| blobPrivateDnsZoneId         | `string` | The blob private DNS zone ID when managed by this component.               |
| blobPrivateDnsZoneName       | `string` | The blob private DNS zone name when managed by this component.             |
| adrNamespaceName             | `string` | The ADR Namespace Name.                                                    |
| adrNamespaceId               | `string` | The ADR Namespace ID.                                                      |
| adrNamespace                 | `object` | The complete ADR namespace resource information.                           |

### cloudNetworking

Creates virtual network, subnet, and network security group resources for Azure deployments.

#### Parameters for cloudNetworking

| Name                         | Description                                             | Type                                              | Default                                         | Required |
|:-----------------------------|:--------------------------------------------------------|:--------------------------------------------------|:------------------------------------------------|:---------|
| common                       | The common component configuration.                     | `[_2.Common](#user-defined-types)`                | n/a                                             | yes      |
| networkingConfig             | Networking configuration settings.                      | `[_1.NetworkingConfig](#user-defined-types)`      | [variables('_1.networkingConfigDefaults')]      | no       |
| natGatewayConfig             | NAT Gateway configuration settings.                     | `[_1.NatGatewayConfig](#user-defined-types)`      | [variables('_1.natGatewayConfigDefaults')]      | no       |
| privateResolverConfig        | Private DNS Resolver configuration settings.            | `[_1.PrivateResolverConfig](#user-defined-types)` | [variables('_1.privateResolverConfigDefaults')] | no       |
| defaultOutboundAccessEnabled | Whether default outbound access is enabled for subnets. | `bool`                                            | `false`                                         | no       |
| telemetry_opt_out            | Whether to opt out of telemetry data collection.        | `bool`                                            | `false`                                         | no       |

#### Resources for cloudNetworking

| Name            | Type                                        | API Version |
|:----------------|:--------------------------------------------|:------------|
| virtualNetwork  | `Microsoft.Network/virtualNetworks`         | 2025-01-01  |
| defaultSubnet   | `Microsoft.Network/virtualNetworks/subnets` | 2025-01-01  |
| natGateway      | `Microsoft.Resources/deployments`           | 2025-04-01  |
| privateResolver | `Microsoft.Resources/deployments`           | 2025-04-01  |

#### Outputs for cloudNetworking

| Name                         | Type     | Description                                                               |
|:-----------------------------|:---------|:--------------------------------------------------------------------------|
| networkSecurityGroupId       | `string` | The ID of the created network security group.                             |
| networkSecurityGroupName     | `string` | The name of the created network security group.                           |
| subnetId                     | `string` | The ID of the created subnet.                                             |
| subnetName                   | `string` | The name of the created subnet.                                           |
| virtualNetworkId             | `string` | The ID of the created virtual network.                                    |
| virtualNetworkName           | `string` | The name of the created virtual network.                                  |
| natGatewayId                 | `string` | The ID of the NAT Gateway (if enabled).                                   |
| natGatewayName               | `string` | The name of the NAT Gateway (if enabled).                                 |
| natGatewayPublicIps          | `array`  | The public IP addresses associated with NAT Gateway (if enabled).         |
| privateResolverId            | `string` | The Private DNS Resolver ID (if enabled).                                 |
| privateResolverName          | `string` | The Private DNS Resolver name (if enabled).                               |
| dnsServerIp                  | `string` | The DNS server IP address from Private Resolver (if enabled).             |
| defaultOutboundAccessEnabled | `bool`   | Whether default outbound access remains enabled for the shared subnet(s). |
| subnetAddressPrefix          | `string` | The address prefix allocated to the default subnet.                       |
| virtualNetworkAddressPrefix  | `string` | The address prefix allocated to the virtual network.                      |

### cloudVmHost

Provisions virtual machines and networking infrastructure for hosting Azure IoT Operations edge deployments.

#### Parameters for cloudVmHost

| Name                      | Description                                                                                                                         | Type                                       | Default                                  | Required |
|:--------------------------|:------------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------------|:-----------------------------------------|:---------|
| common                    | The common component configuration.                                                                                                 | `[_2.Common](#user-defined-types)`         | n/a                                      | yes      |
| adminPassword             | The admin password for the VM.                                                                                                      | `securestring`                             | n/a                                      | yes      |
| arcOnboardingIdentityName | The user-assigned identity for Arc onboarding.                                                                                      | `string`                                   | n/a                                      | no       |
| storageProfile            | The storage profile for the VM.                                                                                                     | `[_1.StorageProfile](#user-defined-types)` | [variables('_1.storageProfileDefaults')] | no       |
| vmUsername                | Username used for the host VM that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user) | `string`                                   | n/a                                      | no       |
| vmCount                   | The number of host VMs to create if a multi-node cluster is needed.                                                                 | `int`                                      | 1                                        | no       |
| vmSkuSize                 | Size of the VM.                                                                                                                     | `string`                                   | Standard_D8s_v3                          | no       |
| telemetry_opt_out         | Whether to opt out of telemetry data collection.                                                                                    | `bool`                                     | `false`                                  | no       |
| subnetId                  | The subnet ID to connect the VMs to.                                                                                                | `string`                                   | n/a                                      | yes      |

#### Resources for cloudVmHost

| Name           | Type                              | API Version |
|:---------------|:----------------------------------|:------------|
| virtualMachine | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for cloudVmHost

| Name               | Type     | Description                                                       |
|:-------------------|:---------|:------------------------------------------------------------------|
| adminUsername      | `string` | The admin username for SSH access to the VMs.                     |
| privateIpAddresses | `array`  | An array containing the private IP addresses of all deployed VMs. |
| publicFqdns        | `array`  | An array containing the public FQDNs of all deployed VMs.         |
| publicIpAddresses  | `array`  | An array containing the public IP addresses of all deployed VMs.  |
| vmIds              | `array`  | An array containing the IDs of all deployed VMs.                  |
| vmNames            | `array`  | An array containing the names of all deployed VMs.                |

### edgeCncfCluster

This module provisions and deploys automation scripts to a VM host that create and configure a K3s Kubernetes cluster with Arc connectivity.
The scripts handle primary and secondary node(s) setup, cluster administration, workload identity enablement, and installation of required Azure Arc extensions.

#### Parameters for edgeCncfCluster

| Name                             | Description                                                                                                                                                                                                                                   | Type                               | Default                                                                                                                            | Required |
|:---------------------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                           | The common component configuration.                                                                                                                                                                                                           | `[_1.Common](#user-defined-types)` | n/a                                                                                                                                | yes      |
| arcConnectedClusterName          | The resource name for the Arc connected cluster.                                                                                                                                                                                              | `string`                           | [format('arck-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| arcOnboardingSpClientId          | Service Principal Client ID with Kubernetes Cluster - Azure Arc Onboarding permissions.                                                                                                                                                       | `string`                           | n/a                                                                                                                                | no       |
| arcOnboardingSpClientSecret      | The Service Principal Client Secret for Arc onboarding.                                                                                                                                                                                       | `securestring`                     | n/a                                                                                                                                | no       |
| arcOnboardingSpPrincipalId       | Service Principal Object Id used when assigning roles for Arc onboarding.                                                                                                                                                                     | `string`                           | n/a                                                                                                                                | no       |
| arcOnboardingIdentityName        | The resource name for the identity used for Arc onboarding.                                                                                                                                                                                   | `string`                           | n/a                                                                                                                                | no       |
| customLocationsOid               | The object id of the Custom Locations Entra ID application for your tenant.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre> | `string`                           | n/a                                                                                                                                | yes      |
| shouldAddCurrentUserClusterAdmin | Whether to add the current user as a cluster admin.                                                                                                                                                                                           | `bool`                             | `true`                                                                                                                             | no       |
| shouldEnableArcAutoUpgrade       | Whether to enable auto-upgrade for Azure Arc agents.                                                                                                                                                                                          | `bool`                             | [not(equals(parameters('common').environment, 'prod'))]                                                                            | no       |
| clusterAdminOid                  | The Object ID that will be given cluster-admin permissions.                                                                                                                                                                                   | `string`                           | n/a                                                                                                                                | no       |
| clusterAdminUpn                  | The User Principal Name that will be given cluster-admin permissions.                                                                                                                                                                         | `string`                           | n/a                                                                                                                                | no       |
| clusterNodeVirtualMachineNames   | The node virtual machines names.                                                                                                                                                                                                              | `array`                            | n/a                                                                                                                                | no       |
| clusterServerVirtualMachineName  | The server virtual machines name.                                                                                                                                                                                                             | `string`                           | n/a                                                                                                                                | no       |
| clusterServerHostMachineUsername | Username used for the host machines that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)                                                                                                     | `string`                           | [parameters('common').resourcePrefix]                                                                                              | no       |
| clusterServerIp                  | The IP address for the server for the cluster. (Needed for mult-node cluster)                                                                                                                                                                 | `string`                           | n/a                                                                                                                                | no       |
| serverToken                      | The token that will be given to the server for the cluster or used by agent nodes.                                                                                                                                                            | `securestring`                     | n/a                                                                                                                                | no       |
| shouldAssignRoles                | Whether to assign roles for Arc Onboarding.                                                                                                                                                                                                   | `bool`                             | `true`                                                                                                                             | no       |
| shouldDeployScriptToVm           | Whether to deploy the scripts to the VM.                                                                                                                                                                                                      | `bool`                             | `true`                                                                                                                             | no       |
| shouldSkipInstallingAzCli        | Should skip downloading and installing Azure CLI on the server.                                                                                                                                                                               | `bool`                             | `false`                                                                                                                            | no       |
| shouldSkipAzCliLogin             | Should skip login process with Azure CLI on the server.                                                                                                                                                                                       | `bool`                             | `false`                                                                                                                            | no       |
| deployUserTokenSecretName        | The name for the deploy user token secret in Key Vault.                                                                                                                                                                                       | `string`                           | deploy-user-token                                                                                                                  | no       |
| deployKeyVaultName               | The name of the Key Vault that will have scripts and secrets for deployment.                                                                                                                                                                  | `string`                           | n/a                                                                                                                                | yes      |
| deployKeyVaultResourceGroupName  | The resource group name where the Key Vault is located. Defaults to the current resource group.                                                                                                                                               | `string`                           | [resourceGroup().name]                                                                                                             | no       |
| k3sTokenSecretName               | The name for the K3s token secret in Key Vault.                                                                                                                                                                                               | `string`                           | k3s-server-token                                                                                                                   | no       |
| nodeScriptSecretName             | The name for the node script secret in Key Vault.                                                                                                                                                                                             | `string`                           | cluster-node-ubuntu-k3s                                                                                                            | no       |
| serverScriptSecretName           | The name for the server script secret in Key Vault.                                                                                                                                                                                           | `string`                           | cluster-server-ubuntu-k3s                                                                                                          | no       |
| telemetry_opt_out                | Whether to opt out of telemetry data collection.                                                                                                                                                                                              | `bool`                             | `false`                                                                                                                            | no       |

#### Resources for edgeCncfCluster

| Name                    | Type                              | API Version |
|:------------------------|:----------------------------------|:------------|
| ubuntuK3s               | `Microsoft.Resources/deployments` | 2025-04-01  |
| roleAssignment          | `Microsoft.Resources/deployments` | 2025-04-01  |
| keyVaultRoleAssignments | `Microsoft.Resources/deployments` | 2025-04-01  |
| deployScriptsToVm       | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for edgeCncfCluster

| Name                                 | Type     | Description                                                        |
|:-------------------------------------|:---------|:-------------------------------------------------------------------|
| connectedClusterName                 | `string` | The connected cluster name                                         |
| connectedClusterResourceGroupName    | `string` | The connected cluster resource group name                          |
| azureArcProxyCommand                 | `string` | Azure Arc proxy command for accessing the cluster                  |
| clusterServerScriptSecretName        | `string` | The name of the Key Vault secret containing the server script      |
| clusterNodeScriptSecretName          | `string` | The name of the Key Vault secret containing the node script        |
| clusterServerScriptSecretShowCommand | `string` | The AZ CLI command to get the cluster server script from Key Vault |
| clusterNodeScriptSecretShowCommand   | `string` | The AZ CLI command to get the cluster node script from Key Vault   |

### edgeIotOps

Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.

#### Parameters for edgeIotOps

| Name                                | Description                                                                                                                                                  | Type                                                  | Default                                                                                                                       | Required |
|:------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                              | The common component configuration.                                                                                                                          | `[_2.Common](#user-defined-types)`                    | n/a                                                                                                                           | yes      |
| arcConnectedClusterName             | The resource name for the Arc connected cluster.                                                                                                             | `string`                                              | n/a                                                                                                                           | yes      |
| containerStorageConfig              | The settings for the Azure Container Store for Azure Arc Extension.                                                                                          | `[_1.ContainerStorageExtension](#user-defined-types)` | [variables('_1.containerStorageExtensionDefaults')]                                                                           | no       |
| aioCertManagerConfig                | The settings for the Azure IoT Operations Platform Extension.                                                                                                | `[_1.AioCertManagerExtension](#user-defined-types)`   | [variables('_1.aioCertManagerExtensionDefaults')]                                                                             | no       |
| secretStoreConfig                   | The settings for the Secret Store Extension.                                                                                                                 | `[_1.SecretStoreExtension](#user-defined-types)`      | [variables('_1.secretStoreExtensionDefaults')]                                                                                | no       |
| shouldInitAio                       | Whether to deploy the Azure IoT Operations initial connected cluster resources, Secret Sync, ACSA, OSM, AIO Platform.                                        | `bool`                                                | `true`                                                                                                                        | no       |
| aioIdentityName                     | The name of the User Assigned Managed Identity for Azure IoT Operations.                                                                                     | `string`                                              | n/a                                                                                                                           | yes      |
| aioExtensionConfig                  | The settings for the Azure IoT Operations Extension.                                                                                                         | `[_1.AioExtension](#user-defined-types)`              | [variables('_1.aioExtensionDefaults')]                                                                                        | no       |
| aioFeatures                         | AIO Instance features.                                                                                                                                       | `[_1.AioFeatures](#user-defined-types)`               | n/a                                                                                                                           | no       |
| aioInstanceName                     | The name for the Azure IoT Operations Instance resource.                                                                                                     | `string`                                              | [format('{0}-ops-instance', parameters('arcConnectedClusterName'))]                                                           | no       |
| aioDataFlowInstanceConfig           | The settings for Azure IoT Operations Data Flow Instances.                                                                                                   | `[_1.AioDataFlowInstance](#user-defined-types)`       | [variables('_1.aioDataFlowInstanceDefaults')]                                                                                 | no       |
| aioMqBrokerConfig                   | The settings for the Azure IoT Operations MQ Broker.                                                                                                         | `[_1.AioMqBroker](#user-defined-types)`               | [variables('_1.aioMqBrokerDefaults')]                                                                                         | no       |
| brokerListenerAnonymousConfig       | Configuration for the insecure anonymous AIO MQ Broker Listener.                                                                                             | `[_1.AioMqBrokerAnonymous](#user-defined-types)`      | [variables('_1.aioMqBrokerAnonymousDefaults')]                                                                                | no       |
| configurationSettingsOverride       | Optional configuration settings to override default IoT Operations extension configuration. Use the same key names as the az iot ops --ops-config parameter. | `object`                                              | {}                                                                                                                            | no       |
| schemaRegistryName                  | The resource name for the ADR Schema Registry for Azure IoT Operations.                                                                                      | `string`                                              | n/a                                                                                                                           | yes      |
| adrNamespaceName                    | The resource name for the ADR Namespace for Azure IoT Operations.                                                                                            | `string`                                              | n/a                                                                                                                           | no       |
| shouldDeployAio                     | Whether to deploy an Azure IoT Operations Instance and all of its required components into the connected cluster.                                            | `bool`                                                | `true`                                                                                                                        | no       |
| shouldDeployResourceSyncRules       | Whether or not to deploy the Custom Locations Resource Sync Rules for the Azure IoT Operations resources.                                                    | `bool`                                                | `true`                                                                                                                        | no       |
| shouldCreateAnonymousBrokerListener | Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)                                           | `bool`                                                | `false`                                                                                                                       | no       |
| shouldEnableOtelCollector           | Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.                                                                              | `bool`                                                | `true`                                                                                                                        | no       |
| shouldEnableOpcUaSimulator          | Whether or not to enable the OPC UA Simulator for Azure IoT Operations.                                                                                      | `bool`                                                | `true`                                                                                                                        | no       |
| shouldEnableAkriRestConnector       | Deploy Akri REST HTTP Connector template to the IoT Operations instance.                                                                                     | `bool`                                                | `false`                                                                                                                       | no       |
| shouldEnableAkriMediaConnector      | Deploy Akri Media Connector template to the IoT Operations instance.                                                                                         | `bool`                                                | `false`                                                                                                                       | no       |
| shouldEnableAkriOnvifConnector      | Deploy Akri ONVIF Connector template to the IoT Operations instance.                                                                                         | `bool`                                                | `false`                                                                                                                       | no       |
| shouldEnableAkriSseConnector        | Deploy Akri SSE Connector template to the IoT Operations instance.                                                                                           | `bool`                                                | `false`                                                                                                                       | no       |
| customAkriConnectors                | List of custom Akri connector templates with user-defined endpoint types and container images.                                                               | `array`                                               | []                                                                                                                            | no       |
| akriMqttSharedConfig                | Shared MQTT connection configuration for all Akri connectors.                                                                                                | `[_1.AkriMqttConfig](#user-defined-types)`            | {'host': 'aio-broker:18883', 'audience': 'aio-internal', 'caConfigmap': 'azure-iot-operations-aio-ca-trust-bundle'}           | no       |
| customLocationName                  | The name for the Custom Locations resource.                                                                                                                  | `string`                                              | [format('{0}-cl', parameters('arcConnectedClusterName'))]                                                                     | no       |
| additionalClusterExtensionIds       | Additional cluster extension IDs to include in the custom location. (Appended to the default Secret Store and IoT Operations extension IDs)                  | `array`                                               | []                                                                                                                            | no       |
| trustIssuerSettings                 | The trust issuer settings for Customer Managed Azure IoT Operations Settings.                                                                                | `[_1.TrustIssuerConfig](#user-defined-types)`         | {'trustSource': 'SelfSigned'}                                                                                                 | no       |
| sseKeyVaultName                     | The name of the Key Vault for Secret Sync. (Required when providing sseIdentityName)                                                                         | `string`                                              | n/a                                                                                                                           | yes      |
| sseIdentityName                     | The name of the User Assigned Managed Identity for Secret Sync.                                                                                              | `string`                                              | n/a                                                                                                                           | yes      |
| sseKeyVaultResourceGroupName        | The name of the Resource Group for the Key Vault for Secret Sync. (Required when providing sseIdentityName)                                                  | `string`                                              | [resourceGroup().name]                                                                                                        | no       |
| shouldAssignSseKeyVaultRoles        | Whether to assign roles for Key Vault to the provided Secret Sync Identity.                                                                                  | `bool`                                                | `true`                                                                                                                        | no       |
| shouldAssignDeployIdentityRoles     | Whether to assign roles to the deploy identity.                                                                                                              | `bool`                                                | [not(empty(parameters('deployIdentityName')))]                                                                                | no       |
| deployIdentityName                  | The resource name for a managed identity that will be given deployment admin permissions.                                                                    | `string`                                              | n/a                                                                                                                           | no       |
| shouldDeployAioDeploymentScripts    | Whether to deploy DeploymentScripts for Azure IoT Operations.                                                                                                | `bool`                                                | `false`                                                                                                                       | no       |
| deployKeyVaultName                  | The name of the Key Vault that will have scripts and secrets for deployment.                                                                                 | `string`                                              | [parameters('sseKeyVaultName')]                                                                                               | no       |
| deployKeyVaultResourceGroupName     | The resource group name where the Key Vault is located. Defaults to the current resource group.                                                              | `string`                                              | [parameters('sseKeyVaultResourceGroupName')]                                                                                  | no       |
| deployUserTokenSecretName           | The name for the deploy user token secret in Key Vault.                                                                                                      | `string`                                              | deploy-user-token                                                                                                             | no       |
| deploymentScriptsSecretNamePrefix   | The prefix used with constructing the secret name that will have the deployment script.                                                                      | `string`                                              | [format('{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| shouldAddDeployScriptsToKeyVault    | Whether to add the deploy scripts for DeploymentScripts to Key Vault as secrets. (Required for DeploymentScripts)                                            | `bool`                                                | `false`                                                                                                                       | no       |
| telemetry_opt_out                   | Whether to opt out of telemetry data collection.                                                                                                             | `bool`                                                | `false`                                                                                                                       | no       |

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
| postInstanceScriptsSecrets    | `Microsoft.Resources/deployments` | 2025-04-01  |
| postInstanceScripts           | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for edgeIotOps

| Name                          | Type     | Description                                                        |
|:------------------------------|:---------|:-------------------------------------------------------------------|
| containerStorageExtensionId   | `string` | The ID of the Container Storage Extension.                         |
| containerStorageExtensionName | `string` | The name of the Container Storage Extension.                       |
| aioCertManagerExtensionId     | `string` | The ID of the Azure IoT Operations Cert-Manager Extension.         |
| aioCertManagerExtensionName   | `string` | The name of the Azure IoT Operations Cert-Manager Extension.       |
| secretStoreExtensionId        | `string` | The ID of the Secret Store Extension.                              |
| secretStoreExtensionName      | `string` | The name of the Secret Store Extension.                            |
| customLocationId              | `string` | The ID of the deployed Custom Location.                            |
| customLocationName            | `string` | The name of the deployed Custom Location.                          |
| aioInstanceId                 | `string` | The ID of the deployed Azure IoT Operations instance.              |
| aioInstanceName               | `string` | The name of the deployed Azure IoT Operations instance.            |
| dataFlowProfileId             | `string` | The ID of the deployed Azure IoT Operations Data Flow Profile.     |
| dataFlowProfileName           | `string` | The name of the deployed Azure IoT Operations Data Flow Profile.   |
| dataFlowEndpointId            | `string` | The ID of the deployed Azure IoT Operations Data Flow Endpoint.    |
| dataFlowEndpointName          | `string` | The name of the deployed Azure IoT Operations Data Flow Endpoint.  |
| akriConnectorTemplates        | `array`  | Map of deployed Akri connector templates by name with id and type. |
| akriConnectorTypesDeployed    | `array`  | List of Akri connector types that were deployed.                   |

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
| namespacedDevice       | `Microsoft.DeviceRegistry/namespaces/devices`    | 2025-10-01  |
| namespacedAsset        | `Microsoft.DeviceRegistry/namespaces/assets`     | 2025-10-01  |
| assetEndpointProfile   | `Microsoft.DeviceRegistry/assetEndpointProfiles` | 2025-10-01  |
| legacyAsset            | `Microsoft.DeviceRegistry/assets`                | 2025-10-01  |
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

### `_1.AssetAction`

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

### `_1.AssetDataPoint`

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

### `_1.AssetDataset`

Dataset configuration for assets.

| Property             | Type     | Description                           |
|:---------------------|:---------|:--------------------------------------|
| name                 | `string` | Name of the dataset.                  |
| datasetConfiguration | `string` | Dataset configuration as JSON string. |
| dataSource           | `string` | Data source address for the dataset.  |
| typeRef              | `string` | Type reference for the dataset.       |
| dataPoints           | `array`  | Data points in the dataset.           |
| destinations         | `array`  | Destinations for the dataset.         |

### `_1.AssetEndpointProfile`

Legacy asset endpoint profile configuration.

| Property                      | Type     | Description                                         |
|:------------------------------|:---------|:----------------------------------------------------|
| name                          | `string` | Name of the asset endpoint profile.                 |
| endpointProfileType           | `string` | Type of the endpoint profile: Microsoft.OpcUa, etc. |
| method                        | `string` | Authentication method: Anonymous, etc.              |
| targetAddress                 | `string` | Target address of the endpoint.                     |
| opcAdditionalConfigString     | `string` | Additional OPC configuration as JSON string.        |
| shouldEnableOpcAssetDiscovery | `bool`   | Whether to enable OPC asset discovery.              |

### `_1.AssetEvent`

Event configuration for assets.

| Property           | Type     | Description                         |
|:-------------------|:---------|:------------------------------------|
| name               | `string` | Name of the event.                  |
| dataSource         | `string` | Data source address for the event.  |
| eventConfiguration | `string` | Event configuration as JSON string. |
| typeRef            | `string` | Type reference for the event.       |
| destinations       | `array`  | Destinations for the event.         |

### `_1.AssetEventDestination`

Event destination configuration.

| Property      | Type     | Description                            |
|:--------------|:---------|:---------------------------------------|
| target        | `string` | Target for the destination: Mqtt, etc. |
| configuration | `object` | Configuration for the destination.     |

### `_1.AssetEventGroup`

Event group configuration for assets.

| Property                | Type     | Description                                   |
|:------------------------|:---------|:----------------------------------------------|
| name                    | `string` | Name of the event group.                      |
| dataSource              | `string` | Data source address for the event group.      |
| eventGroupConfiguration | `string` | Event group configuration as JSON string.     |
| typeRef                 | `string` | Type reference for the event group.           |
| defaultDestinations     | `array`  | Default destinations for events in the group. |
| events                  | `array`  | Events in the event group.                    |

### `_1.AssetManagementGroup`

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

### `_1.AssetStream`

Stream configuration for assets.

| Property            | Type     | Description                          |
|:--------------------|:---------|:-------------------------------------|
| name                | `string` | Name of the stream.                  |
| streamConfiguration | `string` | Stream configuration as JSON string. |
| typeRef             | `string` | Type reference for the stream.       |
| destinations        | `array`  | Destinations for the stream set.     |

### `_1.DatasetDestination`

Dataset destination configuration.

| Property      | Type     | Description                            |
|:--------------|:---------|:---------------------------------------|
| target        | `string` | Target for the destination: Mqtt, etc. |
| configuration | `object` | Configuration for the destination.     |

### `_1.DeviceEndpoint`

Endpoint configuration for devices.

| Property                | Type                                               | Description                                    |
|:------------------------|:---------------------------------------------------|:-----------------------------------------------|
| endpointType            | `string`                                           | Type of the endpoint: Microsoft.OpcUa, etc.    |
| address                 | `string`                                           | Address of the endpoint.                       |
| version                 | `string`                                           | Version of the endpoint protocol.              |
| additionalConfiguration | `string`                                           | Additional configuration as JSON string.       |
| authentication          | `[_1.EndpointAuthentication](#user-defined-types)` | Authentication configuration for the endpoint. |
| trustSettings           | `[_1.TrustSettings](#user-defined-types)`          | Trust settings for the endpoint.               |

### `_1.DeviceEndpoints`

Device endpoints configuration.

| Property | Type     | Description                      |
|:---------|:---------|:---------------------------------|
| outbound | `object` | Outbound endpoint configuration. |
| inbound  | `object` | Inbound endpoint configurations. |

### `_1.DeviceReference`

Device reference for namespaced assets.

| Property     | Type     | Description                         |
|:-------------|:---------|:------------------------------------|
| deviceName   | `string` | Name of the device.                 |
| endpointName | `string` | Name of the endpoint on the device. |

### `_1.EndpointAuthentication`

Endpoint authentication configuration for assets.

| Property                    | Type     | Description                                                 |
|:----------------------------|:---------|:------------------------------------------------------------|
| method                      | `string` | Authentication method: Anonymous, UsernamePassword, or X509 |
| usernamePasswordCredentials | `object` | Username and password credentials for authentication.       |
| x509Credentials             | `object` | X509 certificate credentials for authentication.            |

### `_1.LegacyAsset`

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

### `_1.LegacyAssetDataPoint`

Legacy asset data point configuration.

| Property               | Type     | Description                              |
|:-----------------------|:---------|:-----------------------------------------|
| name                   | `string` | Name of the data point.                  |
| dataSource             | `string` | Data source address.                     |
| dataPointConfiguration | `string` | Data point configuration as JSON string. |
| observabilityMode      | `string` | Observability mode: None, etc.           |

### `_1.LegacyAssetDataset`

Legacy asset dataset configuration.

| Property   | Type     | Description                 |
|:-----------|:---------|:----------------------------|
| name       | `string` | Name of the dataset.        |
| dataPoints | `array`  | Data points in the dataset. |

### `_1.NamespacedAsset`

Namespaced asset configuration.

| Property                     | Type                                        | Description                                         |
|:-----------------------------|:--------------------------------------------|:----------------------------------------------------|
| name                         | `string`                                    | Name of the asset.                                  |
| displayName                  | `string`                                    | Display name of the asset.                          |
| deviceRef                    | `[_1.DeviceReference](#user-defined-types)` | Reference to the device and endpoint.               |
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

### `_1.NamespacedDevice`

Namespaced device configuration.

| Property  | Type                                        | Description                             |
|:----------|:--------------------------------------------|:----------------------------------------|
| name      | `string`                                    | Name of the device.                     |
| isEnabled | `bool`                                      | Whether the device is enabled.          |
| endpoints | `[_1.DeviceEndpoints](#user-defined-types)` | Endpoint configurations for the device. |

### `_1.TrustSettings`

Trust settings for endpoint connections.

| Property  | Type     | Description               |
|:----------|:---------|:--------------------------|
| trustList | `string` | Trust list configuration. |

### `_2.Common`

Common settings for the components.

| Property       | Type     | Description                                                      |
|:---------------|:---------|:-----------------------------------------------------------------|
| resourcePrefix | `string` | Prefix for all resources in this module                          |
| location       | `string` | Location for all resources in this module                        |
| environment    | `string` | Environment for all resources in this module: dev, test, or prod |
| instance       | `string` | Instance identifier for naming resources: 001, 002, etc...       |

## Outputs

| Name                      | Type     | Description                                                                                                                                 |
|:--------------------------|:---------|:--------------------------------------------------------------------------------------------------------------------------------------------|
| arcConnectedClusterName   | `string` | The name of the Arc-enabled Kubernetes cluster that was connected to Azure. This can be used to reference the cluster in other deployments. |
| vmUsername                | `string` | The administrative username that can be used to SSH into the deployed virtual machines.                                                     |
| vmNames                   | `array`  | An array containing the names of all virtual machines that were deployed as part of this blueprint.                                         |
| aioCertManagerExtensionId | `string` | The ID of the Azure IoT Operations Cert-Manager Extension.                                                                                  |

<!-- END_BICEP_DOCS -->