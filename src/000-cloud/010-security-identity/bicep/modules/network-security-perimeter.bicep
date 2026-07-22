metadata name = 'Network Security Perimeter Module'
metadata description = 'Creates a Network Security Perimeter profile with inbound access for deployment clients and resources in the current subscription.'

import * as core from '../types.core.bicep'

@description('The common component configuration.')
param common core.Common

// Parity note: unlike the Terraform implementation, this Bicep module does NOT auto-detect the
// deployment client's public IP. Inbound access is limited to the current subscription rule below
// plus whatever CIDRs the caller passes here. An operator running data-plane operations from a
// workstation must supply their public CIDR via allowedIpAddressPrefixes, otherwise they will be
// blocked once the perimeter is Enforced.
@description('IPv4 or IPv6 CIDR prefixes allowed to access resources associated with the perimeter. Supply the deployment client public CIDR here when running data-plane operations from a workstation; this module does not auto-detect it (unlike the Terraform path).')
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
