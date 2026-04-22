metadata name = 'Leak Close Logic App'
metadata description = 'HTTP-triggered workflow that closes an active leak session and notifies Teams.'

import * as core from '../types.core.bicep'

@description('Common settings.')
param common core.Common

@description('Additional tags applied to the workflow.')
param tags object = {}

@description('Resource group location where the Logic App is deployed.')
param location string

@description('Teams connection resource ID.')
param teamsConnectionId string

@description('Teams connection resource name.')
param teamsConnectionName string

@description('Teams managed API resource ID.')
param teamsManagedApiId string

@description('Storage account name hosting the leakSessions table.')
param storageAccountName string

@description('Name of the table used for leak-session state tracking.')
param tableName string = 'leaksessions'

@description('Teams chat or channel thread ID for posting closure summaries.')
param teamsRecipientId string

@description('Teams posting location type.')
param teamsPostLocation string = 'Group chat'

var workflowName = 'la-${common.resourcePrefix}-leak-close-${common.environment}-${common.instance}'
var tableEndpoint = 'https://${storageAccountName}.table.${environment().suffixes.storage}'

var defaultTags = {
  Environment: common.environment
  Instance: common.instance
}

resource workflow 'Microsoft.Logic/workflows@2019-05-01' = {
  name: workflowName
  location: location
  tags: union(defaultTags, tags)
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
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
        Close_Leak_Request: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            method: 'GET'
            schema: {}
          }
        }
      }
      actions: {
        Get_Leak_Session: {
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
            Get_Leak_Session: [ 'Succeeded' ]
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
              recipient: teamsRecipientId
              messageBody: '<p><strong>✅ Leak Resolved</strong></p><p><strong>Device:</strong> @{triggerOutputs()[\'queries\'][\'device\']}</p><p><strong>Active From:</strong> @{body(\'Get_Leak_Session\')?[\'FirstDetectedAt\']}</p><p><strong>Active Until:</strong> @{body(\'Get_Leak_Session\')?[\'LastEventAt\']}</p><p><strong>Total Events:</strong> @{body(\'Get_Leak_Session\')?[\'EventCount\']}</p>'
            }
            path: '/beta/teams/conversation/message/poster/Flow bot/location/@{encodeURIComponent(\'${teamsPostLocation}\')}'
          }
          runAfter: {
            Delete_Entity: [ 'Succeeded' ]
          }
        }
        Response: {
          type: 'Response'
          kind: 'Http'
          inputs: {
            statusCode: '@{if(equals(actions(\'Delete_Entity\')[\'status\'], \'Succeeded\'), 200, if(equals(actions(\'Get_Leak_Session\')[\'status\'], \'Failed\'), 404, 500))}'
            headers: {
              'Content-Type': 'text/plain'
            }
            body: '@{if(equals(actions(\'Delete_Entity\')[\'status\'], \'Succeeded\'), \'Leak closed\', if(equals(actions(\'Get_Leak_Session\')[\'status\'], \'Failed\'), \'No active leak found for this device\', \'Failed to close leak\'))}'
          }
          runAfter: {
            Post_Closure_Summary: [ 'Succeeded', 'Failed', 'Skipped', 'TimedOut' ]
          }
        }
      }
    }
    parameters: {
      '$connections': {
        value: {
          teams: {
            connectionId: teamsConnectionId
            connectionName: teamsConnectionName
            id: teamsManagedApiId
            connectionProperties: {}
          }
        }
      }
    }
  }
}

@description('Logic App workflow resource ID.')
output logicAppId string = workflow.id

@description('Logic App workflow name.')
output logicAppName string = workflow.name

@description('System-assigned managed identity principal ID.')
output identityPrincipalId string = workflow.identity!.principalId

@description('Callback URL for the HTTP trigger — passed into the notify workflow so the Teams message can include a close link.')
// Intentional: the callback URL must be emitted so the notify workflow (and any
// operator UI) can embed a close link. Consumers should treat the URL as sensitive.
#disable-next-line outputs-should-not-contain-secrets
output callbackUrl string = listCallbackUrl('${workflow.id}/triggers/Close_Leak_Request', workflow.apiVersion).value
