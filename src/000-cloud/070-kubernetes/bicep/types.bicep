metadata name = 'AKS Component Types'
metadata description = 'Type definitions and defaults for the AKS component.'

/*
  Kubernetes Cluster Configuration
*/

@export()
@description('The settings for the Azure Kubernetes Service cluster.')
type KubernetesCluster = {
  @description('Number of nodes for the agent pool in the AKS cluster.')
  nodeCount: int

  @description('VM size for the agent pool in the AKS cluster.')
  nodeVmSize: string

  @description('DNS prefix for the AKS cluster. If not provided, a default value will be generated.')
  dnsPrefix: string?
}

@export()
var kubernetesClusterDefaults = {
  nodeCount: 1
  nodeVmSize: 'Standard_D8ds_v5'
  dnsPrefix: ''
}

/*
  AKS Network Configuration
*/

@export()
@description('Network configuration for AKS subnets.')
type AksNetworkConfig = {
  @description('Address prefix for the AKS system node subnet.')
  subnetAddressPrefixAks: string

  @description('Address prefix for the AKS pod subnet.')
  subnetAddressPrefixAksPod: string

  @description('Whether to enable default outbound internet access for AKS subnets.')
  defaultOutboundAccessEnabled: bool

  @description('Whether to associate AKS subnets with a NAT gateway for managed outbound egress.')
  shouldEnableNatGateway: bool
}

@export()
var aksNetworkConfigDefaults = {
  subnetAddressPrefixAks: '10.0.5.0/24'
  subnetAddressPrefixAksPod: '10.0.6.0/24'
  defaultOutboundAccessEnabled: false
  shouldEnableNatGateway: false
}

/*
  Private Cluster Configuration
*/

@export()
@description('Private cluster configuration for AKS.')
type AksPrivateClusterConfig = {
  @description('Whether to enable private cluster mode for AKS.')
  shouldEnablePrivateCluster: bool

  @description('Whether to enable public FQDN for private cluster.')
  shouldEnablePrivateClusterPublicFqdn: bool

  @description('Whether to create a private endpoint for the AKS cluster.')
  shouldEnablePrivateEndpoint: bool
}

@export()
var aksPrivateClusterConfigDefaults = {
  shouldEnablePrivateCluster: false
  shouldEnablePrivateClusterPublicFqdn: false
  shouldEnablePrivateEndpoint: false
}
