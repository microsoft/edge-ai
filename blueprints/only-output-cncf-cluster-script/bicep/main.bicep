metadata name = 'Only Output CNCF Cluster Script Blueprint'
metadata description = 'Generates scripts for Azure IoT Operations CNCF cluster creation without deploying resources.'

import * as core from './types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Key Vault Parameters
*/

@description('The name of the Key Vault to save the scripts to.')
param keyVaultName string

@description('The resource group name where the Key Vault is located. Defaults to the current resource group.')
param keyVaultResourceGroupName string = resourceGroup().name

/*
  Cluster Configuration Parameters
*/

@description('The IP address for the server for the cluster. (Needed for multi-node cluster)')
param clusterServerIp string?

@description('Should generate token used by the server.')
param shouldGenerateServerToken bool = false

@description('The token that will be given to the server for the cluster or used by agent nodes.')
param serverToken string?

@description('The Object ID that will be given cluster-admin permissions.')
param clusterAdminOid string?

/*
  Azure Arc Parameters
*/

@description('Whether to get Custom Locations Object ID using Azure APIs.')
param shouldGetCustomLocationsOid bool = true

@description('''
The object id of the Custom Locations Entra ID application for your tenant.
If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.
Can be retrieved using:

  ```sh
  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
  ```
''')
param customLocationsOid string?

/*
  Role Assignment Parameters
*/

@description('Whether to assign roles for Arc Onboarding.')
param shouldAssignRoles bool = true

@description('Service Principal Object Id used when assigning roles for Arc onboarding.')
param arcOnboardingSpPrincipalId string?

@description('Service Principal Client ID with Kubernetes Cluster - Azure Arc Onboarding permissions.')
param arcOnboardingSpClientId string?

@description('The Service Principal Client Secret for Arc onboarding.')
@secure()
param arcOnboardingSpClientSecret string?

@description('The resource name for the identity used for Arc onboarding.')
param arcOnboardingIdentityName string?

/*
  Modules
*/

module edgeCncfCluster '../../../src/100-edge/100-cncf-cluster/bicep/main.bicep' = {
  name: '${deployment().name}-edgeCncfCluster'
  params: {
    common: common
    keyVaultName: keyVaultName
    keyVaultResourceGroupName: keyVaultResourceGroupName
    clusterServerIp: clusterServerIp
    shouldGenerateServerToken: shouldGenerateServerToken
    serverToken: serverToken
    clusterAdminOid: clusterAdminOid
    shouldGetCustomLocationsOid: shouldGetCustomLocationsOid
    customLocationsOid: customLocationsOid
    shouldAssignRoles: shouldAssignRoles
    arcOnboardingSpPrincipalId: arcOnboardingSpPrincipalId
    arcOnboardingSpClientId: arcOnboardingSpClientId
    arcOnboardingSpClientSecret: arcOnboardingSpClientSecret
    arcOnboardingIdentityName: arcOnboardingIdentityName
    shouldDeployScriptToVm: false
  }
}

/*
  Outputs
*/

@description('The connected cluster name')
output connectedClusterName string = edgeCncfCluster.outputs.connectedClusterName

@description('The connected cluster resource group name')
output connectedClusterResourceGroupName string = edgeCncfCluster.outputs.connectedClusterResourceGroupName

@description('Azure Arc proxy command for accessing the cluster')
output azureArcProxyCommand string = edgeCncfCluster.outputs.azureArcProxyCommand

@description('The name of the Key Vault secret containing the server script')
output clusterServerScriptSecretName string = edgeCncfCluster.outputs.clusterServerScriptSecretName

@description('The name of the Key Vault secret containing the node script')
output clusterNodeScriptSecretName string = edgeCncfCluster.outputs.clusterNodeScriptSecretName

@description('The AZ CLI command to get the cluster server script from Key Vault')
output clusterServerScriptSecretShowCommand string = edgeCncfCluster.outputs.clusterServerScriptSecretShowCommand

@description('The AZ CLI command to get the cluster node script from Key Vault')
output clusterNodeScriptSecretShowCommand string = edgeCncfCluster.outputs.clusterNodeScriptSecretShowCommand
