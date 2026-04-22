metadata name = 'Leak Notification Logic App'
metadata description = 'Subscribes to ALERT_DLQC events on Event Hub, deduplicates via Azure Table Storage, posts new-leak alerts to Teams.'

import * as core from '../types.core.bicep'

@description('Common settings.')
param common core.Common

@description('Additional tags applied to the workflow.')
param tags object = {}

@description('Resource group location where the Logic App is deployed.')
param location string

@description('Event Hub name to subscribe to for leak events.')
param eventhubName string

@description('Event Hub connection resource ID (from eventhub-connection module).')
param eventhubConnectionId string

@description('Event Hub connection resource name (from eventhub-connection module).')
param eventhubConnectionName string

@description('Event Hub managed API resource ID.')
param eventhubManagedApiId string

@description('Teams connection resource ID (from teams-connection module).')
param teamsConnectionId string

@description('Teams connection resource name (from teams-connection module).')
param teamsConnectionName string

@description('Teams managed API resource ID.')
param teamsManagedApiId string

@description('Storage account name hosting the leakSessions table.')
param storageAccountName string

@description('Name of the table used for leak-session state tracking.')
param tableName string = 'leaksessions'

@description('Teams chat or channel thread ID for posting notifications.')
param teamsRecipientId string

@description('Teams posting location type for the message.')
param teamsPostLocation string = 'Group chat'

@description('Callback URL for the close-leak HTTP trigger, embedded in the Teams message.')
param closeLeakCallbackUrl string

var workflowName = 'la-${common.resourcePrefix}-leak-notify-${common.environment}-${common.instance}'
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
              consumerGroupName: '$Default'
              maximumEventsCount: 50
            }
          }
          recurrence: {
            frequency: 'Second'
            interval: 5
          }
        }
      }
      actions: {
        For_Each_Event: {
          type: 'Foreach'
          foreach: '@triggerBody()'
          operationOptions: 'Sequential'
          actions: {
            Parse_Leak_Event: {
              type: 'ParseJson'
              inputs: {
                content: '@base64ToString(items(\'For_Each_Event\')?[\'ContentData\'])'
                schema: {
                  type: 'object'
                  properties: {
                    message_type: { type: 'string' }
                    timestamp: { type: 'number' }
                    source_device: { type: 'string' }
                    inference_result: {
                      type: 'object'
                      properties: {
                        model_name: { type: 'string' }
                        model_type: { type: 'string' }
                        confidence: { type: 'number' }
                        inference_time_ms: { type: 'number' }
                        metadata: {
                          type: 'object'
                          properties: {
                            backend: { type: 'string' }
                            inference_type: { type: 'string' }
                            model_path: { type: 'string' }
                            request_id: { type: 'string' }
                          }
                        }
                        predictions: {
                          type: 'array'
                          items: {
                            type: 'object'
                            properties: {
                              class: { type: 'string' }
                              confidence: { type: 'number' }
                              bbox: {}
                              severity: { type: 'string' }
                              metadata: {
                                type: 'object'
                                properties: {
                                  backend: { type: 'string' }
                                  class_index: { type: 'integer' }
                                  inference_type: { type: 'string' }
                                  model_name: { type: 'string' }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                    enrichment: {
                      type: 'object'
                      properties: {
                        site: { type: 'string' }
                        facility: { type: 'string' }
                        business_unit: { type: 'string' }
                        alert_level: { type: 'string' }
                        region: { type: 'string' }
                        recommended_actions: {
                          type: 'array'
                          items: { type: 'string' }
                        }
                      }
                    }
                  }
                }
              }
              runAfter: {}
            }
            Get_Active_Leak: {
              type: 'Http'
              inputs: {
                method: 'GET'
                uri: '${tableEndpoint}/${tableName}(PartitionKey=\'@{body(\'Parse_Leak_Event\')?[\'source_device\']}\',RowKey=\'active\')'
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
                Parse_Leak_Event: [ 'Succeeded' ]
              }
            }
            Check_New_Leak: {
              type: 'If'
              expression: {
                and: [
                  {
                    equals: [
                      '@outputs(\'Get_Active_Leak\')[\'statusCode\']'
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
                    body: {
                      PartitionKey: '@{body(\'Parse_Leak_Event\')?[\'source_device\']}'
                      RowKey: 'active'
                      FirstDetectedAt: '@{utcNow()}'
                      LastEventAt: '@{utcNow()}'
                      EventCount: 1
                      Confidence: '@{body(\'Parse_Leak_Event\')?[\'inference_result\']?[\'confidence\']}'
                      AlertLevel: '@{coalesce(body(\'Parse_Leak_Event\')?[\'enrichment\']?[\'alert_level\'], \'Unknown\')}'
                    }
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
                      recipient: teamsRecipientId
                      messageBody: '<p><strong>🚨 Leak Detection Alert</strong></p><p><strong>Device:</strong> @{body(\'Parse_Leak_Event\')?[\'source_device\']}</p><p><strong>Detected At:</strong> @{utcNow()}</p><p><strong>Confidence:</strong> @{body(\'Parse_Leak_Event\')?[\'inference_result\']?[\'confidence\']}</p><p><strong>Model:</strong> @{body(\'Parse_Leak_Event\')?[\'inference_result\']?[\'model_name\']}</p><p><strong>Alert Level:</strong> @{coalesce(body(\'Parse_Leak_Event\')?[\'enrichment\']?[\'alert_level\'], \'Unknown\')}</p><p><strong>Site:</strong> @{coalesce(body(\'Parse_Leak_Event\')?[\'enrichment\']?[\'site\'], \'Unknown\')} / @{coalesce(body(\'Parse_Leak_Event\')?[\'enrichment\']?[\'facility\'], \'Unknown\')}</p><p><a href="${closeLeakCallbackUrl}&device=@{encodeUriComponent(body(\'Parse_Leak_Event\')?[\'source_device\'])}">✅ Close Leak</a></p>'
                    }
                    path: '/beta/teams/conversation/message/poster/Flow bot/location/@{encodeURIComponent(\'${teamsPostLocation}\')}'
                  }
                  runAfter: {
                    Insert_Entity: [ 'Succeeded' ]
                  }
                }
              }
              else: {
                actions: {
                  Update_Entity: {
                    type: 'Http'
                    inputs: {
                      method: 'PATCH'
                      uri: '${tableEndpoint}/${tableName}(PartitionKey=\'@{body(\'Parse_Leak_Event\')?[\'source_device\']}\',RowKey=\'active\')'
                      headers: {
                        'Content-Type': 'application/json'
                        Accept: 'application/json;odata=nometadata'
                        'x-ms-version': '2020-12-06'
                        'If-Match': '*'
                      }
                      body: {
                        LastEventAt: '@{utcNow()}'
                        EventCount: '@{add(int(body(\'Get_Active_Leak\')?[\'EventCount\']), 1)}'
                        Confidence: '@{if(greater(float(body(\'Parse_Leak_Event\')?[\'inference_result\']?[\'confidence\']), float(body(\'Get_Active_Leak\')?[\'Confidence\'])), body(\'Parse_Leak_Event\')?[\'inference_result\']?[\'confidence\'], body(\'Get_Active_Leak\')?[\'Confidence\'])}'
                      }
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
                Get_Active_Leak: [ 'Succeeded', 'Failed' ]
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
            connectionId: eventhubConnectionId
            connectionName: eventhubConnectionName
            id: eventhubManagedApiId
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
          }
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

@description('System-assigned managed identity principal ID — used for role assignments.')
output identityPrincipalId string = workflow.identity!.principalId
