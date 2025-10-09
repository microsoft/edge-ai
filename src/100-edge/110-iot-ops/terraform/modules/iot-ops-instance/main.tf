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
  custom_location_name = "cl-${var.connected_cluster_name}"
  aio_instance_name    = "iotops-${var.connected_cluster_name}"

  mqtt_broker_hostname = "${var.mqtt_broker_config.brokerListenerServiceName}.${var.operations_config.namespace}"
  mqtt_broker_address  = "mqtts://${local.mqtt_broker_hostname}:${var.mqtt_broker_config.brokerListenerPort}"

  # Helper function for boolean to enabled/disabled string conversion
  enabled_disabled = {
    true  = "Enabled"
    false = "Disabled"
  }

  metrics = {
    enabled               = var.should_enable_otel_collector
    otelCollectorAddress  = var.should_enable_otel_collector ? "aio-otel-collector.${var.operations_config.namespace}.svc.cluster.local:4317" : ""
    exportIntervalSeconds = 60
  }

  spc_name_hash_input = "${var.connected_cluster_name}-${var.resource_group.name}-${local.aio_instance_name}"
  spc_name            = "spc-ops-${substr(sha256(local.spc_name_hash_input), 0, 7)}"
}


data "azurerm_subscription" "current" {}


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

resource "azurerm_role_assignment" "schema_registry" {
  scope                = var.schema_registry_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_arc_kubernetes_cluster_extension.iot_operations.identity[0].principal_id
}

resource "azapi_resource" "custom_location" {
  type      = "Microsoft.ExtendedLocation/customLocations@2021-08-31-preview"
  name      = local.custom_location_name
  location  = var.connected_cluster_location
  parent_id = var.resource_group.id
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
  name      = "${azapi_resource.custom_location.name}-broker-sync"
  parent_id = azapi_resource.custom_location.id
  body = {
    location = var.connected_cluster_location
    properties = {
      priority = 400
      selector = {
        matchLabels = {
          "management.azure.com/provider-name" : "microsoft.iotoperations"
        }
      }
      targetResourceGroup = var.resource_group.id
    }
  }

  count = var.should_deploy_resource_sync_rules ? 1 : 0
}

resource "azapi_resource" "aio_device_registry_sync_rule" {
  type      = "Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview"
  name      = "${azapi_resource.custom_location.name}-adr-sync"
  parent_id = azapi_resource.custom_location.id

  body = {
    location = var.connected_cluster_location
    properties = {
      priority = 200
      selector = {
        matchLabels = {
          "management.azure.com/provider-name" : "Microsoft.DeviceRegistry"
        }
      }
      targetResourceGroup = var.resource_group.id
    }
  }

  count = var.should_deploy_resource_sync_rules ? 1 : 0
}

resource "azapi_resource" "instance" {
  type      = "Microsoft.IoTOperations/instances@2025-07-01-preview"
  name      = local.aio_instance_name
  location  = var.connected_cluster_location
  parent_id = var.resource_group.id
  identity {
    type         = "UserAssigned"
    identity_ids = [var.aio_uami_id]
  }
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.id
      type = "CustomLocation"
    }
    properties = {
      schemaRegistryRef = {
        resourceId = var.schema_registry_id
      }
      adrNamespaceRef = var.adr_namespace_id != null ? {
        resourceId = var.adr_namespace_id
      } : null
      features = try(var.aio_features, null)
    }
  }
  depends_on             = [azurerm_arc_kubernetes_cluster_extension.iot_operations]
  response_export_values = ["name", "id"]

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-07-01-preview until azapi provider supports it
}

resource "azapi_resource" "broker" {
  type      = "Microsoft.IoTOperations/instances/brokers@2025-07-01-preview"
  name      = "default"
  parent_id = azapi_resource.instance.id
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.id
      type = "CustomLocation"
    }
    properties = merge(
      {
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
        diagnostics = {
          logs = {
            level = var.mqtt_broker_config.logsLevel
          }
        }
      },
      try({
        persistence = merge(
          {
            maxSize = var.mqtt_broker_persistence_config.max_size
          },
          try({
            encryption = {
              mode = local.enabled_disabled[var.mqtt_broker_persistence_config.encryption_enabled]
            }
          }, {}),
          try({
            dynamicSettings = {
              userPropertyKey   = var.mqtt_broker_persistence_config.dynamic_settings.user_property_key
              userPropertyValue = var.mqtt_broker_persistence_config.dynamic_settings.user_property_value
            }
          }, {}),
          try({
            retain = merge(
              {
                mode = var.mqtt_broker_persistence_config.retain_policy.mode
              },
              try(
                alltrue([
                  var.mqtt_broker_persistence_config.retain_policy.custom_settings != null,
                  var.mqtt_broker_persistence_config.retain_policy.mode == "Custom"
                  ]) ? {
                  retainSettings = merge(
                    try({
                      topics = var.mqtt_broker_persistence_config.retain_policy.custom_settings.topics
                    }, {}),
                    try({
                      dynamic = {
                        mode = local.enabled_disabled[var.mqtt_broker_persistence_config.retain_policy.custom_settings.dynamic_enabled]
                      }
                    }, {})
                  )
                } : {},
                {}
              )
            )
          }, {}),
          try({
            stateStore = merge(
              {
                mode = var.mqtt_broker_persistence_config.state_store_policy.mode
              },
              try(
                alltrue([
                  var.mqtt_broker_persistence_config.state_store_policy.custom_settings != null,
                  var.mqtt_broker_persistence_config.state_store_policy.mode == "Custom"
                  ]) ? {
                  stateStoreSettings = merge(
                    try({
                      stateStoreResources = [
                        for resource in var.mqtt_broker_persistence_config.state_store_policy.custom_settings.state_store_resources : {
                          keyType = resource.key_type
                          keys    = resource.keys
                        }
                      ]
                    }, {}),
                    try({
                      dynamic = {
                        mode = local.enabled_disabled[var.mqtt_broker_persistence_config.state_store_policy.custom_settings.dynamic_enabled]
                      }
                    }, {})
                  )
                } : {},
                {}
              )
            )
          }, {}),
          try({
            subscriberQueue = merge(
              {
                mode = var.mqtt_broker_persistence_config.subscriber_queue_policy.mode
              },
              try(
                alltrue([
                  var.mqtt_broker_persistence_config.subscriber_queue_policy.custom_settings != null,
                  var.mqtt_broker_persistence_config.subscriber_queue_policy.mode == "Custom"
                  ]) ? {
                  subscriberQueueSettings = merge(
                    try({
                      subscriberClientIds = var.mqtt_broker_persistence_config.subscriber_queue_policy.custom_settings.subscriber_client_ids
                    }, {}),
                    try({
                      topics = var.mqtt_broker_persistence_config.subscriber_queue_policy.custom_settings.topics
                    }, {}),
                    try({
                      dynamic = {
                        mode = local.enabled_disabled[var.mqtt_broker_persistence_config.subscriber_queue_policy.custom_settings.dynamic_enabled]
                      }
                    }, {})
                  )
                } : {},
                {}
              )
            )
          }, {}),
          try({
            persistentVolumeClaimSpec = merge(
              try({
                volumeName = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.volume_name
              }, {}),
              try({
                volumeMode = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.volume_mode
              }, {}),
              try({
                storageClassName = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.storage_class_name
              }, {}),
              try({
                accessModes = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.access_modes
              }, {}),
              try({
                dataSource = merge(
                  {
                    kind = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.data_source.kind
                    name = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.data_source.name
                  },
                  try({
                    apiGroup = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.data_source.api_group
                  }, {})
                )
              }, {}),
              try({
                resources = merge(
                  try({
                    requests = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.resources.requests
                  }, {}),
                  try({
                    limits = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.resources.limits
                  }, {})
                )
              }, {}),
              try({
                selector = merge(
                  try({
                    matchLabels = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.selector.match_labels
                  }, {}),
                  try({
                    matchExpressions = [
                      for expr in var.mqtt_broker_persistence_config.persistent_volume_claim_spec.selector.match_expressions : {
                        key      = expr.key
                        operator = expr.operator
                        values   = expr.values
                      }
                    ]
                  }, {})
                )
              }, {})
            )
          }, {})
        )
      }, {})
    )
  }
  depends_on = [azapi_resource.custom_location, azapi_resource.instance]

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-07-01-preview until azapi provider supports it
}

resource "azapi_resource" "broker_authn" {
  type      = "Microsoft.IoTOperations/instances/brokers/authentications@2025-07-01-preview"
  name      = "default"
  parent_id = azapi_resource.broker.id
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.id
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

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-07-01-preview until azapi provider supports it
}

resource "azapi_resource" "broker_listener" {
  type      = "Microsoft.IoTOperations/instances/brokers/listeners@2025-07-01-preview"
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

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-07-01-preview until azapi provider supports it
}

resource "azapi_resource" "broker_listener_anonymous" {
  count = var.should_create_anonymous_broker_listener ? 1 : 0

  type      = "Microsoft.IoTOperations/instances/brokers/listeners@2025-07-01-preview"
  name      = "default-anon"
  parent_id = azapi_resource.broker.id
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.output.id
      type = "CustomLocation"
    }
    properties = {
      serviceType = "NodePort"
      serviceName = var.broker_listener_anonymous_config.serviceName
      ports = [
        {
          port     = var.broker_listener_anonymous_config.port
          nodePort = var.broker_listener_anonymous_config.nodePort
        }
      ]
    }
  }
  depends_on = [azapi_resource.custom_location, azapi_resource.broker, azapi_resource.broker_authn]

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-07-01-preview until azapi provider supports it
}

resource "azapi_resource" "data_profiles" {
  type      = "Microsoft.IoTOperations/instances/dataflowProfiles@2025-07-01-preview"
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

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-07-01-preview until azapi provider supports it
}

resource "azapi_resource" "data_endpoint" {
  type      = "Microsoft.IoTOperations/instances/dataflowEndpoints@2025-07-01-preview"
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

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-07-01-preview until azapi provider supports it
}

resource "azapi_resource" "default_aio_keyvault_secret_provider_class" {
  count = var.enable_instance_secret_sync ? 1 : 0

  type      = "Microsoft.SecretSyncController/azureKeyVaultSecretProviderClasses@2024-08-21-preview"
  name      = local.spc_name
  location  = var.connected_cluster_location
  parent_id = var.resource_group.id

  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.output.id
      type = "CustomLocation"
    }
    properties = {
      clientId     = var.secret_sync_identity.client_id
      keyvaultName = var.key_vault.name
      tenantId     = data.azurerm_subscription.current.tenant_id
    }
  }

  depends_on = [azapi_resource.custom_location]
}

resource "azapi_update_resource" "aio_instance_secret_sync_update" {
  count     = var.enable_instance_secret_sync ? 1 : 0
  type      = "Microsoft.IoTOperations/instances@2025-07-01-preview"
  name      = local.aio_instance_name
  parent_id = var.resource_group.id

  body = {
    properties = {
      defaultSecretProviderClassRef = {
        resourceId = azapi_resource.default_aio_keyvault_secret_provider_class[0].id
      }
    }
  }

  depends_on = [azapi_resource.default_aio_keyvault_secret_provider_class, azapi_resource.instance]
}
