<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# CNCF Cluster Component
  
Sets up and deploys a script to a VM host that will setup the K3S cluster and optionally cluster nodes, Arc connect the cluster, Add cluster admins to the cluster, enable workload identity, install extensions for cluster connect and custom locations.  

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|[_1.Common](#user-defined-types)|n/a|yes|
|clusterAdminOid|The Object ID that will be given cluster-admin permissions.|string|n/a|no|
|customLocationsOid|The object id of the Custom Locations Entra ID application for your tenant.<br>If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre><br>|string|n/a|no|
|arcOnboardingSpClientId|Service Principal Client ID with Kubernetes Cluster - Azure Arc Onboarding permissions.|string|n/a|no|
|arcOnboardingSpClientSecret|The Service Principal Client Secret for Arc onboarding.|securestring|n/a|no|
|shouldAddCurrentUserClusterAdmin|Whether to add the current user as a cluster admin.|bool|true|no|
|shouldEnableArcAutoUpgrade|Whether to enable auto-upgrade for Azure Arc agents.|bool|[not(equals(parameters('common').environment, 'prod'))]|no|
|clusterNodeVirtualMachineNames|The node virtual machines names.|array|[]|no|
|clusterServerVirtualMachineName|The server virtual machines name.|string|n/a|yes|
|clusterServerHostMachineUsername|Username used for the host machines that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)|string|[parameters('common').resourcePrefix]|no|
|clusterServerIp|The IP address for the server for the cluster. (Needed for mult-node cluster)|string|n/a|no|
|serverToken|The token that will be given to the server for the cluster or used by agent nodes.|string|n/a|no|
|shouldDeployScriptToVm|Whether to deploy the scripts to the VM.|bool|true|no|
|shouldGetCustomLocationsOid|Whether to get Custom Locations Object ID using Azure APIs.|bool|true|no|
|shouldGenerateServerToken|Should generate token used by the server.|bool|false|no|
|shouldSkipAzCliLogin|Should skip login process with Azure CLI on the server.|bool|false|no|
|shouldSkipInstallingAzCli|Should skip downloading and installing Azure CLI on the server.|bool|false|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|customLocationsServicePrincipal|Microsoft.Graph/servicePrincipals@v1.0||
|ubuntuK3s|Microsoft.Resources/deployments|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|ubuntuK3s|Configures K3s Kubernetes clusters on Ubuntu virtual machines and connects them to Azure Arc.|

## Module Details

### ubuntuK3s
  
Configures K3s Kubernetes clusters on Ubuntu virtual machines and connects them to Azure Arc.  

#### Parameters for ubuntuK3s

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|[_1.Common](#user-defined-types)|n/a|yes|
|clusterServerVirtualMachineName|The server virtual machines name.|string|n/a|yes|
|clusterNodeVirtualMachineNames|The node virtual machines names.|array|n/a|yes|
|arcResourceName|The name of the Azure Arc resource.|string|n/a|yes|
|arcTenantId|The tenant ID for Azure Arc resource.|string|n/a|yes|
|customLocationsOid|The object id of the Custom Locations Entra ID application for your tenant.<br>If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre><br>|string|n/a|yes|
|shouldEnableArcAutoUpgrade|Whether to enable auto-upgrades for Arc agents.|bool|n/a|yes|
|arcOnboardingSpClientId|The Service Principal Client ID for Arc onboarding.|string|n/a|yes|
|arcOnboardingSpClientSecret|The Service Principal Client Secret for Arc onboarding.|securestring|n/a|yes|
|clusterAdminOid|The Object ID that will be given cluster-admin permissions.|string|n/a|yes|
|clusterServerHostMachineUsername|Username for the host machine with kube-config settings.|string|n/a|yes|
|clusterServerIp|The IP address for the server for the cluster. (Needed for mult-node cluster)|string|n/a|yes|
|clusterServerToken|The token for the K3s cluster.|securestring|n/a|yes|
|shouldDeployScriptToVm|Should deploy the scripts to the VM.|bool|n/a|yes|
|shouldSkipAzCliLogin|Should skip login process with Azure CLI on the server.|bool|n/a|yes|
|shouldSkipInstallingAzCli|Should skip downloading and installing Azure CLI on the server.|bool|n/a|yes|

#### Resources for ubuntuK3s

|Name|Type|API Version|
| :--- | :--- | :--- |
|clusterServerVirtualMachine::linuxServerScriptSetup|Microsoft.Compute/virtualMachines/extensions|2024-11-01|
|clusterServerVirtualMachine|Microsoft.Compute/virtualMachines|2024-11-01|
|clusterNodeVirtualMachines|Microsoft.Compute/virtualMachines|2024-11-01|
|linuxNodeScriptSetup|Microsoft.Compute/virtualMachines/extensions|2024-11-01|

## User Defined Types

### `_1.Common`
  
Common settings for the components.  

|Property|Type|Description|
| :--- | :--- | :--- |
|resourcePrefix|string|Prefix for all resources in this module|
|location|string|Location for all resources in this module|
|environment|string|Environment for all resources in this module: dev, test, or prod|
|instance|string|Instance identifier for naming resources: 001, 002, etc...|

## Outputs

|Name|Type|Description|
| :--- | :--- | :--- |
|connectedClusterName|string|The connected cluster name|
|connectedClusterResourceGroupName|string|The connected cluster resource group name|
|azureArcProxyCommand|string|Azure Arc proxy command for accessing the cluster|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->
