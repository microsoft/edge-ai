import * as core from '../types.core.bicep'

@description('The common component configuration.')
param common core.Common

@description('The server virtual machine information.')
@minLength(3)
param clusterServerVirtualMachineName string

@description('The node virtual machines information.')
param clusterNodeVirtualMachineNames string[]

@description('The name of the Azure Arc resource.')
param arcResourceName string

@description('The tenant ID for Azure Arc resource.')
param arcTenantId string

@description('The Object ID of the Custom Locations Entra ID application.')
param customLocationsOid string

@description('Whether to enable auto-upgrades for Arc agents.')
param shouldEnableArcAutoUpgrade bool

@description('The Service Principal Client ID for Arc onboarding.')
param arcOnboardingSpClientId string?

@description('The Service Principal Client Secret for Arc onboarding.')
@secure()
param arcOnboardingSpClientSecret string?

@description('The Object ID that will be given cluster-admin permissions.')
param clusterAdminOid string?

@description('Username for the host machine with kube-config settings.')
param clusterServerHostMachineUsername string

@description('The IP address for the server for the cluster. (Needed for mult-node cluster)')
param clusterServerIp string?

@description('The token for the K3s cluster.')
@secure()
param clusterServerToken string?

@description('Should deploy the scripts to the VM.')
param shouldDeployScriptToVm bool

@description('Should skip Azure CLI login.')
param shouldSkipAzCliLogin bool

@description('Should skip installing Azure CLI.')
param shouldSkipInstallingAzCli bool

/*
  Local variables
*/

var clusterServerUrl = !empty(clusterServerIp) ? 'https://${clusterServerIp}:6443' : null

var serverEnvVars = {
  K3S_NODE_TYPE: 'server'
  CLUSTER_ADMIN_OID: clusterAdminOid ?? '\${CLUSTER_ADMIN_OID}'
  SKIP_ARC_CONNECT: '\${SKIP_ARC_CONNECT}'
}

var nodeEnvVars = {
  K3S_NODE_TYPE: 'agent'
  CLUSTER_ADMIN_OID: '\${CLUSTER_ADMIN_OID}'
  SKIP_ARC_CONNECT: 'true'
}

// Define default environment variables
var defaultEnvVars = {
  ENVIRONMENT: common.environment
  ARC_RESOURCE_GROUP_NAME: resourceGroup().name
  ARC_RESOURCE_NAME: arcResourceName
  K3S_URL: clusterServerUrl ?? '\${K3S_URL}'
  K3S_TOKEN: clusterServerToken ?? '\${K3S_TOKEN}'
  K3S_VERSION: '\${K3S_VERSION}'
  ARC_AUTO_UPGRADE: string(shouldEnableArcAutoUpgrade)
  ARC_SP_CLIENT_ID: arcOnboardingSpClientId ?? '\${ARC_SP_CLIENT_ID}'
  ARC_SP_SECRET: arcOnboardingSpClientSecret ?? '\${ARC_SP_SECRET}'
  ARC_TENANT_ID: arcTenantId
  AZ_CLI_VER: '\${AZ_CLI_VER}'
  AZ_CONNECTEDK8S_VER: '\${AZ_CONNECTEDK8S_VER}'
  CUSTOM_LOCATIONS_OID: customLocationsOid ?? '\${CUSTOM_LOCATIONS_OID}'
  DEVICE_USERNAME: clusterServerHostMachineUsername
  SKIP_INSTALL_AZ_CLI: shouldSkipInstallingAzCli ? 'true' : '\${SKIP_INSTALL_AZ_CLI}'
  SKIP_AZ_LOGIN: shouldSkipAzCliLogin ? 'true' : '\${SKIP_AZ_LOGIN}'
  SKIP_INSTALL_K3S: '\${SKIP_INSTALL_K3S}'
  SKIP_INSTALL_KUBECTL: '\${SKIP_INSTALL_KUBECTL}'
}

var defaultEnvVarsArray = [for item in items(defaultEnvVars): {
  name: item.key
  value: item.value
}]

var nodeEnvVarsArray = [for item in items(nodeEnvVars): {
  name: item.key
  value: item.value
}]

var serverEnvVarsArray = [for item in items(serverEnvVars): {
  name: item.key
  value: item.value
}]

// Join the initial arrays
var nodeEnvironmentVariablesArray = union(defaultEnvVarsArray, nodeEnvVarsArray)
var serverEnvironmentVariablesArray = union(defaultEnvVarsArray, serverEnvVarsArray)

// Convert to variable with export strings and joined
var serverEnvironmentVariablesString = [for envVar in serverEnvironmentVariablesArray: '${envVar.name}="${envVar.value}";']
var joinedServerEnvironmentVariablesString = join(serverEnvironmentVariablesString, '\n')
var nodeEnvironmentVariablesString = [for envVar in nodeEnvironmentVariablesArray: '${envVar.name}="${envVar.value}";']
var joinedNodeEnvironmentVariablesString = join(nodeEnvironmentVariablesString, '\n')

// Every loadTextContent results in the contents of the file being loaded into a variable that's then built into the
// ARM that's ultimately deployed. Reduce the number of loadTextContent calls to one to prevent any future issues.
var scriptFileContents = loadTextContent('../../scripts/k3s-device-setup.sh')
var effectiveClusterServerScript = base64('#!/usr/bin/env bash\n\n${joinedServerEnvironmentVariablesString}\n\n${scriptFileContents}')
var effectiveClusterNodeScript = base64('#!/usr/bin/env bash\n\n${joinedNodeEnvironmentVariablesString}\n\n${scriptFileContents}')

/*
  Resources
*/

resource clusterServerVirtualMachine 'Microsoft.Compute/virtualMachines@2024-11-01' existing = if (shouldDeployScriptToVm) {
  name: clusterServerVirtualMachineName

  resource linuxServerScriptSetup 'extensions' = {
    name: 'linux-cluster-server-setup'
    location: common.?location ?? resourceGroup().location
    properties: {
      publisher: 'Microsoft.Azure.Extensions'
      type: 'CustomScript'
      typeHandlerVersion: '2.1'
      autoUpgradeMinorVersion: false
      suppressFailures: false
      enableAutomaticUpgrade: false
      settings: {}
      protectedSettings: {
        script: effectiveClusterServerScript
      }
    }
  }
}

// deploy VM extension for node setup
resource clusterNodeVirtualMachines 'Microsoft.Compute/virtualMachines@2024-11-01' existing = [for (clusterNodeVirtualMachineName, index) in clusterNodeVirtualMachineNames: {
  name: clusterNodeVirtualMachineName
}]

resource linuxNodeScriptSetup 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = [for (clusterNodeVirtualMachineName, index) in clusterNodeVirtualMachineNames: {
  name: 'linux-cluster-node-setup'
  location: common.?location ?? resourceGroup().location
  parent: clusterNodeVirtualMachines[index]
  dependsOn: [clusterServerVirtualMachine::linuxServerScriptSetup]

  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: false
    settings: {}
    protectedSettings: {
      script: effectiveClusterNodeScript
    }
  }
}]
