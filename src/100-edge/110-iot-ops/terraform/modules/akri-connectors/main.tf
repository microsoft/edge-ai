/**
 * # Akri Connectors Module
 *
 * Deploys multiple Azure IoT Operations Akri Connector Templates as part of
 * the IoT Operations deployment. Supports REST/HTTP, Media, ONVIF, and SSE
 * connector types with configurable runtime and MQTT settings.
 */

locals {
  // Connector type metadata mapping for built-in Microsoft connectors
  connector_type_metadata = {
    rest = {
      endpoint_type       = "Microsoft.Http"
      image_name          = "azureiotoperations/akri-connectors/rest"
      version             = "1.0"
      default_tag         = "1.0.6"
      default_registry    = "mcr.microsoft.com"
      default_min_version = "1.2.37"
    }
    media = {
      endpoint_type       = "Microsoft.Media"
      image_name          = "azureiotoperations/akri-connectors/media"
      version             = "1.0"
      default_tag         = "1.2.39"
      default_registry    = "mcr.microsoft.com"
      default_min_version = "1.2.37"
    }
    onvif = {
      endpoint_type       = "Microsoft.Onvif"
      image_name          = "azureiotoperations/akri-connectors/onvif"
      version             = "1.0"
      default_tag         = "1.2.39"
      default_registry    = "mcr.microsoft.com"
      default_min_version = "1.2.37"
    }
    sse = {
      endpoint_type       = "Microsoft.Sse"
      image_name          = "azureiotoperations/akri-connectors/sse"
      version             = "1.0"
      default_tag         = "1.0.5"
      default_registry    = "mcr.microsoft.com"
      default_min_version = "1.2.37"
    }
  }

  // Process connector configurations with defaults
  processed_connectors = {
    for conn in var.connector_templates : conn.name => {
      name      = conn.name
      type      = conn.type
      is_custom = conn.type == "custom"

      // Use custom metadata if provided, otherwise use built-in metadata
      endpoint_type    = conn.type == "custom" ? conn.custom_endpoint_type : local.connector_type_metadata[conn.type].endpoint_type
      endpoint_version = conn.type == "custom" ? coalesce(conn.custom_endpoint_version, "1.0") : local.connector_type_metadata[conn.type].version
      image_name       = conn.type == "custom" ? conn.custom_image_name : local.connector_type_metadata[conn.type].image_name

      // Registry and image defaults with connector-specific fallbacks
      registry                 = coalesce(conn.registry, conn.type != "custom" ? local.connector_type_metadata[conn.type].default_registry : "mcr.microsoft.com")
      image_tag                = coalesce(conn.image_tag, conn.type != "custom" ? local.connector_type_metadata[conn.type].default_tag : "latest")
      replicas                 = coalesce(conn.replicas, 1)
      image_pull_policy        = coalesce(conn.image_pull_policy, "IfNotPresent")
      log_level                = lower(coalesce(conn.log_level, "info"))
      aio_min_version          = coalesce(conn.aio_min_version, conn.type != "custom" ? local.connector_type_metadata[conn.type].default_min_version : null)
      aio_max_version          = conn.aio_max_version
      allocation               = conn.allocation
      additional_configuration = conn.additional_configuration
      secrets                  = conn.secrets
      trust_settings           = conn.trust_settings

      // Build connector metadata reference dynamically
      connector_metadata_ref = conn.type == "custom" && conn.custom_connector_metadata_ref != null ? (
        conn.custom_connector_metadata_ref
        ) : (
        "${coalesce(conn.registry, conn.type != "custom" ? local.connector_type_metadata[conn.type].default_registry : "mcr.microsoft.com")}/${conn.type == "custom" ? conn.custom_image_name : local.connector_type_metadata[conn.type].image_name}-metadata:${coalesce(conn.image_tag, conn.type != "custom" ? local.connector_type_metadata[conn.type].default_tag : "latest")}"
      )

      // MQTT config - use connector-specific or fallback to shared
      mqtt_config = try(conn.mqtt_config, null) != null ? conn.mqtt_config : var.mqtt_shared_config
    }
  }

}

/*
 * Connector Template Resources
 */

resource "azapi_resource" "connector_template" {
  for_each = local.processed_connectors

  type      = "Microsoft.IoTOperations/instances/akriConnectorTemplates@2025-10-01"
  name      = each.value.name
  parent_id = var.aio_instance_id

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = merge(
      {
        connectorMetadataRef = each.value.connector_metadata_ref
        deviceInboundEndpointTypes = [
          {
            endpointType = each.value.endpoint_type
            version      = each.value.endpoint_version
          }
        ]
        runtimeConfiguration = {
          runtimeConfigurationType = "ManagedConfiguration"
          managedConfigurationSettings = merge(
            {
              managedConfigurationType = "ImageConfiguration"
              imageConfigurationSettings = {
                registrySettings = {
                  registrySettingsType = "ContainerRegistry"
                  containerRegistrySettings = {
                    registry = each.value.registry
                  }
                }
                imageName       = each.value.image_name
                imagePullPolicy = each.value.image_pull_policy
                replicas        = each.value.replicas
                tagDigestSettings = {
                  tagDigestType = "Tag"
                  tag           = each.value.image_tag
                }
              }
            },
            each.value.allocation != null ? { allocation = each.value.allocation } : {},
            each.value.additional_configuration != null ? { additionalConfiguration = each.value.additional_configuration } : {},
            each.value.secrets != null ? { secrets = each.value.secrets } : {},
            each.value.trust_settings != null ? { trustSettings = each.value.trust_settings } : {}
          )
        }
        mqttConnectionConfiguration = {
          host = each.value.mqtt_config.host
          authentication = {
            method = "ServiceAccountToken"
            serviceAccountTokenSettings = {
              audience = each.value.mqtt_config.audience
            }
          }
          keepAliveSeconds     = coalesce(each.value.mqtt_config.keep_alive_seconds, 60)
          maxInflightMessages  = coalesce(each.value.mqtt_config.max_inflight_messages, 100)
          protocol             = "Mqtt"
          sessionExpirySeconds = coalesce(each.value.mqtt_config.session_expiry_seconds, 600)
          tls = {
            mode                             = "Enabled"
            trustedCaCertificateConfigMapRef = each.value.mqtt_config.ca_configmap
          }
        }
        diagnostics = {
          logs = {
            level = each.value.log_level
          }
        }
      },
      each.value.aio_min_version != null || each.value.aio_max_version != null ? {
        aioMetadata = {
          aioMinVersion = each.value.aio_min_version
          aioMaxVersion = each.value.aio_max_version
        }
      } : {}
    )
  }

  response_export_values    = ["name", "id"]
  schema_validation_enabled = false
}
