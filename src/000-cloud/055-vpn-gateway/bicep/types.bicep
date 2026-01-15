@export()
@description('VPN Gateway configuration.')
type VpnGatewayConfig = {
  @description('SKU name for VPN Gateway. AZ variants provide zone redundancy.')
  sku:
    | 'VpnGw1'
    | 'VpnGw1AZ'
    | 'VpnGw2'
    | 'VpnGw2AZ'
    | 'VpnGw3'
    | 'VpnGw3AZ'
    | 'VpnGw4'
    | 'VpnGw4AZ'
    | 'VpnGw5'
    | 'VpnGw5AZ'

  @description('Generation of VPN Gateway.')
  generation: 'Generation1' | 'Generation2'

  @description('Client address pool for P2S VPN.')
  clientAddressPool: string[]

  @description('VPN protocols to enable.')
  vpnProtocols: string[]
}

@export()
var vpnGatewayConfigDefaults = {
  sku: 'VpnGw1'
  generation: 'Generation1'
  clientAddressPool: ['192.168.200.0/24']
  vpnProtocols: ['OpenVPN', 'IkeV2']
}

@export()
@description('Azure AD authentication configuration.')
type AzureAdConfig = {
  @description('Azure AD tenant ID.')
  tenantId: string?

  @description('Azure AD audience (application ID).')
  audience: string

  @description('Azure AD issuer URL.')
  issuer: string?
}

@export()
var azureAdConfigDefaults = {
  tenantId: null
  audience: '41b23e61-6c1e-4545-b367-cd054e0ed4b4'
  issuer: null
}

// Note: Certificate-based authentication types are not currently supported in Bicep.
// Azure Key Vault certificates cannot be created via native Bicep/ARM resources.
// Future versions may add certificate support if Azure introduces native Bicep support
// for Key Vault certificate creation.

@export()
@description('BGP settings for a VPN site connection.')
type VpnSiteBgpSettings = {
  @description('Autonomous system number advertised by the on-premises device.')
  asn: int

  @description('Peer address Azure uses for BGP sessions.')
  peerAddress: string

  @description('Optional weight applied to the BGP peer.')
  peerWeight: int?
}

@export()
@description('IPsec/IKE settings applied to VPN tunnels.')
type VpnIpsecPolicy = {
  @description('Diffie-Hellman group for the IKE phase.')
  dhGroup: string

  @description('IKE phase encryption algorithm.')
  ikeEncryption: string

  @description('IKE phase integrity algorithm.')
  ikeIntegrity: string

  @description('IPsec phase encryption algorithm.')
  ipsecEncryption: string

  @description('IPsec phase integrity algorithm.')
  ipsecIntegrity: string

  @description('Perfect forward secrecy group.')
  pfsGroup: string

  @description('Optional data size threshold in kilobytes for rekeying.')
  saDataSizeKb: int?

  @description('Optional lifetime in seconds before rekeying the SA.')
  saLifetimeSeconds: int?
}

@export()
@description('Site-to-site VPN connection definition.')
type VpnSiteConnection = {
  @description('Friendly name for the on-premises site.')
  name: string

  @description('Address spaces reachable through the site.')
  addressSpaces: string[]

  @description('Reference key used to look up the shared key input.')
  sharedKeyReference: string

  @description('Optional connection mode (defaults to Default).')
  connectionMode: 'Default' | 'ResponderOnly' | 'InitiatorOnly'?

  @description('Optional DPD timeout in seconds.')
  dpdTimeoutSeconds: int?

  @description('Optional fully qualified domain name for the on-premises gateway.')
  gatewayFqdn: string?

  @description('Optional public IP address for the on-premises gateway.')
  gatewayIpAddress: string?

  @description('IKE protocol version (defaults to IKEv2).')
  ikeProtocol: 'IKEv1' | 'IKEv2'?

  @description('Whether to use policy-based traffic selectors (defaults to false).')
  usePolicyBasedSelectors: bool?

  @description('Optional BGP configuration for the site.')
  bgpSettings: VpnSiteBgpSettings?

  @description('Optional IPsec policy override for the site.')
  ipsecPolicy: VpnIpsecPolicy?
}

@export()
var vpnSiteConnectionDefaults = {
  connectionMode: 'Default'
  ikeProtocol: 'IKEv2'
  usePolicyBasedSelectors: false
}

@export()
var vpnSiteDefaultIpsecPolicyDefaults = {
  dhGroup: 'DHGroup14'
  ikeEncryption: 'AES256'
  ikeIntegrity: 'SHA256'
  ipsecEncryption: 'AES256'
  ipsecIntegrity: 'SHA256'
  pfsGroup: 'PFS14'
  saDataSizeKb: null
  saLifetimeSeconds: null
}
