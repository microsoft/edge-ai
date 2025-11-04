/**
 * # Akri REST HTTP Connector Module
 *
 * This module deploys the Azure IoT Operations Akri REST HTTP Connector Template
 * as part of the IoT Operations deployment. The connector template enables discovery
 * and management of REST/HTTP endpoints as assets and supports multiple authentication
 * methods with routing to MQTT broker and state store destinations.
 *
 * This module is integrated into the IoT Operations component to provide unified
 * deployment and configuration of both core IoT Operations and REST connectivity.
 */

locals {
  # Processed connector template configuration with defaults
  connector_config = merge(
    {
      template_name        = "rest-http-connector"
      image_tag            = "latest"
      log_level            = "Info"
      replicas             = 1
      mqtt_broker_host     = "aio-mq-dmqtt-frontend:8883"
      mqtt_broker_audience = "aio-mq"
      mqtt_ca_configmap    = "aio-ca-trust-bundle-test-only"
    },
    var.akri_rest_connector_config
  )

  # Common metadata for ARM resources
  common_metadata = {
    "deployment.environment" = var.environment
    "deployment.location"    = var.location
    "deployment.prefix"      = var.resource_prefix
    "managed-by"             = "terraform"
    "component"              = "akri-rest-http-connector"
  }
}

# REST Connector Template using ARM resources
resource "azapi_resource" "connector_template" {
  type      = "Microsoft.IoTOperations/instances/akriConnectorTemplates@2025-07-01-preview"
  name      = local.connector_config.template_name
  parent_id = var.aio_instance_id

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = {
      version = "1.0"
      aioMetadata = {
        aioMaxVersion = "3.0"
        aioMinVersion = "0.0"
      }
      diagnostics = {
        logs = {
          level = local.connector_config.log_level
        }
      }
      deviceInboundEndpointTypes = [
        {
          endpointType = "Microsoft.Http"
          version      = "1.0"
        }
      ]
      runtimeConfiguration = {
        runtimeConfigurationType = "managedConfiguration"
        managedConfigurationSettings = {
          managedConfigurationType = "imageConfiguration"
          imageConfigurationSettings = {
            registrySettings = {
              registrySettingsType = "containerRegistry"
              containerRegistrySettings = {
                registry = "mcr.microsoft.com"
              }
            }
            imageName       = "azureiotoperations/akri-connectors/rest"
            imagePullPolicy = "Always"
            replicas        = local.connector_config.replicas
            tagDigestSettings = {
              tagDigestType = "tag"
              tag           = local.connector_config.image_tag
            }
          }
        }
      }
      mqttConnectionConfiguration = {
        host = local.connector_config.mqtt_broker_host
        authentication = {
          method = "ServiceAccountToken"
          serviceAccountTokenSettings = {
            audience = local.connector_config.mqtt_broker_audience
          }
        }
        keepAliveSeconds     = 60
        maxInflightMessages  = 100
        protocol             = "Mqtt"
        sessionExpirySeconds = 600
        tls = {
          mode                             = "Enabled"
          trustedCaCertificateConfigMapRef = local.connector_config.mqtt_ca_configmap
        }
      }
    }
  }

  response_export_values    = ["name", "id"]
  schema_validation_enabled = false # Disable schema validation for 2025-04-01 until azapi provider supports it

  tags = local.common_metadata
}
