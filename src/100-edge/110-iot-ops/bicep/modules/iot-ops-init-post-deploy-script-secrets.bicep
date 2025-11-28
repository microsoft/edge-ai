metadata name = 'Deploy Script Setup Secrets'
metadata description = 'Creates secrets in Key Vault for deployment script setup and initialization for Azure IoT Operations.'

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
  Customer Managed Trust Parameters
*/

@description('The name of the existing key vault for Azure IoT Operations instance.')
param sseKeyVaultName string

@description('The name of the User Assigned Managed Identity for Secret Sync.')
param sseIdentityName string

@description('The trust issuer settings for Customer Managed Azure IoT Operations Settings.')
param trustIssuerSettings types.TrustIssuerConfig

/*
  OpenTelemetry Collector Parameters
*/

@description('Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.')
param shouldEnableOtelCollector bool

/*
  Resources
*/

resource sseIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = {
  name: sseIdentityName
}

/*
  Variables
*/

var isCustomerManagedGenerateIssuer = trustIssuerSettings.trustSource == 'CustomerManagedGenerateIssuer'

/*
  Variables - Script Files
*/

var scriptFiles = types.emptyScriptFiles()

/*
  Variables - Customer Managed Trust
*/

var ca = types.toScriptFiles(
  scriptFiles,
  isCustomerManagedGenerateIssuer,
  {
    content: loadTextContent('../../scripts/aio-akv-certs.sh')
    env: trustIssuerSettings.?aioCa == null
      ? [
          {
            name: 'AKV_NAME'
            value: sseKeyVaultName
          }
          {
            name: 'ENABLE_SELF_SIGNED'
            value: 'true'
          }
        ]
      : [
          {
            name: 'AKV_NAME'
            value: sseKeyVaultName
          }
          {
            name: 'ROOT_CA_CERT'
            secureValue: trustIssuerSettings.aioCa!.rootCaCertPem
          }
          {
            name: 'CA_CERT_CHAIN'
            secureValue: trustIssuerSettings.aioCa!.caCertChainPem
          }
          {
            name: 'CA_KEY'
            secureValue: trustIssuerSettings.aioCa!.caKeyPem
          }
        ]
  },
  []
)

var trust = types.toScriptFiles(
  ca,
  isCustomerManagedGenerateIssuer,
  {
    content: loadTextContent('../../scripts/apply-trust.sh')
    env: [
      {
        name: 'TF_SSE_USER_ASSIGNED_CLIENT_ID'
        value: sseIdentity.properties.clientId
      }
      {
        name: 'TF_KEY_VAULT_NAME'
        value: sseKeyVaultName
      }
      {
        name: 'TF_AIO_CONFIGMAP_KEY'
        value: types.defaultCustomerManagedTrustSettings.configMapKey
      }
      {
        name: 'TF_AIO_CONFIGMAP_NAME'
        value: types.defaultCustomerManagedTrustSettings.configMapName
      }
      {
        name: 'TF_AIO_ISSUER_KIND'
        value: types.defaultCustomerManagedTrustSettings.issuerKind
      }
      {
        name: 'TF_AIO_ISSUER_NAME'
        value: types.defaultCustomerManagedTrustSettings.issuerName
      }
    ]
  },
  [
    {
      name: 'yaml/trust/sa.yaml'
      content: loadTextContent('../../yaml/trust/sa.yaml')
    }
    {
      name: 'yaml/trust/spc.yaml'
      content: loadTextContent('../../yaml/trust/spc.yaml')
    }
    {
      name: 'yaml/trust/secretsync.yaml'
      content: loadTextContent('../../yaml/trust/secretsync.yaml')
    }
    {
      name: 'yaml/trust/customer-issuer.yaml'
      content: loadTextContent('../../yaml/trust/customer-issuer.yaml')
    }
    {
      name: 'yaml/trust/bundle.yaml'
      content: loadTextContent('../../yaml/trust/bundle.yaml')
    }
  ]
)

/*
  Variables - Observability
*/

var obs = types.toScriptFiles(
  trust,
  shouldEnableOtelCollector,
  {
    content: loadTextContent('../../scripts/apply-otel-collector.sh')
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
  obs
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
