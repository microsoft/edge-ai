metadata name = 'Key Vault Apply Scripts Secrets'
metadata description = 'Creates and manages script-related secrets in Azure Key Vault for deployment operations.'

import * as types from './../types.bicep'

/*
  Parameters
*/

@description('The name of the Key Vault that will have scripts and secrets for deployment.')
param deployKeyVaultName string

@description('The prefix used with constructing the secret name that will have the deployment script. (e.g., ds-iot-ops-0, ds-iot-ops-1)')
param secretNamePrefix string

@description('Array of objects with script content and environment variables. (If not empty, creates secretNamePrefix-script and secretNamePrefix-env secrets in Key Vault)')
param scripts types.ScriptConfig[] = []

@description('Array of additional files to create before executing scripts. (If not empty, creates secretNamePrefix-files secret in Key Vault)')
param includeFiles types.IncludeFileConfig[] = []

/*
  Functions
*/

func multiLineContent(fileLines string[][]) string? =>
  !empty(fileLines) ? join(map(fileLines, lines => join(lines, '\n')), '\n') : null

func multiLinePartsContent(begin string, fileLines string[][], end string) string? =>
  !empty(fileLines)
    ? multiLineContent([
        [begin]
        fileLines
        [end]
      ])
    : null

/*
  Variables
*/

// Additional files that are needed for the applying script.
var includeFileScriptContent = multiLinePartsContent(
  '#!/usr/bin/env bash',
  map(includeFiles, file => [
    'echo "Creating file ${file.name}..."'
    'mkdir -p "$(dirname ${file.name})"'
    'cat > ${file.name} <<EOF'
    '${file.content}'
    'EOF'
  ]),
  'echo "Finished writing out additional files..."'
)

// Environment variable script content that is meant to be `source`'d from the applying script.
var reducedEnvironmentVariables = flatten(map(filter(scripts, script => script.?env != null), script => script.env!))
var environmentVariablesScriptContent = multiLineContent(map(
  reducedEnvironmentVariables,
  envVar => ['export ${envVar.name}="${envVar.?value ?? envVar.?secureValue ?? ''}"']
))

// Script content that is meant to be `source`'d from the applying script.
var scriptContent = multiLinePartsContent(
  '#!/usr/bin/env bash',
  map(scripts, script => [script.content]),
  'echo "Finished executing scripts..."'
)

/*
  Resources
*/

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: deployKeyVaultName

  resource includeFiles 'secrets' = if (!empty(includeFileScriptContent)) {
    name: '${secretNamePrefix}-files'
    properties: {
      value: includeFileScriptContent
      contentType: 'text/plain'
    }
  }

  resource environmentVariables 'secrets' = if (!empty(environmentVariablesScriptContent)) {
    name: '${secretNamePrefix}-env'
    properties: {
      value: environmentVariablesScriptContent
      contentType: 'text/plain'
    }
  }

  resource script 'secrets' = if (!empty(scriptContent)) {
    name: '${secretNamePrefix}-script'
    properties: {
      value: scriptContent
      contentType: 'text/plain'
    }
  }
}

/*
  Outputs
*/

@description('The name of the Key Vault include files secret if created.')
output includeFilesSecretName string? = !empty(includeFileScriptContent) ? keyVault::includeFiles.name : null

@description('The URI of the Key Vault include files secret if created.')
output includeFilesSecretUri string? = !empty(includeFileScriptContent)
  ? keyVault::includeFiles.properties.secretUri
  : null

@description('The name of the Key Vault environment variables secret if created.')
output environmentVariablesSecretName string? = !empty(environmentVariablesScriptContent)
  ? keyVault::environmentVariables.name
  : null

@description('The URI of the Key Vault environment variables secret if created.')
output environmentVariablesSecretUri string? = !empty(environmentVariablesScriptContent)
  ? keyVault::environmentVariables.properties.secretUri
  : null

@description('The name of the Key Vault script secret if created.')
output scriptSecretName string? = !empty(scriptContent) ? keyVault::script.name : null

@description('The URI of the Key Vault script secret if created.')
output scriptSecretUri string? = !empty(scriptContent) ? keyVault::script.properties.secretUri : null
