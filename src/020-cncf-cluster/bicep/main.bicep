/**
 * # CNCF Cluster
 *
 * Sets up and deploys a script to a VM host that will setup the K3S cluster and optionally cluster nodes,
 * Arc connect the cluster, Add cluster admins to the cluster, enable workload identity,
 * install extensions for cluster connect and custom locations.
 */

extension microsoftGraphV1

import * as core from './types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Azure Arc Parameters
*/

@description('The Object ID that will be given cluster-admin permissions.')
param clusterAdminOid string?

@description('''
The object id of the Custom Locations Entra ID application for your tenant.
If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.
Can be retrieved using:

  ```sh
  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
  ```
''')
param customLocationsOid string?

@description('Service Principal Client ID with Kubernetes Cluster - Azure Arc Onboarding permissions.')
param arcOnboardingSpClientId string?

@description('The Service Principal Client Secret for Arc onboarding.')
@secure()
param arcOnboardingSpClientSecret string?

@description('Whether to add the current user as a cluster admin.')
param shouldAddCurrentUserClusterAdmin bool = true

@description('Whether to enable auto-upgrade for Azure Arc agents.')
param shouldEnableArcAutoUpgrade bool = common.environment != 'prod'

/*
  Cluster Parameters
*/

@description('The node virtual machines names.')
param clusterNodeVirtualMachineNames string[] = []

@description('The server virtual machines name.')
@minLength(3)
param clusterServerVirtualMachineName string

@description('Username used for the host machines that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)')
param clusterServerHostMachineUsername string = common.resourcePrefix

@description('The IP address for the server for the cluster. (Needed for mult-node cluster)')
param clusterServerIp string?

@description('The token that will be given to the server for the cluster or used by agent nodes.')
param serverToken string?

@description('Whether to deploy the scripts to the VM.')
param shouldDeployScriptToVm bool = true

@description('Whether to get Custom Locations Object ID using Azure APIs.')
param shouldGetCustomLocationsOid bool = true

@description('Should generate token used by the server.')
param shouldGenerateServerToken bool = false

@description('Should skip login process with Azure CLI on the server.')
param shouldSkipAzCliLogin bool = false

@description('Should skip downloading and installing Azure CLI on the server.')
param shouldSkipInstallingAzCli bool = false

/*
  Variables
*/

// Configuration variables
var arcResourceName = 'arck-${common.resourcePrefix}-${common.environment}-${common.?instance ?? '001'}'
var resourceGroupName = resourceGroup().name

// Get the token value either from the generated token or the provided parameter
// This is not optimal, but customer can provide their own token via parameter
var clusterServerToken = serverToken ?? (shouldGenerateServerToken ? substring('${uniqueString(clusterServerVirtualMachineName)}-${uniqueString(resourceGroup().id)}', 0, 24) : null)

// Determine current user OID for cluster admin if needed
var currentUserOid = shouldAddCurrentUserClusterAdmin ? deployer().objectId : null

var effectiveCustomLocationsOid = customLocationsOid ?? customLocationsServicePrincipal.?id
/*
  Resources
*/

resource customLocationsServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' existing = if (shouldGetCustomLocationsOid && empty(customLocationsOid ?? '')) {
  // The service principal for Custom Locations in tenant
  appId: 'bc313c14-388c-4e7d-a58e-70017303ee3b' // gitleaks:allow
}

/*
  Modules
*/

// Deploy the ubuntu-k3s module to setup the cluster (server and optionally nodes)
module ubuntuK3s './modules/ubuntu-k3s.bicep' = {
  name: 'ubuntu-k3s-deployment'
  params: {
    common: common
    arcResourceName: arcResourceName
    arcTenantId: tenant().tenantId
    clusterAdminOid: clusterAdminOid ?? currentUserOid
    customLocationsOid: effectiveCustomLocationsOid
    shouldEnableArcAutoUpgrade: shouldEnableArcAutoUpgrade
    arcOnboardingSpClientId: arcOnboardingSpClientId
    arcOnboardingSpClientSecret: arcOnboardingSpClientSecret
    clusterServerVirtualMachineName: clusterServerVirtualMachineName
    clusterNodeVirtualMachineNames: clusterNodeVirtualMachineNames
    clusterServerIp: clusterServerIp ?? ''
    clusterServerToken: clusterServerToken
    shouldDeployScriptToVm: shouldDeployScriptToVm
    shouldSkipAzCliLogin: shouldSkipAzCliLogin
    shouldSkipInstallingAzCli: shouldSkipInstallingAzCli
    clusterServerHostMachineUsername: clusterServerHostMachineUsername
  }
}

/*
  Outputs
*/

@description('The connected cluster name')
output connectedClusterName string = arcResourceName

@description('The connected cluster resource group name')
output connectedClusterResourceGroupName string = resourceGroupName

@description('Azure Arc proxy command for accessing the cluster')
output azureArcProxyCommand string = 'az connectedk8s proxy -n ${arcResourceName} -g ${resourceGroupName}'
