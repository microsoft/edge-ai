metadata name = 'Deploy Script Setup Secrets'
metadata description = 'Creates secrets in Key Vault for deployment script setup and initialization for Azure IoT Operations.'

import * as core from '../types.core.bicep'
import * as types from '../types.bicep'

/*
  Common Parameters
*/

@description('The name of the Arc connected cluster.')
param arcConnectedClusterName string

@description('The resource group name where the Arc connected cluster is located.')
param resourceGroupName string

@description('The namespace for Azure IoT Operations in the cluster.')
param aioNamespace string

/*
  Script Parameters
*/

@description('The name of the Key Vault that will have scripts and secrets for deployment.')
param deployKeyVaultName string

@description('The resource group name where the Key Vault is located. Defaults to the current resource group.')
param deployKeyVaultResourceGroupName string

@description('The prefix used with constructing the secret name that will have the deployment script. (e.g., ds-iot-ops-0, ds-iot-ops-1)')
param deploySecretNamePrefix string

@description('The name of the secret in Key Vault that has the token for the deploy user with cluster-admin role.')
param deployUserTokenSecretName string

/*
  OPC UA Simulator Parameters
*/

@description('Whether or not to enable the OPC UA Simulator for Azure IoT Operations.')
param shouldEnableOpcUaSimulator bool = true

/*
  Variables
*/

/*
  Variables - Script Files
*/

var scriptFiles = types.emptyScriptFiles()

/*
  Variables - OPC UA Simulator
*/

var opc = types.toScriptFiles(
  scriptFiles,
  shouldEnableOpcUaSimulator,
  {
    content: loadTextContent('../../scripts/apply-simulator.sh')
  },
  []
)

/*
  Variables - Complete Script with Include Files
*/

var deployScript = types.tryCreateDeployScriptFiles(
  deployUserTokenSecretName,
  arcConnectedClusterName,
  resourceGroupName,
  aioNamespace,
  opc
)

/*
  Modules
*/

module scriptSecrets './key-vault-deploy-script-secrets.bicep' = {
  name: '${deployment().name}-secrets'
  scope: resourceGroup(deployKeyVaultResourceGroupName)

  params: {
    deployKeyVaultName: deployKeyVaultName
    secretNamePrefix: deploySecretNamePrefix
    scripts: deployScript.?scripts
    includeFiles: deployScript.?includeFiles
  }
}

/*
  Outputs
*/

@description('The name of the Key Vault include files secret, if created.')
output includeFilesSecretName string? = scriptSecrets.outputs.?includeFilesSecretName

@description('The URI of the Key Vault include files secret, if created.')
output includeFilesSecretUri string? = scriptSecrets.outputs.?includeFilesSecretUri

@description('The name of the Key Vault environment variables secret, if created.')
output environmentVariablesSecretName string? = scriptSecrets.outputs.?environmentVariablesSecretName

@description('The URI of the Key Vault environment variables secret, if created.')
output environmentVariablesSecretUri string? = scriptSecrets.outputs.?environmentVariablesSecretUri

@description('The name of the Key Vault script secret, if created.')
output scriptSecretName string? = scriptSecrets.outputs.?scriptSecretName

@description('The URI of the Key Vault script secret, if created.')
output scriptSecretUri string? = scriptSecrets.outputs.?scriptSecretUri
