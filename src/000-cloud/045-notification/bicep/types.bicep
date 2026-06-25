metadata name = 'Notification Component Types'
metadata description = 'Type definitions for the Notification Component Logic App and storage references.'

/*
  Type Definitions
*/

@export()
@description('Reference details for a Logic App workflow with a system-assigned identity.')
type LogicAppReference = {
  @description('The resource ID of the Logic App workflow.')
  id: string

  @description('The name of the Logic App workflow.')
  name: string

  @description('The principal ID of the Logic App workflow system-assigned identity.')
  identityPrincipalId: string
}

@export()
@description('Reference details for the storage account used for session state tracking.')
type StorageAccountReference = {
  @description('The resource ID of the storage account.')
  id: string

  @description('The name of the storage account.')
  name: string
}
