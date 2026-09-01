metadata name = 'Notification Component'
metadata description = 'Deploys Azure Logic Apps for Event Hub event notifications with Table Storage session deduplication. The primary workflow polls an Event Hub, deduplicates sessions in Azure Table Storage, and posts new-event alerts to Microsoft Teams. A secondary workflow exposes an HTTP endpoint to close active event sessions. The Teams connection requires user consent after deployment via the Azure Portal.'

import * as core from './types.core.bicep'
import * as types from './types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Dependency Parameters
*/

@description('The name of the Event Hub namespace for Logic App trigger connectivity and role assignment.')
param eventhubNamespaceName string

@description('The name of the Event Hub to subscribe to for events.')
param eventhubName string

@description('The name of the storage account used for event session state tracking via Table Storage.')
param storageAccountName string

@description('JSON schema object for parsing Event Hub events in the Logic App Parse_Event action.')
param eventSchema object

@description('HTML template for new-event Teams notifications. Supports the `\${close_session_url}` placeholder and Logic App expression syntax for dynamic event fields.')
param notificationMessageTemplate string

@description('HTML message body for session-closure Teams notifications. Supports Logic App expression syntax for dynamic fields.')
param closureMessageTemplate string

@description('Event schema field name used as the Table Storage partition key for session state deduplication lookups.')
param partitionKeyField string

@description('Teams chat or channel thread ID for posting event notifications.')
@secure()
param teamsRecipientId string

@description('Microsoft 365 Group ID (Team ID) for posting to a Teams channel. Required when teamsPostLocation is \'Channel\'.')
param teamsGroupId string?

@description('Teams posting location: \'Channel\' or \'Group chat\'.')
param teamsPostLocation ('Channel' | 'Group chat') = 'Channel'

/*
  Optional Parameters
*/

@description('Consumer group for the Event Hub trigger.')
param eventhubConsumerGroup string = '$Default'

@description('Maximum events retrieved per trigger execution.')
param maximumEventsCount int = 50

@description('Polling interval in seconds for the Event Hub trigger.')
param pollingInterval int = 5

@description('Whether to create role assignments for the Logic App managed identities.')
param shouldAssignRoles bool = true

@description('Azure Table Storage table name for session state tracking.')
param tableName string = 'notifications'

/*
  Local Variables
*/

var notificationPurpose = 'notify'
var closePurpose = 'close'

var logicAppName = 'la-${common.resourcePrefix}-${notificationPurpose}-${common.environment}-${common.instance}'
var closeLogicAppName = 'la-${common.resourcePrefix}-${closePurpose}-${common.environment}-${common.instance}'
var eventhubConnName = 'conn-evh-${common.resourcePrefix}-${common.environment}-${common.instance}'
var teamsConnName = 'conn-teams-${common.resourcePrefix}-${common.environment}-${common.instance}'

var tableEndpoint = 'https://${storageAccountName}.table.${environment().suffixes.storage}'

var eventhubManagedApiId = subscriptionResourceId('Microsoft.Web/locations/managedApis', common.location, 'eventhubs')
var teamsManagedApiId = subscriptionResourceId('Microsoft.Web/locations/managedApis', common.location, 'teams')

var teamsNotificationRecipient = teamsPostLocation == 'Channel'
  ? {
      groupId: teamsGroupId
      channelId: teamsRecipientId
    }
  : teamsRecipientId

var insertEntityBody = {
  PartitionKey: '@{body(\'Parse_Event\')?[\'${partitionKeyField}\']}'
  RowKey: 'active'
  FirstDetectedAt: '@{utcNow()}'
  LastEventAt: '@{utcNow()}'
  EventCount: 1
}

var updateEntityBody = {
  LastEventAt: '@{utcNow()}'
  EventCount: '@{add(int(body(\'Get_Active_Session\')?[\'EventCount\']), 1)}'
}

var closeSessionCallbackUrl = listCallbackUrl('${closeSession.id}/triggers/Close_Session_Request', '2019-05-01').value

var notificationMessageBody = replace(notificationMessageTemplate, '\${close_session_url}', closeSessionCallbackUrl)

/*
  Existing Resources
*/

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: storageAccountName

  resource tableService 'tableServices' existing = {
    name: 'default'
  }
}

/*
  Resources
*/

resource eventSessionsTable 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01' = {
  parent: storageAccount::tableService
  name: tableName
}

resource eventhubConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: eventhubConnName
  location: common.location
  properties: {
    displayName: 'Event Hub (Managed Identity)'
    api: {
      id: eventhubManagedApiId
    }
    #disable-next-line BCP089
    parameterValueSet: {
      name: 'managedIdentityAuth'
      values: {
        namespaceEndpoint: {
          value: 'sb://${eventhubNamespaceName}.servicebus.windows.net/'
        }
      }
    }
  }
}

resource teamsConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: teamsConnName
  location: common.location
  properties: {
    displayName: 'Teams'
    api: {
      id: teamsManagedApiId
    }
  }
}

resource closeSession 'Microsoft.Logic/workflows@2019-05-01' = {
  name: closeLogicAppName
  location: common.location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        Close_Session_Request: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            method: 'GET'
            schema: {}
          }
        }
      }
      actions: {
        Get_Active_Session: {
          type: 'Http'
          inputs: {
            method: 'GET'
            uri: '${tableEndpoint}/${tableName}(PartitionKey=\'@{triggerOutputs()[\'queries\'][\'device\']}\',RowKey=\'active\')'
            headers: {
              Accept: 'application/json;odata=nometadata'
              'x-ms-version': '2020-12-06'
            }
            authentication: {
              type: 'ManagedServiceIdentity'
              audience: 'https://storage.azure.com/'
            }
          }
          runAfter: {}
        }
        Delete_Entity: {
          type: 'Http'
          inputs: {
            method: 'DELETE'
            uri: '${tableEndpoint}/${tableName}(PartitionKey=\'@{triggerOutputs()[\'queries\'][\'device\']}\',RowKey=\'active\')'
            headers: {
              Accept: 'application/json;odata=nometadata'
              'x-ms-version': '2020-12-06'
              'If-Match': '*'
            }
            authentication: {
              type: 'ManagedServiceIdentity'
              audience: 'https://storage.azure.com/'
            }
          }
          runAfter: {
            Get_Active_Session: ['Succeeded']
          }
        }
        Post_Closure_Summary: {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'teams\'][\'connectionId\']'
              }
            }
            method: 'post'
            body: {
              recipient: teamsNotificationRecipient
              messageBody: closureMessageTemplate
            }
            path: '/beta/teams/conversation/message/poster/Flow bot/location/@{encodeURIComponent(\'${teamsPostLocation}\')}'
          }
          runAfter: {
            Delete_Entity: ['Succeeded']
          }
        }
        Response: {
          type: 'Response'
          kind: 'Http'
          inputs: {
            statusCode: '@{if(equals(actions(\'Delete_Entity\')[\'status\'], \'Succeeded\'), 200, if(equals(actions(\'Get_Active_Session\')[\'status\'], \'Failed\'), 404, 500))}'
            headers: {
              'Content-Type': 'text/plain'
            }
            body: '@{if(equals(actions(\'Delete_Entity\')[\'status\'], \'Succeeded\'), \'Session closed\', if(equals(actions(\'Get_Active_Session\')[\'status\'], \'Failed\'), \'No active session found\', \'Failed to close session\'))}'
          }
          runAfter: {
            Post_Closure_Summary: ['Succeeded', 'Failed', 'Skipped', 'TimedOut']
          }
        }
      }
    }
    parameters: {
      '$connections': {
        value: {
          teams: {
            connectionId: teamsConnection.id
            connectionName: teamsConnection.name
            id: teamsManagedApiId
            connectionProperties: {}
          }
        }
      }
    }
  }
}

resource teamsNotification 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: common.location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        When_events_are_available_in_Event_Hub: {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'eventhubs\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/@{encodeURIComponent(\'${eventhubName}\')}/events/batch/head'
            queries: {
              contentType: 'application/octet-stream'
              consumerGroupName: eventhubConsumerGroup
              maximumEventsCount: maximumEventsCount
            }
          }
          recurrence: {
            frequency: 'Second'
            interval: pollingInterval
          }
        }
      }
      actions: {
        For_Each_Event: {
          type: 'Foreach'
          foreach: '@triggerBody()'
          operationOptions: 'Sequential'
          actions: {
            Parse_Event: {
              type: 'ParseJson'
              inputs: {
                content: '@base64ToString(items(\'For_Each_Event\')?[\'ContentData\'])'
                schema: eventSchema
              }
              runAfter: {}
            }
            Get_Active_Session: {
              type: 'Http'
              inputs: {
                method: 'GET'
                uri: '${tableEndpoint}/${tableName}(PartitionKey=\'@{body(\'Parse_Event\')?[\'${partitionKeyField}\']}\',RowKey=\'active\')'
                headers: {
                  Accept: 'application/json;odata=nometadata'
                  'x-ms-version': '2020-12-06'
                }
                authentication: {
                  type: 'ManagedServiceIdentity'
                  audience: 'https://storage.azure.com/'
                }
              }
              runAfter: {
                Parse_Event: ['Succeeded']
              }
            }
            Check_New_Session: {
              type: 'If'
              expression: {
                and: [
                  {
                    equals: [
                      '@outputs(\'Get_Active_Session\')[\'statusCode\']'
                      404
                    ]
                  }
                ]
              }
              actions: {
                Insert_Entity: {
                  type: 'Http'
                  inputs: {
                    method: 'POST'
                    uri: '${tableEndpoint}/${tableName}'
                    headers: {
                      'Content-Type': 'application/json'
                      Accept: 'application/json;odata=nometadata'
                      'x-ms-version': '2020-12-06'
                    }
                    body: insertEntityBody
                    authentication: {
                      type: 'ManagedServiceIdentity'
                      audience: 'https://storage.azure.com/'
                    }
                  }
                  runAfter: {}
                }
                Post_Teams_Notification: {
                  type: 'ApiConnection'
                  inputs: {
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'teams\'][\'connectionId\']'
                      }
                    }
                    method: 'post'
                    body: {
                      recipient: teamsNotificationRecipient
                      messageBody: notificationMessageBody
                    }
                    path: '/beta/teams/conversation/message/poster/Flow bot/location/@{encodeURIComponent(\'${teamsPostLocation}\')}'
                  }
                  runAfter: {
                    Insert_Entity: ['Succeeded']
                  }
                }
              }
              else: {
                actions: {
                  Update_Entity: {
                    type: 'Http'
                    inputs: {
                      method: 'PATCH'
                      uri: '${tableEndpoint}/${tableName}(PartitionKey=\'@{body(\'Parse_Event\')?[\'${partitionKeyField}\']}\',RowKey=\'active\')'
                      headers: {
                        'Content-Type': 'application/json'
                        Accept: 'application/json;odata=nometadata'
                        'x-ms-version': '2020-12-06'
                        'If-Match': '*'
                      }
                      body: updateEntityBody
                      authentication: {
                        type: 'ManagedServiceIdentity'
                        audience: 'https://storage.azure.com/'
                      }
                    }
                    runAfter: {}
                  }
                }
              }
              runAfter: {
                Get_Active_Session: ['Succeeded', 'Failed']
              }
            }
          }
          runAfter: {}
        }
      }
    }
    parameters: {
      '$connections': {
        value: {
          eventhubs: {
            connectionId: eventhubConnection.id
            connectionName: eventhubConnection.name
            id: eventhubManagedApiId
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
          }
          teams: {
            connectionId: teamsConnection.id
            connectionName: teamsConnection.name
            id: teamsManagedApiId
            connectionProperties: {}
          }
        }
      }
    }
  }
}

/*
  Modules
*/

module eventhubDataReceiverRoleAssignment 'modules/eventhub-role-assignment.bicep' = if (shouldAssignRoles) {
  name: '${deployment().name}-evhRole'
  params: {
    eventhubNamespaceName: eventhubNamespaceName
    principalId: teamsNotification.identity.principalId
  }
}

module notificationStorageTableRoleAssignment 'modules/storage-table-role-assignment.bicep' = if (shouldAssignRoles) {
  name: '${deployment().name}-notifyTableRole'
  params: {
    storageAccountName: storageAccountName
    principalId: teamsNotification.identity.principalId
  }
}

module closeSessionStorageTableRoleAssignment 'modules/storage-table-role-assignment.bicep' = if (shouldAssignRoles) {
  name: '${deployment().name}-closeTableRole'
  params: {
    storageAccountName: storageAccountName
    principalId: closeSession.identity.principalId
  }
}

/*
  Outputs
*/

@description('Notification Logic App workflow resource details.')
output logicApp types.LogicAppReference = {
  id: teamsNotification.id
  name: teamsNotification.name
  identityPrincipalId: teamsNotification.identity.principalId
}

@description('Close session Logic App workflow resource details.')
output closeLogicApp types.LogicAppReference = {
  id: closeSession.id
  name: closeSession.name
  identityPrincipalId: closeSession.identity.principalId
}

// DR-02: Bicep cannot mark this output sensitive at the field level; the callback URL is
// emitted in clear text. Treat downstream consumers as handling a secret value.
#disable-next-line outputs-should-not-contain-secrets
@description('HTTP endpoint URL for closing active event sessions.')
output closeSessionEndpoint string = closeSessionCallbackUrl

@description('Storage account used for event session state tracking via Table Storage.')
output storageAccount types.StorageAccountReference = {
  id: storageAccount.id
  name: storageAccount.name
}
