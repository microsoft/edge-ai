metadata name = 'Ubuntu K3s Module'
metadata description = 'Configures K3s Kubernetes clusters on Ubuntu virtual machines and connects them to Azure Arc.'

import * as core from '../types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Azure Arc Parameters
*/

@description('The name of the Azure Arc resource.')
param arcResourceName string

@description('The tenant ID for Azure Arc resource.')
param arcTenantId string

@description('''
The object id of the Custom Locations Entra ID application for your tenant.
If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.
Can be retrieved using:

  ```sh
  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
  ```
''')
param customLocationsOid string

@description('Whether to enable auto-upgrades for Arc agents.')
param shouldEnableArcAutoUpgrade bool

/*
  Arc Onboarding Parameters
*/

@description('The Service Principal Client ID for Arc onboarding.')
param arcOnboardingSpClientId string?

@description('The Service Principal Client Secret for Arc onboarding.')
@secure()
param arcOnboardingSpClientSecret string?

/*
  Cluster Configuration Parameters
*/

@description('The Object ID that will be given cluster-admin permissions.')
param clusterAdminOid string?

@description('Username for the host machine with kube-config settings.')
param clusterServerHostMachineUsername string

@description('The IP address for the server for the cluster. (Needed for mult-node cluster)')
param clusterServerIp string?

@description('The Object ID that will be given deployment admin permissions.')
param deployAdminOid string?

@description('The token that will be given to the server for the cluster or used by agent nodes.')
@secure()
param serverToken string?

/*
  Key Vault Parameters
*/

@description('The name for the deploy user token secret in Key Vault.')
param deployUserTokenSecretName string

@description('The name of the Key Vault to save the scripts to.')
param keyVaultName string

@description('The name for the K3s token secret in Key Vault.')
param k3sTokenSecretName string

@description('The name for the node script secret in Key Vault.')
param nodeScriptSecretName string

@description('The name for the server script secret in Key Vault.')
param serverScriptSecretName string

/*
  Deployment Configuration Parameters
*/

@description('Should skip login process with Azure CLI on the server.')
param shouldSkipAzCliLogin bool

@description('Should skip downloading and installing Azure CLI on the server.')
param shouldSkipInstallingAzCli bool

/*
  Local variables
*/

var clusterServerUrl = !empty(clusterServerIp) ? 'https://${clusterServerIp}:6443' : null

var serverEnvVars = {
  K3S_NODE_TYPE: 'server'
  CLUSTER_ADMIN_OID: clusterAdminOid
  SKIP_ARC_CONNECT: ''
  DEPLOY_ADMIN_OID: deployAdminOid
}

var nodeEnvVars = {
  K3S_NODE_TYPE: 'agent'
  CLUSTER_ADMIN_OID: ''
  SKIP_ARC_CONNECT: 'true'
  DEPLOY_ADMIN_OID: ''
}

// Define default environment variables
var defaultEnvVars = {
  ENVIRONMENT: common.environment
  ARC_RESOURCE_GROUP_NAME: resourceGroup().name
  ARC_RESOURCE_NAME: arcResourceName
  K3S_URL: clusterServerUrl
  K3S_TOKEN: serverToken ?? ''
  K3S_VERSION: ''
  AKV_NAME: keyVaultName
  AKV_K3S_TOKEN_SECRET: k3sTokenSecretName
  AKV_DEPLOY_SAT_SECRET: deployUserTokenSecretName
  ARC_AUTO_UPGRADE: string(shouldEnableArcAutoUpgrade)
  ARC_SP_CLIENT_ID: arcOnboardingSpClientId
  ARC_SP_SECRET: arcOnboardingSpClientSecret
  ARC_TENANT_ID: arcTenantId
  AZ_CLI_VER: ''
  AZ_CONNECTEDK8S_VER: ''
  CUSTOM_LOCATIONS_OID: customLocationsOid ?? ''
  DEVICE_USERNAME: clusterServerHostMachineUsername
  SKIP_INSTALL_AZ_CLI: shouldSkipInstallingAzCli ? 'true' : ''
  SKIP_AZ_LOGIN: shouldSkipAzCliLogin ? 'true' : ''
  SKIP_INSTALL_K3S: ''
  SKIP_INSTALL_KUBECTL: ''
}

// Resolve server env variable assignments.
var combinedServerEnvVars = union(defaultEnvVars, serverEnvVars)
var serverEnvVarStrings = map(
  filter(items(combinedServerEnvVars), envVar => !empty(envVar.value)),
  envVar => '${envVar.key}="${envVar.value}";'
)
var resolvedServerEnvVarsString = join(serverEnvVarStrings, '\n')

// Resolve node env variable assignments.
var combinedNodeEnvVars = union(defaultEnvVars, nodeEnvVars)
var nodeEnvVarStrings = map(
  filter(items(combinedNodeEnvVars), envVar => !empty(envVar.value)),
  envVar => '${envVar.key}="${envVar.value}";'
)
var resolvedNodeEnvVarsString = join(nodeEnvVarStrings, '\n')

// Every loadTextContent results in the contents of the file being loaded into a variable that's then built into the
// ARM that's ultimately deployed. Reduce the number of loadTextContent calls to one to prevent any future issues.
var scriptFileContents = replace(loadTextContent('../../scripts/k3s-device-setup.sh'), '\r\n', '\n')
var effectiveClusterServerScript = '#!/usr/bin/env bash\n\n${resolvedServerEnvVarsString}\n\n${scriptFileContents}'
var effectiveClusterNodeScript = '#!/usr/bin/env bash\n\n${resolvedNodeEnvVarsString}\n\n${scriptFileContents}'

/*
  Resources
*/

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVaultName

  resource serverScriptSecret 'secrets' = {
    name: serverScriptSecretName
    properties: {
      value: effectiveClusterServerScript
      contentType: 'text/plain'
    }
  }

  resource nodeScriptSecret 'secrets' = {
    name: nodeScriptSecretName
    properties: {
      value: effectiveClusterNodeScript
      contentType: 'text/plain'
    }
  }

  // Add secret for server token and deploy user token when @onlyIfNotExist() is supported.
  // Update role assignment to only give secrets officer scoped to these secrets.
}

/*
  Outputs
*/

@description('The script for setting up the host machine for the cluster server.')
@secure()
output clusterServerScript string = effectiveClusterServerScript

@description('The script for setting up the host machine for the cluster node.')
@secure()
output clusterNodeScript string = effectiveClusterNodeScript

@description('The Key Vault Secret name for the script for setting up the host machine for the cluster server.')
output clusterServerScriptSecretName string = keyVault::serverScriptSecret.name

@description('The Key Vault Secret name for the script for setting up the host machine for the cluster node.')
output clusterNodeScriptSecretName string = keyVault::nodeScriptSecret.name
