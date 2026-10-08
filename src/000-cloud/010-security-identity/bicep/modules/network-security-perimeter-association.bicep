metadata name = 'Network Security Perimeter Association Module'
metadata description = 'Associates a supported private-link resource with a Network Security Perimeter profile in Enforced mode.'

@description('Name of the Network Security Perimeter.')
param networkSecurityPerimeterName string

@description('Name of the Network Security Perimeter profile.')
param networkSecurityPerimeterProfileName string

@description('Name of the Network Security Perimeter resource association.')
param associationName string

@description('Resource ID of the private-link resource associated with the perimeter.')
param privateLinkResourceId string

resource networkSecurityPerimeter 'Microsoft.Network/networkSecurityPerimeters@2025-01-01' existing = {
  name: networkSecurityPerimeterName
}

resource profile 'Microsoft.Network/networkSecurityPerimeters/profiles@2025-01-01' existing = {
  parent: networkSecurityPerimeter
  name: networkSecurityPerimeterProfileName
}

resource association 'Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2025-01-01' = {
  parent: networkSecurityPerimeter
  name: associationName
  properties: {
    accessMode: 'Enforced'
    privateLinkResource: {
      id: privateLinkResourceId
    }
    profile: {
      id: profile.id
    }
  }
}

@description('The resource ID of the Network Security Perimeter association.')
output associationId string = association.id
