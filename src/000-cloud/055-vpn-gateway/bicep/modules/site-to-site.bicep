metadata name = 'Site-to-Site Module'
metadata description = 'Creates local network gateways and VPN connections for each configured site.'

import * as core from '../types.core.bicep'
import * as types from '../types.bicep'

/*
  Parameters
*/

@description('Common component configuration for naming conventions.')
param common core.Common

@description('Azure region for all created resources.')
param location string

@description('Resource tags applied to all site-to-site assets.')
param tags object

@description('VPN Gateway resource ID used for the site connections.')
param vpnGatewayId string

@description('Site-to-site VPN connection definitions.')
param vpnSiteConnections types.VpnSiteConnection[]

@description('Fallback IPsec policy applied when sites omit an override.')
param vpnSiteDefaultIpsecPolicy types.VpnIpsecPolicy?

@secure()
@description('Pre-shared keys keyed by sharedKeyReference values.')
param vpnSiteSharedKeys object

/*
  Variables
*/

var resourceNamePrefix = '${common.resourcePrefix}-${common.environment}-${common.instance}'
var processedSites = [
  for (site, idx) in vpnSiteConnections: {
    index: idx
    name: site.name
    uniqueSuffix: toLower(substring(
      uniqueString(common.resourcePrefix, site.name, common.environment, common.instance),
      0,
      6
    ))
    addressSpaces: site.addressSpaces
    sharedKeyReference: site.sharedKeyReference
    connectionMode: site.?connectionMode ?? types.vpnSiteConnectionDefaults.connectionMode
    dpdTimeoutSeconds: site.?dpdTimeoutSeconds
    gatewayFqdn: site.?gatewayFqdn
    gatewayIpAddress: site.?gatewayIpAddress
    ikeProtocol: site.?ikeProtocol ?? types.vpnSiteConnectionDefaults.ikeProtocol
    usePolicyBasedSelectors: site.?usePolicyBasedSelectors ?? types.vpnSiteConnectionDefaults.usePolicyBasedSelectors
    bgpSettings: site.?bgpSettings
    ipsecPolicy: site.?ipsecPolicy ?? vpnSiteDefaultIpsecPolicy
  }
]

/*
  Resources
*/

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2024-05-01' = [
  for site in processedSites: {
    name: 'lng-${site.uniqueSuffix}-${resourceNamePrefix}'
    location: location
    tags: tags
    properties: {
      gatewayIpAddress: site.?gatewayIpAddress
      fqdn: site.?gatewayFqdn
      localNetworkAddressSpace: {
        addressPrefixes: site.addressSpaces
      }
      bgpSettings: site.?bgpSettings != null
        ? {
            asn: site.bgpSettings!.asn
            bgpPeeringAddress: site.bgpSettings!.peerAddress
            peerWeight: (site.?bgpSettings).?peerWeight ?? 0
          }
        : null
    }
  }
]

resource vpnConnections 'Microsoft.Network/connections@2024-05-01' = [
  for (conn, i) in vpnSiteConnections: {
    name: 'conn-${processedSites[i].uniqueSuffix}-${resourceNamePrefix}'
    location: location
    tags: tags
    properties: {
      connectionType: 'IPsec'
      virtualNetworkGateway1: {
        id: vpnGatewayId
        properties: {}
      }
      localNetworkGateway2: {
        id: localNetworkGateway[i].id
        properties: {}
      }
      #disable-next-line use-secure-value-for-secure-inputs
      sharedKey: vpnSiteSharedKeys[conn.sharedKeyReference]
      connectionProtocol: processedSites[i].ikeProtocol
      connectionMode: processedSites[i].connectionMode
      dpdTimeoutSeconds: processedSites[i].?dpdTimeoutSeconds
      usePolicyBasedTrafficSelectors: processedSites[i].usePolicyBasedSelectors
      ipsecPolicies: processedSites[i].?ipsecPolicy == null
        ? []
        : [
            union(
              union(
                {
                  ikeEncryption: (processedSites[i].?ipsecPolicy)!.ikeEncryption
                  ikeIntegrity: (processedSites[i].?ipsecPolicy)!.ikeIntegrity
                  ipsecEncryption: (processedSites[i].?ipsecPolicy)!.ipsecEncryption
                  ipsecIntegrity: (processedSites[i].?ipsecPolicy)!.ipsecIntegrity
                  dhGroup: (processedSites[i].?ipsecPolicy)!.dhGroup
                  pfsGroup: (processedSites[i].?ipsecPolicy)!.pfsGroup
                },
                (processedSites[i].?ipsecPolicy).?saLifetimeSeconds == null
                  ? {}
                  : {
                      saLifeTimeSeconds: (processedSites[i].?ipsecPolicy).?saLifetimeSeconds
                    }
              ),
              (processedSites[i].?ipsecPolicy).?saDataSizeKb == null
                ? {}
                : {
                    saDataSizeKilobytes: (processedSites[i].?ipsecPolicy).?saDataSizeKb
                  }
            )
          ]
    }
  }
]

/*
  Outputs
*/

var localNetworkGatewayOutputs = [
  for (site, i) in processedSites: {
    key: site.name
    value: {
      id: localNetworkGateway[i].id
      name: localNetworkGateway[i].name
      resourceGroupName: resourceGroup().name
      addressSpaces: site.addressSpaces
    }
  }
]

var siteConnectionOutputs = [
  for (site, i) in processedSites: {
    key: site.name
    value: {
      id: vpnConnections[i].id
      name: vpnConnections[i].name
      localNetworkGatewayId: localNetworkGateway[i].id
      sharedKeyReference: site.sharedKeyReference
      usePolicyBasedSelectors: site.usePolicyBasedSelectors
    }
  }
]

@description('Local network gateway metadata keyed by VPN site name.')
output localNetworkGateways object = length(processedSites) == 0
  ? {}
  : toObject(localNetworkGatewayOutputs, item => item.key, item => item.value)

@description('Site-to-site VPN connection metadata keyed by VPN site name.')
output siteConnections object = length(processedSites) == 0
  ? {}
  : toObject(siteConnectionOutputs, item => item.key, item => item.value)
