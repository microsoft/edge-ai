metadata name = 'Network Security Perimeter Module'
metadata description = 'Creates a Network Security Perimeter profile with inbound access for deployment clients and resources in the current subscription.'

import * as core from '../types.core.bicep'

@description('The common component configuration.')
param common core.Common

@description('IPv4 or IPv6 CIDR prefixes allowed to access resources associated with the perimeter.')
param allowedIpAddressPrefixes string[]

var networkSecurityPerimeterName = 'nsp-${common.resourcePrefix}-${common.environment}-${common.instance}'
var profileName = 'defaultprofile'
var validatedAllowedIpAddressPrefixes = [
  for prefix in allowedIpAddressPrefixes: contains(prefix, '/') && !empty(cidrHost(prefix, 0))
    ? prefix
    : fail('Each Network Security Perimeter address prefix must be a valid IPv4 or IPv6 CIDR.')
]

resource networkSecurityPerimeter 'Microsoft.Network/networkSecurityPerimeters@2025-01-01' = {
  name: networkSecurityPerimeterName
  location: common.location
}

resource profile 'Microsoft.Network/networkSecurityPerimeters/profiles@2025-01-01' = {
  parent: networkSecurityPerimeter
  name: profileName
}

resource deploymentClientAccessRule 'Microsoft.Network/networkSecurityPerimeters/profiles/accessRules@2025-01-01' = if (!empty(allowedIpAddressPrefixes)) {
  parent: profile
  name: 'allow-deployment-clients'
  properties: {
    direction: 'Inbound'
    addressPrefixes: validatedAllowedIpAddressPrefixes
  }
}

resource subscriptionAccessRule 'Microsoft.Network/networkSecurityPerimeters/profiles/accessRules@2025-01-01' = {
  parent: profile
  name: 'allow-current-subscription'
  properties: {
    direction: 'Inbound'
    subscriptions: [
      {
        id: subscription().id
      }
    ]
  }
}

@description('The resource ID of the Network Security Perimeter.')
output networkSecurityPerimeterId string = networkSecurityPerimeter.id

@description('The resource group containing the Network Security Perimeter.')
output networkSecurityPerimeterResourceGroupName string = resourceGroup().name

@description('The resource ID of the Network Security Perimeter profile.')
output profileId string = profile.id
