metadata name = 'Event Hub Data Receiver Role Assignment Module'
metadata description = 'Grants the notification Logic App identity the Azure Event Hubs Data Receiver role on the Event Hub namespace.'

/*
  Parameters
*/

@description('The name of the Event Hub namespace to scope the role assignment to.')
param eventhubNamespaceName string

@description('The principal ID granted the Azure Event Hubs Data Receiver role.')
param principalId string

/*
  Variables
*/

@description('Azure Event Hubs Data Receiver role definition ID.')
var eventHubsDataReceiverRoleId = 'a638d3c7-ab3a-418d-83e6-5f17a39d4fde'

/*
  Resources
*/

resource eventhubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' existing = {
  name: eventhubNamespaceName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(eventhubNamespace.id, principalId, eventHubsDataReceiverRoleId)
  scope: eventhubNamespace
  properties: {
    principalId: principalId
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/analytics#azure-event-hubs-data-receiver
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', eventHubsDataReceiverRoleId)
    principalType: 'ServicePrincipal'
  }
}

/*
  Outputs
*/

@description('The resource ID of the role assignment.')
output roleAssignmentId string = roleAssignment.id
