/**
 * # Azure IoT Module
 *
 * Deploys resources necessary to enable Azure IoT Operations (AIO) and creates an AIO instance.
 *
 */

data "azurerm_subscription" "current" {}

locals {
  resource_group_id        = format("%s/resourceGroups/%s", data.azurerm_subscription.current.id, var.resource_group_name)
  arc_connected_cluster_id = format("%s/resourceGroups/%s/providers/Microsoft.Kubernetes/connectedClusters/%s", data.azurerm_subscription.current.id, var.resource_group_name, var.connected_cluster_name)
  default_storage_class    = var.edge_storage_accelerator.faultToleranceEnabled ? "acstor-arccontainerstorage-storage-pool" : "default,local-path"
  kubernetes_storage_class = var.edge_storage_accelerator.diskStorageClass != "" ? var.edge_storage_accelerator.diskStorageClass : local.default_storage_class

  container_storage_settings = var.edge_storage_accelerator.faultToleranceEnabled ? {
    "edgeStorageConfiguration.create"               = "true"
    "feature.diskStorageClass"                      = local.kubernetes_storage_class
    "acstorConfiguration.create"                    = "true"
    "acstorConfiguration.properties.diskMountPoint" = "/mnt"
    } : {
    "edgeStorageConfiguration.create" = "true"
    "feature.diskStorageClass"        = local.kubernetes_storage_class
  }
  # AIO Instance 
  selfsigned_issuer_name    = "${var.operations_config.namespace}-aio-certificate-issuer"
  selfsigned_configmap_name = "${var.operations_config.namespace}-aio-ca-trust-bundle"
  trust = {
    issuer_name    = var.trust_config.source == "CustomerManaged" ? var.trust_config.settings.issuerName : local.selfsigned_issuer_name
    issuer_kind    = var.trust_config.source == "CustomerManaged" ? var.trust_config.settings.issuerKind : "ClusterIssuer"
    configmap_name = var.trust_config.source == "CustomerManaged" ? var.trust_config.settings.configMapName : local.selfsigned_configmap_name
  }
  custom_location_name = "${var.connected_cluster_name}-cl"
  aio_instance_name    = "${var.connected_cluster_name}-ops-instance"

  mqtt_broker_address = format("mqtts://%s.%s:%s", var.mqtt_broker_config.brokerListenerServiceName, var.operations_config.namespace, var.mqtt_broker_config.brokerListenerPort)
}

resource "azurerm_arc_kubernetes_cluster_extension" "platform" {
  name           = "azure-iot-operations-platform"
  cluster_id     = local.arc_connected_cluster_id
  extension_type = "microsoft.iotoperations.platform"
  identity {
    type = "SystemAssigned"
  }
  version           = var.platform.version
  release_train     = var.platform.train
  release_namespace = "cert-manager"
  configuration_settings = {
    "installCertManager"  = (var.trust_config.source == "SelfSigned") ? "true" : "false"
    "installTrustManager" = (var.trust_config.source == "SelfSigned") ? "true" : "false"
  }
}

resource "azurerm_arc_kubernetes_cluster_extension" "secret_store" {
  name           = "azure-secret-store"
  cluster_id     = local.arc_connected_cluster_id
  extension_type = "microsoft.azure.secretstore"
  identity {
    type = "SystemAssigned"
  }
  version       = var.secret_sync_controller.version
  release_train = var.secret_sync_controller.train
  configuration_settings = {
    "rotationPollIntervalInSeconds"             = "120"
    "validatingAdmissionPolicies.applyPolicies" = "false"
  }
  depends_on = [azurerm_arc_kubernetes_cluster_extension.platform]
}

resource "azurerm_arc_kubernetes_cluster_extension" "open_service_mesh" {
  name           = "open-service-mesh"
  cluster_id     = local.arc_connected_cluster_id
  extension_type = "microsoft.openservicemesh"
  identity {
    type = "SystemAssigned"
  }
  version       = var.open_service_mesh.version
  release_train = var.open_service_mesh.train
  configuration_settings = {
    "osm.osm.enablePermissiveTrafficPolicy"       = "false"
    "osm.osm.featureFlags.enableWASMStats"        = "false"
    "osm.osm.configResyncInterval"                = "10s"
    "osm.osm.osmController.resource.requests.cpu" = "100m"
    "osm.osm.osmBootstrap.resource.requests.cpu"  = "100m"
    "osm.osm.injector.resource.requests.cpu"      = "100m"
  }
}

resource "azurerm_arc_kubernetes_cluster_extension" "container_storage" {
  name           = "azure-arc-containerstorage"
  cluster_id     = local.arc_connected_cluster_id
  extension_type = "microsoft.arc.containerstorage"
  identity {
    type = "SystemAssigned"
  }
  version                = var.edge_storage_accelerator.version
  release_train          = var.edge_storage_accelerator.train
  configuration_settings = local.container_storage_settings
  depends_on             = [azurerm_arc_kubernetes_cluster_extension.platform, azurerm_arc_kubernetes_cluster_extension.open_service_mesh]
}

resource "azurerm_arc_kubernetes_cluster_extension" "iot_operations" {
  name           = "${var.connected_cluster_name}-iot-ops"
  cluster_id     = local.arc_connected_cluster_id
  extension_type = "microsoft.iotoperations"
  identity {
    type = "SystemAssigned"
  }
  version           = var.operations_config.version
  release_train     = var.operations_config.train
  release_namespace = var.operations_config.namespace
  # Current default config
  configuration_settings = {
    "AgentOperationTimeoutInMinutes"                                       = tostring(var.operations_config.agentOperationTimeoutInMinutes)
    "connectors.values.mqttBroker.address"                                 = local.mqtt_broker_address
    "connectors.values.mqttBroker.serviceAccountTokenAudience"             = var.mqtt_broker_config.serviceAccountAudience
    "connectors.values.opcPlcSimulation.deploy"                            = "false"
    "connectors.values.opcPlcSimulation.autoAcceptUntrustedCertificates"   = "false"
    "connectors.values.discoveryHandler.enabled"                           = "false"
    "adr.values.Microsoft.CustomLocation.ServiceAccount"                   = "default"
    "akri.values.webhookConfiguration.enabled"                             = "false"
    "akri.values.certManagerWebhookCertificate.enabled"                    = "false"
    "akri.values.agent.extensionService.mqttBroker.hostName"               = "${var.mqtt_broker_config.brokerListenerServiceName}.${var.operations_config.namespace}"
    "akri.values.agent.extensionService.mqttBroker.port"                   = tostring(var.mqtt_broker_config.brokerListenerPort)
    "akri.values.agent.extensionService.mqttBroker.serviceAccountAudience" = var.mqtt_broker_config.serviceAccountAudience
    "akri.values.agent.host.containerRuntimeSocket"                        = ""
    "akri.values.kubernetesDistro"                                         = lower(var.operations_config.kubernetesDistro)
    "mqttBroker.values.global.quickstart"                                  = "false"
    "mqttBroker.values.operator.firstPartyMetricsOn"                       = "true"
    "observability.metrics.enabled"                                        = var.metrics.enabled ? "true" : "false"
    "observability.metrics.openTelemetryCollectorAddress"                  = var.metrics.otelCollectorAddress
    "observability.metrics.exportIntervalSeconds"                          = tostring(var.metrics.exportIntervalSeconds)
    "trustSource"                                                          = var.trust_config.source
    "trustBundleSettings.issuer.name"                                      = local.trust.issuer_name
    "trustBundleSettings.issuer.kind"                                      = local.trust.issuer_kind
    "trustBundleSettings.configMap.name"                                   = local.trust.configmap_name
    "trustBundleSettings.configMap.key"                                    = var.trust_config.source == "SelfSigned" ? "" : var.trust_config.settings.configMapKey
    "schemaRegistry.values.mqttBroker.host"                                = local.mqtt_broker_address
    "schemaRegistry.values.mqttBroker.tlsEnabled"                          = true,
    "schemaRegistry.values.mqttBroker.serviceAccountTokenAudience"         = var.mqtt_broker_config.serviceAccountAudience
  }
  depends_on = [azurerm_arc_kubernetes_cluster_extension.container_storage]
}

resource "azapi_resource" "custom_location" {
  type      = "Microsoft.ExtendedLocation/customLocations@2021-08-31-preview"
  name      = local.custom_location_name
  location  = var.connected_cluster_location
  parent_id = local.resource_group_id
  identity {
    type = "SystemAssigned"
  }
  body = {
    properties = {
      hostResourceId      = local.arc_connected_cluster_id
      namespace           = var.operations_config.namespace
      displayName         = local.custom_location_name
      clusterExtensionIds = [azurerm_arc_kubernetes_cluster_extension.platform.id, azurerm_arc_kubernetes_cluster_extension.secret_store.id, azurerm_arc_kubernetes_cluster_extension.iot_operations.id]
    }
  }
  response_export_values = ["id"]
  depends_on             = [azurerm_arc_kubernetes_cluster_extension.iot_operations]
}

resource "azapi_resource" "aio_sync_rule" {
  type      = "Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview"
  name      = "${azapi_resource.custom_location.name}/${azapi_resource.custom_location.name}-broker-sync"
  location  = var.connected_cluster_location
  parent_id = local.resource_group_id
  identity {
    type = "SystemAssigned"
  }
  body = {
    properties = {
      priority = 400
      selector = {
        matchLabels = {
          "management.azure.com/provider-name" : "microsoft.iotoperations"
        }
      }
      targetResourceGroup = local.resource_group_id
    }
  }
  count = var.deploy_resource_sync_rules ? 1 : 0
}

resource "azapi_resource" "aio_device_registry_sync_rule" {
  type      = "Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview"
  name      = "${azapi_resource.custom_location.name}/${azapi_resource.custom_location.name}-adr-sync"
  location  = var.connected_cluster_location
  parent_id = local.resource_group_id
  identity {
    type = "SystemAssigned"
  }
  body = {
    properties = {
      priority = 200
      selector = {
        matchLabels = {
          "management.azure.com/provider-name" : "Microsoft.DeviceRegistry"
        }
      }
      targetResourceGroup = local.resource_group_id
    }
  }
  depends_on = [azapi_resource.aio_sync_rule]
  count      = var.deploy_resource_sync_rules ? 1 : 0
}

resource "azapi_resource" "instance" {
  type      = "Microsoft.IoTOperations/instances@2024-11-01"
  name      = local.aio_instance_name
  location  = var.connected_cluster_location
  parent_id = local.resource_group_id
  identity {
    type = "SystemAssigned"
  }
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.output.id
      type = "CustomLocation"
    }
    properties = {
      schemaRegistryRef = {
        resourceId = var.schema_registry_id
      }
    }
  }
  depends_on = [azapi_resource.custom_location]
}

resource "azapi_resource" "broker" {
  type      = "Microsoft.IoTOperations/instances/brokers@2024-11-01"
  name      = "default"
  parent_id = azapi_resource.instance.id
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.output.id
      type = "CustomLocation"
    }
    properties = {
      memoryProfile = var.mqtt_broker_config.memoryProfile
      generateResourceLimits = {
        cpu = "Disabled"
      }
      cardinality = {
        backendChain = {
          partitions       = var.mqtt_broker_config.backendPartitions
          workers          = var.mqtt_broker_config.backendWorkers
          redundancyFactor = var.mqtt_broker_config.backendRedundancyFactor
        }
        frontend = {
          replicas = var.mqtt_broker_config.frontendReplicas
          workers  = var.mqtt_broker_config.frontendWorkers
        }
      }
    }
  }
  depends_on = [azapi_resource.custom_location, azapi_resource.instance]
}

resource "azapi_resource" "broker_authn" {
  type      = "Microsoft.IoTOperations/instances/brokers/authentications@2024-11-01"
  name      = "default"
  parent_id = azapi_resource.broker.id
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.output.id
      type = "CustomLocation"
    }
    properties = {
      authenticationMethods = [
        {
          method = "ServiceAccountToken"
          serviceAccountTokenSettings = {
            audiences = [var.mqtt_broker_config.serviceAccountAudience]
          }
        }
      ]
    }
  }
  depends_on = [azapi_resource.custom_location, azapi_resource.broker]
}

resource "azapi_resource" "broker_listener" {
  type      = "Microsoft.IoTOperations/instances/brokers/listeners@2024-11-01"
  name      = "default"
  parent_id = azapi_resource.broker.id
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.output.id
      type = "CustomLocation"
    }
    properties = {
      serviceType = var.mqtt_broker_config.serviceType
      serviceName = var.mqtt_broker_config.brokerListenerServiceName
      ports = [
        {
          authenticationRef = "default"
          port              = var.mqtt_broker_config.brokerListenerPort
          tls = {
            mode = "Automatic"
            certManagerCertificateSpec = {
              issuerRef = {
                name  = local.trust.issuer_name
                kind  = local.trust.issuer_kind
                group = "cert-manager.io"
              }
            }
          }
        }
      ]
    }
  }
  depends_on = [azapi_resource.custom_location, azapi_resource.broker, azapi_resource.broker_authn]
}

resource "azapi_resource" "data_profiles" {
  type      = "Microsoft.IoTOperations/instances/dataflowProfiles@2024-11-01"
  name      = "default"
  parent_id = azapi_resource.instance.id
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.output.id
      type = "CustomLocation"
    }
    properties = {
      instanceCount = var.dataflow_instance_count
    }
  }
  depends_on = [azapi_resource.custom_location, azapi_resource.instance]
}

resource "azapi_resource" "data_endpoint" {
  type      = "Microsoft.IoTOperations/instances/dataflowEndpoints@2024-11-01"
  name      = "default"
  parent_id = azapi_resource.instance.id
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.output.id
      type = "CustomLocation"
    }
    properties = {
      endpointType = "Mqtt"
      mqttSettings = {
        host = format("%s:%s", var.mqtt_broker_config.brokerListenerServiceName, var.mqtt_broker_config.brokerListenerPort)
        authentication = {
          method = "ServiceAccountToken"
          serviceAccountTokenSettings = {
            audience = var.mqtt_broker_config.serviceAccountAudience
          }
        }
        tls = {
          mode                             = "Enabled"
          trustedCaCertificateConfigMapRef = local.trust.configmap_name
        }
      }
    }
  }
  depends_on = [azapi_resource.custom_location, azapi_resource.instance]
}
