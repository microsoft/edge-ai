<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Only Output CNCF Cluster Script Blueprint

Generates scripts for Azure IoT Operations CNCF cluster creation without deploying resources.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|telemetry_opt_out|Whether to opt-out of telemetry. Set to true to disable telemetry.|`bool`|`false`|no|
|arcConnectedClusterName|The resource name for the Arc connected cluster.|`string`|[format('arck-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|arcOnboardingIdentityName|The resource name for the identity used for Arc onboarding.|`string`|[format('id-{0}-arc-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|arcOnboardingSpClientId|Service Principal Client ID with Kubernetes Cluster - Azure Arc Onboarding permissions.|`string`|n/a|no|
|arcOnboardingSpClientSecret|The Service Principal Client Secret for Arc onboarding.|`securestring`|n/a|no|
|arcOnboardingSpPrincipalId|Service Principal Object Id used when assigning roles for Arc onboarding.|`string`|n/a|no|
|customLocationsOid|The object id of the Custom Locations Entra ID application for your tenant.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre><br>|`string`|n/a|yes|
|shouldEnableArcAutoUpgrade|Whether to enable auto-upgrade for Azure Arc agents.|`bool`|[not(equals(parameters('common').environment, 'prod'))]|no|
|shouldAssignRoles|Whether to assign roles for Arc Onboarding.|`bool`|`true`|no|
|clusterAdminOid|The Object ID that will be given cluster-admin permissions.|`string`|n/a|no|
|clusterNodeVirtualMachineNames|The names of the VMs for the cluster nodes. (Only needed if wanting this blueprint to deploy the scripts)|`array`|n/a|no|
|clusterServerIp|The IP address for the server for the cluster. (Needed for multi-node cluster)|`string`|n/a|no|
|clusterServerHostMachineUsername|Username used for the host machines that will be given kube-config settings on setup.|`string`|[parameters('common').resourcePrefix]|no|
|clusterServerVirtualMachineName|The name of the VM for the cluster server. (Only needed if wanting this blueprint to deploy the scripts)|`string`|n/a|no|
|serverToken|The token that will be given to the server for the cluster or used by agent nodes.|`securestring`|n/a|no|
|shouldAddCurrentUserClusterAdmin|Whether to add the current user as a cluster admin.|`bool`|`true`|no|
|deployUserTokenSecretName|The name for the deploy user token secret in Key Vault.|`string`|deploy-user-token|no|
|k3sTokenSecretName|The name for the K3s token secret in Key Vault.|`string`|k3s-server-token|no|
|keyVaultName|The name of the Key Vault to save the scripts to.|`string`|[format('kv-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|keyVaultResourceGroupName|The resource group name where the Key Vault is located. Defaults to the current resource group.|`string`|[resourceGroup().name]|no|
|nodeScriptSecretName|The name for the node script secret in Key Vault.|`string`|cluster-node-ubuntu-k3s|no|
|serverScriptSecretName|The name for the server script secret in Key Vault.|`string`|cluster-server-ubuntu-k3s|no|
|shouldDeployScriptToVm|Whether to deploy the scripts to the VMs. (Only needed if wanting this blueprint to deploy the scripts)|`bool`|`false`|no|
|shouldSkipAzCliLogin|Should skip login process with Azure CLI on the server.|`bool`|`false`|no|
|shouldSkipInstallingAzCli|Should skip downloading and installing Azure CLI on the server.|`bool`|`false`|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
|edgeCncfCluster|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|attribution||
|edgeCncfCluster|This module provisions and deploys automation scripts to a VM host that create and configure a K3s Kubernetes cluster with Arc connectivity.<br>The scripts handle primary and secondary node(s) setup, cluster administration, workload identity enablement, and installation of required Azure Arc extensions.|

## Module Details

### attribution

### edgeCncfCluster

This module provisions and deploys automation scripts to a VM host that create and configure a K3s Kubernetes cluster with Arc connectivity.
The scripts handle primary and secondary node(s) setup, cluster administration, workload identity enablement, and installation of required Azure Arc extensions.

#### Parameters for edgeCncfCluster

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|arcConnectedClusterName|The resource name for the Arc connected cluster.|`string`|[format('arck-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|arcOnboardingSpClientId|Service Principal Client ID with Kubernetes Cluster - Azure Arc Onboarding permissions.|`string`|n/a|no|
|arcOnboardingSpClientSecret|The Service Principal Client Secret for Arc onboarding.|`securestring`|n/a|no|
|arcOnboardingSpPrincipalId|Service Principal Object Id used when assigning roles for Arc onboarding.|`string`|n/a|no|
|arcOnboardingIdentityName|The resource name for the identity used for Arc onboarding.|`string`|n/a|no|
|customLocationsOid|The object id of the Custom Locations Entra ID application for your tenant.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre><br>|`string`|n/a|yes|
|shouldAddCurrentUserClusterAdmin|Whether to add the current user as a cluster admin.|`bool`|True|no|
|shouldEnableArcAutoUpgrade|Whether to enable auto-upgrade for Azure Arc agents.|`bool`|[not(equals(parameters('common').environment, 'prod'))]|no|
|clusterAdminOid|The Object ID that will be given cluster-admin permissions.|`string`|n/a|no|
|clusterNodeVirtualMachineNames|The node virtual machines names.|`array`|n/a|no|
|clusterServerVirtualMachineName|The server virtual machines name.|`string`|n/a|no|
|clusterServerHostMachineUsername|Username used for the host machines that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)|`string`|[parameters('common').resourcePrefix]|no|
|clusterServerIp|The IP address for the server for the cluster. (Needed for mult-node cluster)|`string`|n/a|no|
|serverToken|The token that will be given to the server for the cluster or used by agent nodes.|`securestring`|n/a|no|
|shouldAssignRoles|Whether to assign roles for Arc Onboarding.|`bool`|True|no|
|shouldDeployScriptToVm|Whether to deploy the scripts to the VM.|`bool`|True|no|
|shouldSkipInstallingAzCli|Should skip downloading and installing Azure CLI on the server.|`bool`|False|no|
|shouldSkipAzCliLogin|Should skip login process with Azure CLI on the server.|`bool`|False|no|
|deployUserTokenSecretName|The name for the deploy user token secret in Key Vault.|`string`|deploy-user-token|no|
|deployKeyVaultName|The name of the Key Vault that will have scripts and secrets for deployment.|`string`|n/a|yes|
|deployKeyVaultResourceGroupName|The resource group name where the Key Vault is located. Defaults to the current resource group.|`string`|[resourceGroup().name]|no|
|k3sTokenSecretName|The name for the K3s token secret in Key Vault.|`string`|k3s-server-token|no|
|nodeScriptSecretName|The name for the node script secret in Key Vault.|`string`|cluster-node-ubuntu-k3s|no|
|serverScriptSecretName|The name for the server script secret in Key Vault.|`string`|cluster-server-ubuntu-k3s|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|

#### Resources for edgeCncfCluster

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
|arcOnboardingIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2024-11-30|
|ubuntuK3s|`Microsoft.Resources/deployments`|2022-09-01|
|roleAssignment|`Microsoft.Resources/deployments`|2022-09-01|
|keyVaultRoleAssignments|`Microsoft.Resources/deployments`|2022-09-01|
|deployScriptsToVm|`Microsoft.Resources/deployments`|2022-09-01|

#### Outputs for edgeCncfCluster

|Name|Type|Description|
| :--- | :--- | :--- |
|connectedClusterName|`string`|The connected cluster name|
|connectedClusterResourceGroupName|`string`|The connected cluster resource group name|
|azureArcProxyCommand|`string`|Azure Arc proxy command for accessing the cluster|
|clusterServerScriptSecretName|`string`|The name of the Key Vault secret containing the server script|
|clusterNodeScriptSecretName|`string`|The name of the Key Vault secret containing the node script|
|clusterServerScriptSecretShowCommand|`string`|The AZ CLI command to get the cluster server script from Key Vault|
|clusterNodeScriptSecretShowCommand|`string`|The AZ CLI command to get the cluster node script from Key Vault|

## User Defined Types

### `_1.Common`

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
|connectedClusterName|`string`|The connected cluster name|
|connectedClusterResourceGroupName|`string`|The connected cluster resource group name|
|azureArcProxyCommand|`string`|Azure Arc proxy command for accessing the cluster|
|clusterServerScriptSecretName|`string`|The name of the Key Vault secret containing the server script|
|clusterNodeScriptSecretName|`string`|The name of the Key Vault secret containing the node script|
|clusterServerScriptSecretShowCommand|`string`|The AZ CLI command to get the cluster server script from Key Vault|
|clusterNodeScriptSecretShowCommand|`string`|The AZ CLI command to get the cluster node script from Key Vault|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->
