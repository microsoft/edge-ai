metadata name = 'Microsoft Foundry Component Type Definitions'
metadata description = 'Type definitions for Microsoft Foundry component including configuration, projects, deployments, and RAI policies.'

/*
  Microsoft Foundry Configuration Type
*/

@export()
@description('Configuration settings for Microsoft Foundry account.')
type AiFoundryConfig = {
  @description('SKU name for the Microsoft Foundry account.')
  sku: string

  @description('Whether to enable public network access.')
  shouldEnablePublicNetworkAccess: bool

  @description('Whether to enable local authentication (API keys).')
  shouldEnableLocalAuth: bool
}

@export()
@description('Default Microsoft Foundry configuration.')
var aiFoundryConfigDefaults = {
  sku: 'S0'
  shouldEnablePublicNetworkAccess: true
  shouldEnableLocalAuth: true
}

/*
  Project Type
*/

@export()
@description('Configuration for a Microsoft Foundry project.')
type AiProject = {
  @description('Project resource name.')
  name: string

  @description('Display name shown in portal.')
  displayName: string

  @description('Project description.')
  description: string
}

/*
  Model Deployment Types
*/

@export()
@description('Configuration for a model deployment.')
type ModelDeployment = {
  @description('Deployment resource name.')
  name: string

  @description('Model configuration.')
  model: {
    @description('Model provider format.')
    format: string

    @description('Model name.')
    name: string

    @description('Model version.')
    version: string
  }

  @description('Scale configuration.')
  scale: {
    @description('SKU type: Standard, GlobalStandard, ProvisionedManaged.')
    type: string

    @description('Capacity in TPM thousands.')
    capacity: int
  }

  @description('Optional RAI policy name.')
  raiPolicyName: string?

  @description('Version upgrade option.')
  versionUpgradeOption: ('NoAutoUpgrade' | 'OnceCurrentVersionExpired' | 'OnceNewDefaultVersionAvailable')?
}

/*
  RAI Policy Types
*/

@export()
@description('Content filter configuration.')
type ContentFilter = {
  @description('Filter name: Hate, Violence, Sexual, SelfHarm.')
  name: string

  @description('Whether filter is enabled.')
  enabled: bool

  @description('Whether filter blocks content.')
  blocking: bool

  @description('Severity threshold.')
  severityThreshold: 'Low' | 'Medium' | 'High'

  @description('Filter source: Prompt or Completion.')
  source: 'Prompt' | 'Completion'
}

@export()
@description('Configuration for a RAI policy.')
type RaiPolicy = {
  @description('Policy resource name.')
  name: string

  @description('Base policy to inherit from.')
  basePolicyName: string

  @description('Policy mode.')
  mode: 'Blocking' | 'Logging'

  @description('Content filter configurations.')
  contentFilters: ContentFilter[]
}
