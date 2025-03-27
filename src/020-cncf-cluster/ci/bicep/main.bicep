import * as core from '../../bicep/types.core.bicep'

@description('The common component configuration.')
param common core.Common

@description('VM information for the cluster server.')
param clusterServerVirtualMachineName string = 'vm-${common.resourcePrefix}-aio-${common.environment}-${common.?instance ?? '001'}-0'

@description('VM information for the cluster nodes.')
param clusterNodeVirtualMachineNames string[] = []

@description('Whether to get Custom Locations Object ID using Azure APIs.')
param shouldGetCustomLocationsOid bool = true

@description('The Object ID of the Custom Locations Entra ID application for your tenant.')
param customLocationsOid string?

@description('The IP address for the server for the cluster. (Needed for mult-node cluster)')
param clusterServerIp string?

@description('The token that will be given to the server for the cluster or used by agent nodes.')
param serverToken string?

@description('Should generate token used by the server.')
param shouldGenerateServerToken bool = false

// Deploy the CNCF cluster module
module cncfCluster '../../bicep/main.bicep' = {
  name: '${common.resourcePrefix}-cncf-cluster'
  params: {
    common: common
    customLocationsOid: customLocationsOid
    shouldGetCustomLocationsOid: shouldGetCustomLocationsOid
    clusterServerVirtualMachineName: clusterServerVirtualMachineName
    clusterNodeVirtualMachineNames: clusterNodeVirtualMachineNames
    clusterServerIp: clusterServerIp
    serverToken: serverToken
    shouldGenerateServerToken: shouldGenerateServerToken
  }
}
