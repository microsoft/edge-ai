import * as core from '../types.core.bicep'
import * as types from '../types.bicep'

@description('The common component configuration.')
param common core.Common

@description('Name of the existing arc-enabled cluster where AIO will be deployed.')
param arcConnectedClusterName string

@description('The settings for the Azure IoT Operations Extension.')
param aioExtensionConfig types.AioExtension

@description('The resource ID for the Secret Store Extension.')
#disable-next-line secure-secrets-in-params
param secretStoreExtensionId string

@description('The resource ID for the Azure IoT Operations Platform Extension.')
param aioPlatformExtensionId string

@description('Whether or not to deploy the Custom Locations Resource Sync Rules for the Azure IoT Operations resources.')
param shouldDeployResourceSyncRules bool

@description('The settings for the Azure IoT Operations MQ Broker.')
param aioMqBrokerConfig types.AioMqBroker

@description('The settings for Azure IoT Operations Data Flow Instances.')
param aioDataFlowInstanceConfig types.AioDataFlowInstance

@description('The name for the Custom Locations resource.')
param customLocationName string

@description('The name for the Azure IoT Operations Instance resource.')
param aioInstanceName string

@description('The resource ID for the User Assigned Identity for Azure IoT Operations.')
param aioUserAssignedIdentityId string?

@description('The resource ID for the ADR Schema Registry for Azure IoT Operations.')
param schemaRegistryId string

@description('Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.')
param shouldEnableOtelCollector bool

@description('The source for trust for Azure IoT Operations.')
param trustSource types.TrustSource

var metrics = {
  enabled: shouldEnableOtelCollector
  otelCollectorAddress: shouldEnableOtelCollector
    ? 'aio-otel-collector.${aioExtensionConfig.settings.namespace}.svc.cluster.local:4317'
    : ''
  exportIntervalSeconds: 60
}

// For now, only support self signed cert and trust until customer managed has been implemented
var selfSignedIssuerName = '${aioExtensionConfig.settings.namespace}-aio-certificate-issuer'
var selfSignedConfigMapName = '${aioExtensionConfig.settings.namespace}-aio-ca-trust-bundle'
var trust = {
  issuerName: selfSignedIssuerName
  issuerKind: 'ClusterIssuer'
  configMapName: selfSignedConfigMapName
  configMapKey: ''
}

var aioMqBrokerAddress = 'mqtts://${aioMqBrokerConfig.brokerListenerServiceName}.${aioExtensionConfig.settings.namespace}:${aioMqBrokerConfig.brokerListenerPort}'

resource arcConnectedCluster 'Microsoft.Kubernetes/connectedClusters@2021-03-01' existing = {
  name: arcConnectedClusterName
}

resource aioExtension 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
  scope: arcConnectedCluster
  name: 'azure-iot-operations-${take(uniqueString(arcConnectedCluster.id), 5)}'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    extensionType: 'microsoft.iotoperations'
    version: aioExtensionConfig.release.version
    releaseTrain: aioExtensionConfig.release.train
    autoUpgradeMinorVersion: false
    scope: {
      cluster: {
        releaseNamespace: aioExtensionConfig.settings.namespace
      }
    }
    configurationSettings: {
      #disable-next-line prefer-unquoted-property-names
      'AgentOperationTimeoutInMinutes': any(aioExtensionConfig.settings.agentOperationTimeoutInMinutes)
      'connectors.values.mqttBroker.address': aioMqBrokerAddress
      'connectors.values.mqttBroker.serviceAccountTokenAudience': aioMqBrokerConfig.serviceAccountAudience
      'connectors.values.opcPlcSimulation.deploy': 'false'
      'connectors.values.opcPlcSimulation.autoAcceptUntrustedCertificates': 'false'
      'connectors.values.discoveryHandler.enabled': 'false'
      'adr.values.Microsoft.CustomLocation.ServiceAccount': 'default'
      'akri.values.webhookConfiguration.enabled': 'false'
      'akri.values.certManagerWebhookCertificate.enabled': 'false'
      'akri.values.agent.extensionService.mqttBroker.hostName': '${aioMqBrokerConfig.brokerListenerServiceName}.${aioExtensionConfig.settings.namespace}'
      'akri.values.agent.extensionService.mqttBroker.port': any(aioMqBrokerConfig.brokerListenerPort)
      'akri.values.agent.extensionService.mqttBroker.serviceAccountAudience': aioMqBrokerConfig.serviceAccountAudience
      'akri.values.agent.host.containerRuntimeSocket': ''
      'akri.values.kubernetesDistro': toLower(aioExtensionConfig.settings.kubernetesDistro)
      'mqttBroker.values.global.quickstart': 'false'
      'mqttBroker.values.operator.firstPartyMetricsOn': 'true'
      'observability.metrics.enabled': '${metrics.enabled}'
      'observability.metrics.openTelemetryCollectorAddress': metrics.otelCollectorAddress
      'observability.metrics.exportIntervalSeconds': '${metrics.exportIntervalSeconds}'
      #disable-next-line prefer-unquoted-property-names
      'trustSource': trustSource
      'trustBundleSettings.issuer.name': trust.issuerName
      'trustBundleSettings.issuer.kind': trust.issuerKind
      'trustBundleSettings.configMap.name': trust.configMapName
      'trustBundleSettings.configMap.key': trust.configMapKey
      'schemaRegistry.values.mqttBroker.host': aioMqBrokerAddress
      'schemaRegistry.values.mqttBroker.tlsEnabled': any(true)
      'schemaRegistry.values.mqttBroker.serviceAccountTokenAudience': aioMqBrokerConfig.serviceAccountAudience
    }
  }
}

resource customLocation 'Microsoft.ExtendedLocation/customLocations@2021-08-31-preview' = {
  name: customLocationName
  location: common.location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hostResourceId: arcConnectedCluster.id
    namespace: aioExtensionConfig.settings.namespace
    displayName: customLocationName
    clusterExtensionIds: [aioPlatformExtensionId, secretStoreExtensionId, aioExtension.id]
  }
}

resource aioSyncRule 'Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview' = if (shouldDeployResourceSyncRules) {
  parent: customLocation
  name: '${customLocationName}-broker-sync'
  location: common.location
  properties: {
    priority: 400
    selector: {
      matchLabels: {
        #disable-next-line no-hardcoded-env-urls
        'management.azure.com/provider-name': 'microsoft.iotoperations'
      }
    }
    targetResourceGroup: resourceGroup().id
  }
}

resource adrSyncRule 'Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview' = if (shouldDeployResourceSyncRules) {
  parent: customLocation
  name: '${customLocationName}-adr-sync'
  location: common.location
  properties: {
    priority: 200
    selector: {
      matchLabels: {
        #disable-next-line no-hardcoded-env-urls
        'management.azure.com/provider-name': 'Microsoft.DeviceRegistry'
      }
    }
    targetResourceGroup: resourceGroup().id
  }
  dependsOn: [
    aioSyncRule
  ]
}

resource aioInstance 'Microsoft.IoTOperations/instances@2024-11-01' = {
  name: aioInstanceName
  location: common.location
  extendedLocation: {
    name: customLocation.id
    type: 'CustomLocation'
  }
  identity: empty(aioUserAssignedIdentityId)
    ? {
        type: 'None'
      }
    : {
        type: 'UserAssigned'
        userAssignedIdentities: {
          '${aioUserAssignedIdentityId}': {}
        }
      }
  properties: {
    schemaRegistryRef: {
      resourceId: schemaRegistryId
    }
  }
}

resource broker 'Microsoft.IoTOperations/instances/brokers@2024-11-01' = {
  parent: aioInstance
  name: 'default'
  extendedLocation: {
    name: customLocation.id
    type: 'CustomLocation'
  }
  properties: {
    memoryProfile: aioMqBrokerConfig.memoryProfile
    generateResourceLimits: {
      cpu: 'Disabled'
    }
    cardinality: {
      backendChain: {
        partitions: aioMqBrokerConfig.backendPartitions
        workers: aioMqBrokerConfig.backendWorkers
        redundancyFactor: aioMqBrokerConfig.backendRedundancyFactor
      }
      frontend: {
        replicas: aioMqBrokerConfig.frontendReplicas
        workers: aioMqBrokerConfig.frontendWorkers
      }
    }
  }
}

resource brokerAuthn 'Microsoft.IoTOperations/instances/brokers/authentications@2024-11-01' = {
  parent: broker
  name: 'default'
  extendedLocation: {
    name: customLocation.id
    type: 'CustomLocation'
  }
  properties: {
    authenticationMethods: [
      {
        method: 'ServiceAccountToken'
        serviceAccountTokenSettings: {
          audiences: [aioMqBrokerConfig.serviceAccountAudience]
        }
      }
    ]
  }
}

resource brokerListener 'Microsoft.IoTOperations/instances/brokers/listeners@2024-11-01' = {
  parent: broker
  name: 'default'
  extendedLocation: {
    name: customLocation.id
    type: 'CustomLocation'
  }
  properties: {
    serviceType: aioMqBrokerConfig.serviceType
    serviceName: aioMqBrokerConfig.brokerListenerServiceName
    ports: [
      {
        authenticationRef: brokerAuthn.name
        port: aioMqBrokerConfig.brokerListenerPort
        tls: {
          mode: 'Automatic'
          certManagerCertificateSpec: {
            issuerRef: {
              name: trust.issuerName
              kind: trust.issuerKind
              group: 'cert-manager.io'
            }
          }
        }
      }
    ]
  }
}

resource dataFlowProfile 'Microsoft.IoTOperations/instances/dataflowProfiles@2024-11-01' = {
  parent: aioInstance
  name: 'default'
  extendedLocation: {
    name: customLocation.id
    type: 'CustomLocation'
  }
  properties: {
    instanceCount: aioDataFlowInstanceConfig.count
  }
}

resource dataFlowEndpoint 'Microsoft.IoTOperations/instances/dataflowEndpoints@2024-11-01' = {
  parent: aioInstance
  name: 'default'
  extendedLocation: {
    name: customLocation.id
    type: 'CustomLocation'
  }
  properties: {
    endpointType: 'Mqtt'
    mqttSettings: {
      host: '${aioMqBrokerConfig.brokerListenerServiceName}:${aioMqBrokerConfig.brokerListenerPort}'
      authentication: {
        method: 'ServiceAccountToken'
        serviceAccountTokenSettings: {
          audience: aioMqBrokerConfig.serviceAccountAudience
        }
      }
      tls: {
        mode: 'Enabled'
        trustedCaCertificateConfigMapRef: trust.configMapName
      }
    }
  }
}

output aioInstanceName string = aioInstance.name
output aioInstanceId string = aioInstance.id

output customLocationName string = customLocation.name
output customLocationId string = customLocation.id

output dataFlowProfileName string = dataFlowProfile.name
output dataFlowProfileId string = dataFlowProfile.id

output dataFlowEndpointName string = dataFlowEndpoint.name
output dataFlowEndPointId string = dataFlowEndpoint.id
