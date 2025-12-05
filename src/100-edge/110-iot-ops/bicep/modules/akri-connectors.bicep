metadata name = 'Akri Connectors Module'
metadata description = 'Deploys multiple Azure IoT Operations Akri Connector Templates as part of the IoT Operations deployment. Supports REST/HTTP, Media, ONVIF, and SSE connector types with configurable runtime and MQTT settings.'

import * as types from '../types.bicep'

/*
  Parameters
*/

@description('Azure IoT Operations instance ID where connector templates will be deployed.')
param aioInstanceId string

@description('Custom location ID for the Azure IoT Operations deployment.')
param customLocationId string

@description('List of Akri connector templates to deploy.')
param connectorTemplates types.AkriConnectorTemplate[]

@description('Shared MQTT connection configuration for all connectors.')
param mqttSharedConfig types.AkriMqttConfig

/*
  Variables
*/

var connectorTypeMetadata = {
  rest: {
    endpointType: 'Microsoft.Http'
    imageName: 'azureiotoperations/akri-connectors/rest'
    version: '1.0'
    defaultTag: '1.0.6'
    defaultRegistry: 'mcr.microsoft.com'
    defaultMinVersion: '1.2.37'
  }
  media: {
    endpointType: 'Microsoft.Media'
    imageName: 'azureiotoperations/akri-connectors/media'
    version: '1.0'
    defaultTag: '1.2.39'
    defaultRegistry: 'mcr.microsoft.com'
    defaultMinVersion: '1.2.37'
  }
  onvif: {
    endpointType: 'Microsoft.Onvif'
    imageName: 'azureiotoperations/akri-connectors/onvif'
    version: '1.0'
    defaultTag: '1.2.39'
    defaultRegistry: 'mcr.microsoft.com'
    defaultMinVersion: '1.2.37'
  }
  sse: {
    endpointType: 'Microsoft.Sse'
    imageName: 'azureiotoperations/akri-connectors/sse'
    version: '1.0'
    defaultTag: '1.0.5'
    defaultRegistry: 'mcr.microsoft.com'
    defaultMinVersion: '1.2.37'
  }
}

var processedConnectors = [
  for conn in connectorTemplates: {
    name: conn.name
    type: conn.type
    isCustom: conn.type == 'custom'

    endpointType: conn.type == 'custom' ? conn.customEndpointType! : connectorTypeMetadata[conn.type].endpointType
    endpointVersion: conn.type == 'custom'
      ? (conn.?customEndpointVersion ?? '1.0')
      : connectorTypeMetadata[conn.type].version
    imageName: conn.type == 'custom' ? conn.customImageName! : connectorTypeMetadata[conn.type].imageName

    registry: conn.?registry ?? (conn.type != 'custom'
      ? connectorTypeMetadata[conn.type].defaultRegistry
      : 'mcr.microsoft.com')
    imageTag: conn.?imageTag ?? (conn.type != 'custom' ? connectorTypeMetadata[conn.type].defaultTag : 'latest')
    replicas: conn.?replicas ?? 1
    imagePullPolicy: conn.?imagePullPolicy ?? 'IfNotPresent'
    logLevel: toLower(conn.?logLevel ?? 'info')
    aioMinVersion: conn.?aioMinVersion ?? (conn.type != 'custom'
      ? connectorTypeMetadata[conn.type].defaultMinVersion
      : null)
    aioMaxVersion: conn.?aioMaxVersion
    allocation: conn.?allocation
    additionalConfiguration: conn.?additionalConfiguration
    secrets: conn.?secrets
    trustSettings: conn.?trustSettings

    connectorMetadataRef: conn.type == 'custom' && conn.?customConnectorMetadataRef != null
      ? conn.customConnectorMetadataRef!
      : '${conn.?registry ?? (conn.type != 'custom' ? connectorTypeMetadata[conn.type].defaultRegistry : 'mcr.microsoft.com')}/${conn.type == 'custom' ? conn.customImageName! : connectorTypeMetadata[conn.type].imageName}-metadata:${conn.?imageTag ?? (conn.type != 'custom' ? connectorTypeMetadata[conn.type].defaultTag : 'latest')}'

    mqttConfig: conn.?mqttConfig ?? mqttSharedConfig
  }
]

/*
  Resources
*/

@batchSize(1)
resource connectorTemplate 'Microsoft.IoTOperations/instances/akriConnectorTemplates@2025-10-01' = [
  for (conn, i) in processedConnectors: {
    name: '${last(split(aioInstanceId, '/'))!}/${conn.name}'
    extendedLocation: {
      type: 'CustomLocation'
      name: customLocationId
    }
    properties: union(
      {
        connectorMetadataRef: conn.connectorMetadataRef
        deviceInboundEndpointTypes: [
          {
            endpointType: conn.endpointType
            version: conn.endpointVersion
          }
        ]
        runtimeConfiguration: {
          runtimeConfigurationType: 'ManagedConfiguration'
          managedConfigurationSettings: union(
            {
              managedConfigurationType: 'ImageConfiguration'
              imageConfigurationSettings: {
                registrySettings: {
                  registrySettingsType: 'ContainerRegistry'
                  containerRegistrySettings: {
                    registry: conn.registry
                  }
                }
                imageName: conn.imageName
                imagePullPolicy: conn.imagePullPolicy
                replicas: conn.replicas
                tagDigestSettings: {
                  tagDigestType: 'Tag'
                  tag: conn.imageTag
                }
              }
            },
            conn.?allocation != null ? { allocation: conn.allocation! } : {},
            conn.?additionalConfiguration != null ? { additionalConfiguration: conn.additionalConfiguration! } : {},
            conn.?secrets != null ? { secrets: conn.secrets! } : {},
            conn.?trustSettings != null ? { trustSettings: conn.trustSettings! } : {}
          )
        }
        mqttConnectionConfiguration: {
          host: conn.mqttConfig.host
          authentication: {
            method: 'ServiceAccountToken'
            serviceAccountTokenSettings: {
              audience: conn.mqttConfig.audience
            }
          }
          keepAliveSeconds: conn.mqttConfig.?keepAliveSeconds ?? 60
          maxInflightMessages: conn.mqttConfig.?maxInflightMessages ?? 100
          protocol: 'Mqtt'
          sessionExpirySeconds: conn.mqttConfig.?sessionExpirySeconds ?? 600
          tls: {
            mode: 'Enabled'
            trustedCaCertificateConfigMapRef: conn.mqttConfig.caConfigmap
          }
        }
        diagnostics: {
          logs: {
            level: conn.logLevel
          }
        }
      },
      conn.?aioMinVersion != null || conn.?aioMaxVersion != null
        ? {
            aioMetadata: union(
              conn.?aioMinVersion != null ? { aioMinVersion: conn.aioMinVersion! } : {},
              conn.?aioMaxVersion != null ? { aioMaxVersion: conn.aioMaxVersion! } : {}
            )
          }
        : {}
    )
  }
]

/*
  Outputs
*/

@description('Map of deployed connector templates by name with id and type.')
output connectorTemplates array = [
  for (conn, i) in processedConnectors: {
    id: connectorTemplate[i].id
    name: connectorTemplate[i].name
    type: conn.type
  }
]

@description('List of connector types that were deployed.')
output connectorTypesDeployed array = union(map(processedConnectors, conn => conn.type), [])
