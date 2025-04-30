import * as core from '../../bicep/types.core.bicep'

@description('The common component configuration.')
param common core.Common

@description('The resource name for the identity used for Arc onboarding.')
param arcOnboardingIdentityName string = 'id-${common.resourcePrefix}-arc-${common.environment}-${common.instance}'

@description('The server virtual machines name.')
param clusterServerVirtualMachineName string = 'vm-${common.resourcePrefix}-aio-${common.environment}-${common.instance}-0'

@description('The node virtual machines names.')
param clusterNodeVirtualMachineNames string[] = []

@description('''
The object id of the Custom Locations Entra ID application for your tenant.
Can be retrieved using: az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv')
''')
param customLocationsOid string

@description('The IP address for the server for the cluster. (Needed for mult-node cluster)')
param clusterServerIp string?

@description('The token that will be given to the server for the cluster or used by agent nodes.')
@secure()
param serverToken string?

@description('The name of the Key Vault to save the scripts to.')
param keyVaultName string = 'kv-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('The resource group name where the Key Vault is located. Defaults to the deployment resource group.')
param keyVaultResourceGroupName string = resourceGroup().name

// Deploy the CNCF cluster module
module cncfCluster '../../bicep/main.bicep' = {
  name: '${common.resourcePrefix}-cncf-cluster'
  params: {
    common: common
    customLocationsOid: customLocationsOid
    clusterServerVirtualMachineName: clusterServerVirtualMachineName
    clusterNodeVirtualMachineNames: clusterNodeVirtualMachineNames
    clusterServerIp: clusterServerIp
    serverToken: serverToken
    arcOnboardingIdentityName: arcOnboardingIdentityName
    deployKeyVaultName: keyVaultName
    deployKeyVaultResourceGroupName: keyVaultResourceGroupName
  }
}
