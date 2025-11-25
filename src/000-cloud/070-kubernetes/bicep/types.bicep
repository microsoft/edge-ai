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
