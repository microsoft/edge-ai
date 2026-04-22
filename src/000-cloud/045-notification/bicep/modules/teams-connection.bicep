metadata name = 'Teams API Connection'
metadata description = 'API connection used by Logic Apps to post to Microsoft Teams. Requires user consent after deployment via Azure Portal.'

import * as core from '../types.core.bicep'

@description('Common settings.')
param common core.Common

@description('Additional tags applied to the connection.')
param tags object = {}

@description('Resource group location where the connection is deployed.')
param location string

var connectionName = 'apicon-teams-${common.resourcePrefix}-${common.environment}-${common.instance}'

var teamsManagedApiId = subscriptionResourceId(
  'Microsoft.Web/locations/managedApis',
  location,
  'teams'
)

resource teamsConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: connectionName
  location: location
  tags: tags
  properties: {
    api: {
      id: teamsManagedApiId
    }
    displayName: 'Teams'
  }
}

@description('Connection resource ID, passed into Logic App parameters.')
output connectionId string = teamsConnection.id

@description('Connection resource name.')
output connectionName string = teamsConnection.name

@description('Managed API ID for the teams connector, passed into Logic App parameters.')
output managedApiId string = teamsManagedApiId
