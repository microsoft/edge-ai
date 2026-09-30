metadata name = 'Key Vault Script Secrets Module'
metadata description = 'Uploads the cluster setup scripts to Key Vault as gzip-compressed, base64-encoded secrets using a deployment script to stay within the Key Vault secret size limit.'

import * as core from '../types.core.bicep'

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

@description('The name for the node script secret in Key Vault.')
param nodeScriptSecretName string

@description('The name for the server script secret in Key Vault.')
param serverScriptSecretName string

/*
  Script Parameters
*/

@description('The script for setting up the host machine for the cluster node.')
@secure()
param clusterNodeScript string

@description('The script for setting up the host machine for the cluster server.')
@secure()
param clusterServerScript string

/*
  Variables
*/

var uploadScriptContent = '''
set -euo pipefail

upload_script_secret() {
  local secret_name="$1"
  local script_content="$2"
  local secret_file
  secret_file="$(mktemp)"
  chmod 600 "$secret_file"

  printf '%s' "$script_content" | gzip -9 -n | base64 -w0 >"$secret_file"

  for attempt in $(seq 1 10); do
    if az keyvault secret set \
      --vault-name "$KEY_VAULT_NAME" \
      --name "$secret_name" \
      --file "$secret_file" \
      --content-type 'application/gzip;base64' \
      --output none; then
      rm -f "$secret_file"
      return 0
    fi
    echo "Setting Key Vault secret '$secret_name' attempt $attempt/10 failed, retrying in 30s..."
    sleep 30
  done

  rm -f "$secret_file"
  echo "Failed to set Key Vault secret '$secret_name'" >&2
  return 1
}

upload_script_secret "$SERVER_SCRIPT_SECRET_NAME" "$SERVER_SCRIPT"
upload_script_secret "$NODE_SCRIPT_SECRET_NAME" "$NODE_SCRIPT"
'''

/*
  Resources
*/

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVaultName
}

resource scriptSecretsIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'id-${common.resourcePrefix}-cluster-scripts-${common.environment}-${common.instance}'
  location: common.location
}

resource keyVaultSecretsOfficerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, scriptSecretsIdentity.id, 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
  scope: keyVault
  properties: {
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-secrets-officer
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
    )
    principalId: scriptSecretsIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource uploadScriptSecrets 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'ds-${common.resourcePrefix}-cluster-scripts-${common.environment}-${common.instance}'
  location: common.location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${scriptSecretsIdentity.id}': {}
    }
  }
  dependsOn: [
    keyVaultSecretsOfficerRole
  ]
  properties: {
    azCliVersion: '2.71.0'
    retentionInterval: 'PT1H'
    timeout: 'PT15M'
    cleanupPreference: 'OnSuccess'
    environmentVariables: [
      {
        name: 'KEY_VAULT_NAME'
        value: keyVaultName
      }
      {
        name: 'SERVER_SCRIPT_SECRET_NAME'
        value: serverScriptSecretName
      }
      {
        name: 'NODE_SCRIPT_SECRET_NAME'
        value: nodeScriptSecretName
      }
      {
        name: 'SERVER_SCRIPT'
        secureValue: clusterServerScript
      }
      {
        name: 'NODE_SCRIPT'
        secureValue: clusterNodeScript
      }
    ]
    scriptContent: uploadScriptContent
  }
}

/*
  Outputs
*/

@description('The Key Vault Secret name for the script for setting up the host machine for the cluster server.')
output clusterServerScriptSecretName string = serverScriptSecretName

@description('The Key Vault Secret name for the script for setting up the host machine for the cluster node.')
output clusterNodeScriptSecretName string = nodeScriptSecretName

@description('The name of the deployment script resource that uploads the script secrets.')
output deploymentScriptName string = uploadScriptSecrets.name
