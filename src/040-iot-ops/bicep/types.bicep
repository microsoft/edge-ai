@export()
@description('The common settings for Azure Arc Extensions.')
type Release = {
  @description('The version of the extension.')
  version: string

  @description('The release train that has the version to deploy (ex., "preview", "stable").')
  train: string
}

@export()
@description('The settings for the Secret Store Extension.')
type SecretStoreExtension = {
  @description('The common settings for the extension.')
  release: Release
}

@export()
var secretStoreExtensionDefaults = {
  release: {
    version: '0.6.7'
    train: 'preview'
  }
}

@export()
@description('The settings for the Open Service Mesh Extension.')
type OpenServiceMeshExtension = {
  @description('The common settings for the extension.')
  release: Release
}

@export()
var openServiceMeshExtensionDefaults = {
  release: {
    version: '1.2.10'
    train: 'stable'
  }
}

@export()
@description('The settings for the Azure Container Store for Azure Arc Extension.')
type ContainerStorageExtension = {
  @description('The common settings for the extension.')
  release: Release

  settings: {
    @description('Whether or not to enable fault tolerant storage in the cluster.')
    faultToleranceEnabled: bool

    @description('The storage class for the cluster. (Otherwise, "acstor-arccontainerstorage-storage-pool" for fault tolerant storage else "default,local-path")')
    diskStorageClass: string?
  }
}

@export()
var containerStorageExtensionDefaults = {
  release: {
    version: '2.2.2'
    train: 'stable'
  }
  settings: {
    faultToleranceEnabled: false
  }
}

@export()
@description('The settings for the Azure IoT Operations Platform Extension.')
type AioPlatformExtension = {
  @description('The common settings for the extension.')
  release: Release

  settings: {
    @description('Whether or not to install managers for trust in the cluster.')
    installCertManager: bool?
  }
}

@export()
var aioPlatformExtensionDefaults = {
  release: {
    version: '0.7.6'
    train: 'preview'
  }
  settings: {
    installCertManager: true
  }
}

@export()
@description('The settings for the Azure IoT Operations Extension.')
type AioExtension = {
  @description('The common settings for the extension.')
  release: Release

  settings: {
    @description('The namespace in the cluster where Azure IoT Operations will be installed.')
    namespace: string

    @description('The distro for Kubernetes for the cluster.')
    kubernetesDistro: 'K3s' | 'K8s' | 'MicroK8s'

    @description('The length of time in minutes before an operation for an agent timesout.')
    agentOperationTimeoutInMinutes: int
  }
}

@export()
var aioExtensionDefaults = {
  release: {
    version: '1.0.9'
    train: 'stable'
  }
  settings: {
    namespace: 'azure-iot-operations'
    kubernetesDistro: 'K3s'
    agentOperationTimeoutInMinutes: 120
  }
}

@export()
@description('The settings for the Azure IoT Operations MQ Broker.')
type AioMqBroker = {
  brokerListenerServiceName: string
  brokerListenerPort: int
  serviceAccountAudience: string
  frontendReplicas: int
  frontendWorkers: int
  backendRedundancyFactor: int
  backendWorkers: int
  backendPartitions: int
  memoryProfile: string
  serviceType: string
}

@export()
var aioMqBrokerDefaults = {
  brokerListenerServiceName: 'aio-broker'
  brokerListenerPort: 18883
  serviceAccountAudience: 'aio-internal'
  frontendReplicas: 1
  frontendWorkers: 1
  backendRedundancyFactor: 2
  backendWorkers: 1
  backendPartitions: 1
  memoryProfile: 'Low'
  serviceType: 'ClusterIp'
}

@export()
@description('The settings for Azure IoT Operations Data Flow Instances.')
type AioDataFlowInstance = {
  @description('The number of data flow instances.')
  count: int
}

@export()
var aioDataFlowInstanceDefaults = {
  count: 1
}

@export()
type TrustSource = 'SelfSigned' | 'CustomerManaged'
