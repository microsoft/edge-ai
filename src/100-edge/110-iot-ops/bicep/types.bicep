/*
 * IMPORTANT: The variable names in this file ('secretStoreExtensionDefaults',
 * 'aioExtensionDefaults') are explicitly referenced
 * by the aio-version-checker.py script. If you rename these variables or change their structure,
 * you must also update the script and the aio-version-checker-template.yml pipeline.
 * NOTE: 'aioCertManagerExtensionDefaults' and 'containerStorageExtensionDefaults' have been
 * moved to the 109-arc-extensions component.
 */

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
    version: '1.1.5'
    train: 'stable'
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
    version: '1.2.154'
    train: 'stable'
  }
  settings: {
    namespace: 'azure-iot-operations'
    kubernetesDistro: 'K3s'
    agentOperationTimeoutInMinutes: 120
  }
}

@description('AIO Instance features.')
@export()
type AioFeatures = {
  @description('Object of features')
  *: InstanceFeature
}

@description('Individual feature object within the AIO instance.')
type InstanceFeature = {
  mode: InstanceFeatureMode?
  settings: {
    *: InstanceFeatureSettingValue
  }
}

@description('The mode of the AIO instance feature. Either "Stable", "Preview" or "Disabled".')
type InstanceFeatureMode = 'Stable' | 'Preview' | 'Disabled'

@description('The setting value of the AIO instance feature. Either "Enabled" or "Disabled".')
type InstanceFeatureSettingValue = 'Enabled' | 'Disabled'

@export()
@description('Broker persistence configuration for disk-backed message storage.')
type BrokerPersistence = {
  @description('Whether persistence is enabled.')
  enabled: bool

  @description('Maximum size of the message buffer on disk (e.g., "500M", "1G").')
  maxSize: string?

  @description('Encryption configuration for the persistence database.')
  encryption: {
    @description('Whether encryption is enabled for the persistence database. Either "Enabled" or "Disabled".')
    mode: ('Enabled' | 'Disabled')
  }?

  @description('Dynamic settings for MQTTv5 user property-based persistence control.')
  dynamicSettings: {
    @description('The user property key to enable persistence.')
    userPropertyKey: string?

    @description('The user property value to enable persistence.')
    userPropertyValue: string?
  }?

  @description('Controls which retained messages should be persisted to disk.')
  retain: {
    @description('Retention policy mode. Either "All", "None", or "Custom".')
    mode: ('All' | 'None' | 'Custom')

    @description('Custom retention settings (required when mode is Custom).')
    retainSettings: {
      @description('List of topics for custom retention (supports wildcards).')
      topics: string[]?

      @description('Dynamic retention control configuration.')
      dynamic: {
        @description('Whether dynamic retention control is enabled. Either "Enabled" or "Disabled".')
        mode: ('Enabled' | 'Disabled')
      }?
    }?
  }?

  @description('Controls which state store keys should be persisted to disk.')
  stateStore: {
    @description('State store policy mode. Either "All", "None", or "Custom".')
    mode: ('All' | 'None' | 'Custom')

    @description('Custom state store settings (required when mode is Custom).')
    stateStoreSettings: {
      @description('List of state store resources to persist.')
      stateStoreResources: {
        @description('The key type for persistence. Either "Pattern", "String", or "Binary".')
        keyType: ('Pattern' | 'String' | 'Binary')

        @description('List of keys to persist to disk.')
        keys: string[]
      }[]?

      @description('Dynamic state store control configuration.')
      dynamic: {
        @description('Whether dynamic state store control is enabled. Either "Enabled" or "Disabled".')
        mode: ('Enabled' | 'Disabled')
      }?
    }?
  }?

  @description('Controls which subscriber queues should be persisted to disk.')
  subscriberQueue: {
    @description('Subscriber queue policy mode. Either "All", "None", or "Custom".')
    mode: ('All' | 'None' | 'Custom')

    @description('Custom subscriber queue settings (required when mode is Custom).')
    subscriberQueueSettings: {
      @description('List of subscriber client IDs (supports wildcards).')
      subscriberClientIds: string[]?

      @description('List of topics for subscriber persistence (supports wildcards).')
      topics: string[]?

      @description('Dynamic subscriber queue control configuration.')
      dynamic: {
        @description('Whether dynamic subscriber queue control is enabled. Either "Enabled" or "Disabled".')
        mode: ('Enabled' | 'Disabled')
      }?
    }?
  }?

  @description('Persistent volume claim specification for storage.')
  persistentVolumeClaimSpec: {
    @description('Storage class name for the persistent volume.')
    storageClassName: string?

    @description('Access modes for the persistent volume.')
    accessModes: string[]?

    @description('Volume mode (Filesystem or Block).')
    volumeMode: string?

    @description('Volume name.')
    volumeName: string?

    @description('Resource requirements for the persistent volume.')
    resources: {
      @description('Resource requests.')
      requests: object?

      @description('Resource limits.')
      limits: object?
    }?

    @description('Data source for the persistent volume.')
    dataSource: {
      @description('API group of the data source.')
      apiGroup: string?

      @description('Kind of the data source.')
      kind: string

      @description('Name of the data source.')
      name: string
    }?

    @description('Label selector for persistent volume selection.')
    selector: {
      @description('Label match requirements.')
      matchLabels: object?

      @description('Expression-based match requirements.')
      matchExpressions: {
        @description('Label key.')
        key: string

        @description('Selection operator for persistent volume label selectors.')
        operator: ('In' | 'NotIn' | 'Exists' | 'DoesNotExist')

        @description('Label values.')
        values: string[]?
      }[]?
    }?
  }?
}

@export()
@description('The settings for the Azure IoT Operations MQ Broker.')
type AioMqBroker = {
  @description('The service name for the broker listener.')
  brokerListenerServiceName: string

  @description('The port for the broker listener.')
  brokerListenerPort: int

  @description('The audience for the service account.')
  serviceAccountAudience: string

  @description('The number of frontend replicas for the broker.')
  frontendReplicas: int

  @description('The number of frontend workers for the broker.')
  frontendWorkers: int

  @description('The redundancy factor for the backend of the broker.')
  backendRedundancyFactor: int

  @description('The number of backend workers for the broker.')
  backendWorkers: int

  @description('The number of partitions for the backend of the broker.')
  backendPartitions: int

  @description('The memory profile for the broker (Low, Medium, High).')
  memoryProfile: string

  @description('The service type for the broker (ClusterIP, LoadBalancer, NodePort).')
  serviceType: string

  @description('The log level for broker diagnostics (info, debug, trace).')
  logsLevel: string

  @description('Broker persistence configuration for disk-backed message storage.')
  persistence: BrokerPersistence?
}

@export()
var aioMqBrokerDefaults = {
  brokerListenerServiceName: 'aio-broker'
  brokerListenerPort: 18883
  serviceAccountAudience: 'aio-internal'
  frontendReplicas: 2
  frontendWorkers: 2
  backendRedundancyFactor: 2
  backendWorkers: 2
  backendPartitions: 2
  memoryProfile: 'Medium'
  serviceType: 'ClusterIp'
  logsLevel: 'info'
}

@export()
@description('Configuration for the insecure anonymous AIO MQ Broker Listener.')
type AioMqBrokerAnonymous = {
  @description('The service name for the anonymous broker listener.')
  serviceName: string

  @description('The port for the anonymous broker listener.')
  port: int

  @description('The node port for the anonymous broker listener.')
  nodePort: int
}

@export()
var aioMqBrokerAnonymousDefaults = {
  serviceName: 'aio-broker-anon'
  port: 18884
  nodePort: 31884
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
@description('The source of trust for Azure IoT Operations certificates.')
type TrustSource = 'SelfSigned' | 'CustomerManaged'

@export()
@description('The config source of trust for how to use or generate Azure IoT Operations certificates.')
type TrustConfigSource = 'SelfSigned' | 'CustomerManagedByoIssuer' | 'CustomerManagedGenerateIssuer'

@export()
@description('The configuration for the Customer Managed Generated trust source of Azure IoT Operations certificates.')
type CustomerManagedGenerateIssuerConfig = {
  trustSource: 'CustomerManagedGenerateIssuer'

  @description('The CA certificate, chain, and key for Azure IoT Operations.')
  aioCa: AioCaConfig?
}

@export()
@description('The configuration for Customer Managed Bring Your Own Issuer for Azure IoT Operations certificates.')
type CustomerManagedByoIssuerConfig = {
  trustSource: 'CustomerManagedByoIssuer'

  @description('The trust settings for Azure IoT Operations.')
  trustSettings: TrustSettingsConfig
}

@export()
@description('The configuration for Self-Signed Issuer for Azure IoT Operations certificates.')
type SelfSignedIssuerConfig = {
  trustSource: 'SelfSigned'
}

@export()
@description('The configuration for the trust source of Azure IoT Operations certificates.')
@discriminator('trustSource')
type TrustIssuerConfig = SelfSignedIssuerConfig | CustomerManagedByoIssuerConfig | CustomerManagedGenerateIssuerConfig

@export()
@description('Configuration for Azure IoT Operations Certificate Authority.')
type AioCaConfig = {
  @description('The PEM-formatted root CA certificate.')
  @secure()
  rootCaCertPem: string

  @description('The PEM-formatted CA certificate chain.')
  @secure()
  caCertChainPem: string

  @description('The PEM-formatted CA private key.')
  @secure()
  caKeyPem: string
}

@export()
@description('The configuration for the trust settings of Azure IoT Operations certificates.')
type TrustSettingsConfig = {
  issuerName: string
  issuerKind: string
  configMapName: string
  configMapKey: string
}

@export()
var defaultCustomerManagedTrustSettings = {
  issuerName: 'issuer-custom-root-ca-cert'
  issuerKind: 'ClusterIssuer'
  configMapName: 'bundle-custom-ca-cert'
  configMapKey: 'ca.crt'
}

@export()
@description('Environment variable configuration for scripts.')
type ScriptEnvironmentVariable = {
  @description('The name of the environment variable.')
  name: string

  @description('The value of the environment variable.')
  value: string?

  @description('The secure value of the environment variable.')
  @secure()
  secureValue: string?
}

@export()
@description('Script configuration for deployment scripts.')
type ScriptConfig = {
  @description('The script content to be executed.')
  @secure()
  content: string

  @description('Environment variables for the script.')
  env: ScriptEnvironmentVariable[]?
}

@export()
@description('Additional file configuration for deployment scripts.')
type IncludeFileConfig = {
  @description('The name of the file to create.')
  name: string

  @description('The content of the file to create.')
  @secure()
  content: string
}

@export()
@description('The script and additional configuration files for deployment scripts.')
type ScriptFilesConfig = {
  @description('The script configuration for deployment scripts.')
  scripts: ScriptConfig[]

  @description('The additional file configuration for deployment scripts.s')
  includeFiles: IncludeFileConfig[]
}

@export()
@description('''
Returns an empty ScriptFilesConfig object with no scripts or includeFiles.
Useful as a default or initial value when building up script configurations.
''')
func emptyScriptFiles() ScriptFilesConfig => { scripts: [], includeFiles: [] }

@export()
@description('''
Adds a script and optional includeFiles to an existing ScriptFilesConfig context if the predicate is true.
If predicate is false, returns the context as-is or an empty ScriptFilesConfig if context is null.
This is useful for conditionally building up script and file lists for deployment.
''')
func toScriptFiles(context ScriptFilesConfig?, predicate bool, script ScriptConfig, files IncludeFileConfig[]?) ScriptFilesConfig =>
  predicate
    ? {
        scripts: [
          ...(context.?scripts ?? [])
          script
        ]
        includeFiles: [...(context.?includeFiles ?? []), ...(files ?? [])]
      }
    : (context ?? { scripts: [], includeFiles: [] })

@export()
@description('''
Combines two ScriptFilesConfig objects into one by merging their scripts and includeFiles arrays.
This is useful for aggregating multiple script/file configurations into a single deployment object.
''')
func combineScriptFiles(firstPart ScriptFilesConfig?, secondPart ScriptFilesConfig?) ScriptFilesConfig => {
  scripts: [...(firstPart.?scripts ?? []), ...(secondPart.?scripts ?? [])]
  includeFiles: [...(firstPart.?includeFiles ?? []), ...(secondPart.?includeFiles ?? [])]
}

@export()
@description('''
This function is used to generate the set of scripts and files required for the Azure DeploymentScript resource in IoT Operations deployments. It includes:
- The main deployment setup script
- The Arc K8s Proxy connection script, which enables the AIO cluster to connect to Arc-enabled Kubernetes
- Any additional script files provided as input

The result is a ScriptFilesConfig object that can be used to automate deployment, ensuring all necessary scripts and files are included for cluster setup and connectivity.

Note: The function will only return a ScriptFilesConfig object if there are scripts provided in the input. If no scripts are present, it will return null and no deployment scripts will be created.
''')
func tryCreateDeployScriptFiles(
  deployUserTokenSecretName string,
  arcConnectedClusterName string,
  resourceGroupName string,
  aioNamespace string,
  scriptFiles ScriptFilesConfig?
) ScriptFilesConfig? =>
  scriptFiles.?scripts == null
    ? null
    : combineScriptFiles(
        {
          scripts: [
            // Deployment Script Setup

            {
              content: loadTextContent('../scripts/deployment-script-setup.sh')
            }

            // Arc K8s Proxy Connect

            {
              content: loadTextContent('../scripts/init-scripts.sh')
              env: [
                {
                  name: 'TF_MODULE_PATH'
                  value: '.'
                }
                {
                  name: 'DEPLOY_USER_TOKEN_SECRET'
                  value: deployUserTokenSecretName
                }
                {
                  name: 'TF_CONNECTED_CLUSTER_NAME'
                  value: arcConnectedClusterName
                }
                {
                  name: 'TF_RESOURCE_GROUP_NAME'
                  value: resourceGroupName
                }
                {
                  name: 'TF_AIO_NAMESPACE'
                  value: aioNamespace
                }
              ]
            }
          ]
          includeFiles: [
            {
              name: 'yaml/aio-namespace.yaml'
              content: loadTextContent('../yaml/aio-namespace.yaml')
            }
          ]
        },
        scriptFiles
      )

@export()
@description('MQTT connection configuration for Akri connectors.')
type AkriMqttConfig = {
  @description('MQTT broker host address.')
  host: string

  @description('Service account token audience for authentication.')
  audience: string

  @description('ConfigMap reference for trusted CA certificates.')
  caConfigmap: string

  @description('Keep alive interval in seconds.')
  keepAliveSeconds: int?

  @description('Maximum number of in-flight messages.')
  maxInflightMessages: int?

  @description('Session expiry interval in seconds.')
  sessionExpirySeconds: int?
}

@export()
@description('Resource allocation policy for Akri connector pods.')
type AkriAllocationPolicy = {
  @description('Allocation policy type.')
  policy: 'Bucketized'

  @description('Bucket size for allocation (1-100).')
  @minValue(1)
  @maxValue(100)
  bucketSize: int
}

@export()
@description('Secret configuration for Akri connector.')
type AkriSecretConfig = {
  @description('Alias for the secret.')
  secretAlias: string

  @description('Key within the secret.')
  secretKey: string

  @description('Reference to the secret resource.')
  secretRef: string
}

@export()
@description('Trust settings for Akri connector.')
type AkriTrustSettings = {
  @description('Reference to the trust list secret.')
  trustListSecretRef: string
}

@export()
@description('Akri connector template configuration.')
type AkriConnectorTemplate = {
  @description('Unique name for the connector (lowercase letters, numbers, and hyphens only).')
  name: string

  @description('Connector type.')
  type: 'rest' | 'media' | 'onvif' | 'sse' | 'custom'

  @description('Custom endpoint type (required for custom connectors).')
  customEndpointType: string?

  @description('Custom image name (required for custom connectors).')
  customImageName: string?

  @description('Custom endpoint version.')
  customEndpointVersion: string?

  @description('Custom connector metadata reference.')
  customConnectorMetadataRef: string?

  @description('Container registry for pulling connector images.')
  registry: string?

  @description('Image tag for the connector.')
  imageTag: string?

  @description('Number of connector replicas.')
  @minValue(1)
  @maxValue(10)
  replicas: int?

  @description('Image pull policy.')
  imagePullPolicy: ('Always' | 'IfNotPresent' | 'Never')?

  @description('Log level for connector diagnostics.')
  logLevel: ('trace' | 'debug' | 'info' | 'warning' | 'error' | 'critical')?

  @description('MQTT configuration override for this connector.')
  mqttConfig: AkriMqttConfig?

  @description('Minimum AIO version requirement.')
  aioMinVersion: string?

  @description('Maximum AIO version requirement.')
  aioMaxVersion: string?

  @description('Resource allocation policy.')
  allocation: AkriAllocationPolicy?

  @description('Additional configuration key-value pairs.')
  additionalConfiguration: object?

  @description('Secret configurations.')
  secrets: AkriSecretConfig[]?

  @description('Trust settings configuration.')
  trustSettings: AkriTrustSettings?
}
