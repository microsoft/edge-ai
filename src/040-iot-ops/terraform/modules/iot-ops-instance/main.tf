/**
 * # Azure IoT Instance
 *
 * Deploys an AIO instance.
 *
 */

locals {
  # AIO Instance 
  selfsigned_issuer_name    = "${var.operations_config.namespace}-aio-certificate-issuer"
  selfsigned_configmap_name = "${var.operations_config.namespace}-aio-ca-trust-bundle"

  is_customer_managed = var.trust_source == "CustomerManaged"

  trust = local.is_customer_managed ? var.customer_managed_trust_settings : {
    issuer_name    = local.selfsigned_issuer_name
    issuer_kind    = "ClusterIssuer"
    configmap_name = local.selfsigned_configmap_name
    configmap_key  = ""
  }
  custom_location_name = "${var.connected_cluster_name}-cl"
  aio_instance_name    = "${var.connected_cluster_name}-ops-instance"

  mqtt_broker_address = "mqtts://${var.mqtt_broker_config.brokerListenerServiceName}.${var.operations_config.namespace}:${var.mqtt_broker_config.brokerListenerPort}"

  metrics = {
    enabled               = var.enable_otel_collector
    otelCollectorAddress  = var.enable_otel_collector ? "aio-otel-collector.${var.operations_config.namespace}.svc.cluster.local:4317" : ""
    exportIntervalSeconds = 60
  }
}


resource "azurerm_arc_kubernetes_cluster_extension" "iot_operations" {
  name           = "iot-ops"
  cluster_id     = var.arc_connected_cluster_id
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
    "observability.metrics.enabled"                                        = local.metrics.enabled ? "true" : "false"
    "observability.metrics.openTelemetryCollectorAddress"                  = local.metrics.otelCollectorAddress
    "observability.metrics.exportIntervalSeconds"                          = tostring(local.metrics.exportIntervalSeconds)
    "trustSource"                                                          = var.trust_source
    "trustBundleSettings.issuer.name"                                      = local.trust.issuer_name
    "trustBundleSettings.issuer.kind"                                      = local.trust.issuer_kind
    "trustBundleSettings.configMap.name"                                   = local.trust.configmap_name
    "trustBundleSettings.configMap.key"                                    = local.trust.configmap_key
    "schemaRegistry.values.mqttBroker.host"                                = local.mqtt_broker_address
    "schemaRegistry.values.mqttBroker.tlsEnabled"                          = true,
    "schemaRegistry.values.mqttBroker.serviceAccountTokenAudience"         = var.mqtt_broker_config.serviceAccountAudience
  }
}

resource "azapi_resource" "custom_location" {
  type      = "Microsoft.ExtendedLocation/customLocations@2021-08-31-preview"
  name      = local.custom_location_name
  location  = var.connected_cluster_location
  parent_id = var.resource_group_id
  identity {
    type = "SystemAssigned"
  }
  body = {
    properties = {
      hostResourceId      = var.arc_connected_cluster_id
      namespace           = var.operations_config.namespace
      displayName         = local.custom_location_name
      clusterExtensionIds = [var.platform_cluster_extension_id, var.secret_store_cluster_extension_id, azurerm_arc_kubernetes_cluster_extension.iot_operations.id]
    }
  }
  response_export_values = ["name", "id"]
  depends_on             = [azurerm_arc_kubernetes_cluster_extension.iot_operations]
}

resource "azapi_resource" "aio_sync_rule" {
  type      = "Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview"
  name      = "${azapi_resource.custom_location.name}/${azapi_resource.custom_location.name}-broker-sync"
  location  = var.connected_cluster_location
  parent_id = var.resource_group_id
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
      targetResourceGroup = var.resource_group_id
    }
  }
  count = var.deploy_resource_sync_rules ? 1 : 0
}

resource "azapi_resource" "aio_device_registry_sync_rule" {
  type      = "Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview"
  name      = "${azapi_resource.custom_location.name}/${azapi_resource.custom_location.name}-adr-sync"
  location  = var.connected_cluster_location
  parent_id = var.resource_group_id
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
      targetResourceGroup = var.resource_group_id
    }
  }
  depends_on = [azapi_resource.aio_sync_rule]
  count      = var.deploy_resource_sync_rules ? 1 : 0
}

resource "azapi_resource" "instance" {
  type      = "Microsoft.IoTOperations/instances@2024-11-01"
  name      = local.aio_instance_name
  location  = var.connected_cluster_location
  parent_id = var.resource_group_id
  identity {
    type         = "UserAssigned"
    identity_ids = [var.aio_uami_id]
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
  response_export_values = ["name", "id"]
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
  depends_on             = [azapi_resource.custom_location, azapi_resource.instance]
  response_export_values = ["name", "id"]
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
        host = "${var.mqtt_broker_config.brokerListenerServiceName}:${var.mqtt_broker_config.brokerListenerPort}"
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
