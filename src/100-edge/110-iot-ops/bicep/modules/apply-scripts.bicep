metadata name = 'Apply Scripts'
metadata description = 'Runs deployment scripts for IoT Operations using an Azure deploymentScript resource, including tool installation and script execution.'

import * as core from '../types.core.bicep'
import * as types from '../types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The resource ID of the deploy Managed Identity used to execute the scripts.')
param deployIdentityId string?

@description('The Client ID for a Service Principal for deployment scripts.')
param deploySpClientId string?

@description('The Client Secret for a Service Principal for deployment scripts.')
@secure()
param deploySpSecret string?

@description('The Tenant ID for a Service Principal for deployment scripts.')
param deploySpTenantId string?

/*
  Script Parameters
*/

@description('The name of the Key Vault that will have scripts and secrets for deployment.')
param deployKeyVaultName string

@description('The prefix used with constructing the secret name that will have the deployment script. (e.g., ds-iot-ops-0, ds-iot-ops-1)')
param deploymentScriptsSecretNamePrefix string

@description('The name of the DeploymentScript resource.')
param deploymentScriptName string = 'ds-${deploymentScriptsSecretNamePrefix}'

@description('The names of Key Vault Secrets with scripts to deploy.')
param scriptSecretNames (string?)[] = []

@description('The names of Key Vault Secrets with environment variable scripts to deploy.')
param environmentVariableSecretNames (string?)[] = []

@description('The names of Key Vault Secrets with include files scripts to deploy.')
param includeFileSecretNames (string?)[] = []

/*
  Local Functions
*/

func toEnvVarArray(arr (string?)[]) string => join(map(arr, i => !empty(i)), ' ')

/*
  Resources
*/

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: deploymentScriptName
  location: common.location

  kind: 'AzureCLI'
  identity: deployIdentityId != null
    ? {
        type: 'UserAssigned'
        userAssignedIdentities: {
          '${deployIdentityId}': {}
        }
      }
    : {
        type: 'SystemAssigned'
      }

  properties: {
    azCliVersion: '2.71.0'
    retentionInterval: 'P1D'
    timeout: 'PT15M'
    environmentVariables: [
      {
        name: 'DEPLOY_KEY_VAULT_NAME'
        value: deployKeyVaultName
      }
      {
        name: 'DEPLOY_SP_CLIENT_ID'
        value: deploySpClientId
      }
      {
        name: 'DEPLOY_SP_SECRET'
        secureValue: deploySpSecret
      }
      {
        name: 'DEPLOY_SP_TENANT_ID'
        value: deploySpTenantId
      }
      {
        name: 'ADDITIONAL_FILES_SECRET_NAMES'
        value: toEnvVarArray(includeFileSecretNames)
      }
      {
        name: 'ENV_VAR_SECRET_NAMES'
        value: toEnvVarArray(environmentVariableSecretNames)
      }
      {
        name: 'SCRIPT_SECRET_NAMES'
        value: toEnvVarArray(scriptSecretNames)
      }
    ]
    scriptContent: loadTextContent('../../scripts/deployment-script.sh')
    cleanupPreference: 'OnExpiration'
  }
}

/*
  Outputs
*/

@description('The name of the deployment script resource.')
output deploymentScriptName string = deploymentScript.name

@description('The ID of the deployment script resource.')
output deploymentScriptId string = deploymentScript.id
