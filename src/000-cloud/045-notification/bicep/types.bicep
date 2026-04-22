/*
  Dependency types for the 045-notification module.
  These shapes mirror the objects produced by the cloud-resource-group,
  040-messaging, and 030-data modules.
*/

@export()
@description('Resource group reference containing name, id, and location.')
type ResourceGroupRef = {
  name: string
  id: string
  location: string
}

@export()
@description('Event Hub namespace reference.')
type EventHubNamespaceRef = {
  id: string
  name: string
}

@export()
@description('Storage account reference used for leak-session tracking table.')
type StorageAccountRef = {
  id: string
  name: string
}

@export()
@description('Logic App workflow output shape returned by this module.')
type LogicAppRef = {
  id: string
  name: string
  identityPrincipalId: string
}
