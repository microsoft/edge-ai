metadata name = 'AKS and ACR Component Types'
metadata description = 'Type definitions and defaults for the AKS and ACR component.'

import * as core from './types.core.bicep'

/*
  Container Registry Configuration
*/

@export()
@description('The settings for the Azure Container Registry.')
type ContainerRegistry = {
  @description('The SKU for the Azure Container Registry. Options are Basic, Standard, Premium.')
  sku: 'Basic' | 'Standard' | 'Premium'
}

@export()
var containerRegistryDefaults = {
  sku: 'Premium'
}
