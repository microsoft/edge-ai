/**
 * # MQTT Configuration Module
 *
 * This module creates MQTT broker listeners, endpoints, and dataflows using the azapi provider.
 * It handles the deployment of MQTT configuration resources for both enterprise and site clusters.
 * Uses existing AIO instance and dataflow profile outputs from the IoT Operations module.
 */

// Data source for enterprise broker (still needed as it's not exposed as output)
data "azapi_resource" "enterprise_aio_broker" {
  type      = "Microsoft.IoTOperations/instances/brokers@2025-04-01"
  name      = "broker"
  parent_id = var.enterprise_aio_instance.id
}

// Site MQTT Endpoint
resource "azapi_resource" "site_mqtt_endpoint" {
  type      = "Microsoft.IoTOperations/instances/dataflowEndpoints@2025-04-01"
  name      = "mqtt-local"
  parent_id = var.site_aio_instance.id

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.site_custom_locations.id
    }
    properties = {
      endpointType = "Mqtt"
      mqttSettings = {
        authentication = {
          method = "Anonymous"
        }
        clientIdPrefix       = "local-mqtt-client"
        cloudEventAttributes = "Propagate"
        host                 = "aio-broker:18883"
        keepAliveSeconds     = 60
        maxInflightMessages  = 100
        protocol             = "Mqtt"
        qos                  = 1
        retain               = "Keep"
        sessionExpirySeconds = 3600
        tls = {
          mode                          = "Enabled"
          trustedCaCertificateConfigMap = "azure-iot-operations-aio-ca-trust-bundle"
        }
      }
    }
  }

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-04-01 until azapi provider supports it
}

// Enterprise MQTT Endpoint with Certificate Authentication
resource "azapi_resource" "enterprise_mqtt_endpoint_cert_auth" {
  type      = "Microsoft.IoTOperations/instances/dataflowEndpoints@2025-04-01"
  name      = "mqtt-cert-auth"
  parent_id = var.site_aio_instance.id

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.site_custom_locations.id
    }
    properties = {
      endpointType = "Mqtt"
      mqttSettings = {
        authentication = {
          method = "X509Certificate"
          x509CertificateSettings = {
            secretRef = var.site_client_secret_name
          }
        }
        clientIdPrefix       = "client-cert-auth"
        cloudEventAttributes = "Propagate"
        host                 = "${var.enterprise_vm_private_ip}:${var.enterprise_broker_port}"
        keepAliveSeconds     = 60
        maxInflightMessages  = 100
        protocol             = "Mqtt"
        qos                  = 1
        retain               = "Keep"
        sessionExpirySeconds = 3600
        tls = {
          mode                          = "Enabled"
          trustedCaCertificateConfigMap = var.site_tls_ca_configmap_name
        }
      }
    }
  }

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-04-01 until azapi provider supports it
}

// Enterprise Site Route with Certificate Authentication
resource "azapi_resource" "site_enterprise_route_cert_auth" {
  type      = "Microsoft.IoTOperations/instances/dataflowProfiles/dataflows@2025-04-01"
  name      = "site-to-enterprise-cert-auth"
  parent_id = var.site_aio_dataflow_profile.id

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.site_custom_locations.id
    }
    properties = {
      mode = "Enabled"
      operations = [
        {
          operationType = "Source"
          sourceSettings = {
            dataSources         = ["input"]
            endpointRef         = "mqtt-local"
            serializationFormat = "Json"
          }
        },
        {
          operationType = "BuiltInTransformation"
          builtInTransformationSettings = {
            datasets = []
            filter   = []
            map = [
              {
                inputs = ["*"]
                output = "*"
                type   = "PassThrough"
              }
            ]
            serializationFormat = "Json"
          }
        },
        {
          operationType = "Destination"
          destinationSettings = {
            dataDestination = "output"
            endpointRef     = azapi_resource.enterprise_mqtt_endpoint_cert_auth.name
          }
        }
      ]
    }
  }

  depends_on                = [azapi_resource.enterprise_mqtt_endpoint_cert_auth]
  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-04-01 until azapi provider supports it
}

// Enterprise MQTT Broker Authentication
resource "azapi_resource" "enterprise_mqtt_broker_authentication" {
  type      = "Microsoft.IoTOperations/instances/brokers/authentications@2025-04-01"
  name      = "default"
  parent_id = data.azapi_resource.enterprise_aio_broker.id

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.enterprise_custom_locations.id
    }
    properties = {
      authenticationMethods = [
        {
          method = "ServiceAccountToken"
          serviceAccountTokenSettings = {
            audiences = ["aio-internal"]
          }
        },
        {
          method = "X509"
          x509Settings = {
            trustedClientCaCert = var.enterprise_client_ca_configmap_name
          }
        }
      ]
    }
  }

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-04-01 until azapi provider supports it
}

// Enterprise MQTT Broker Listener
resource "azapi_resource" "enterprise_mqtt_broker_listener" {
  type      = "Microsoft.IoTOperations/instances/brokers/listeners@2025-04-01"
  name      = "default-loadbalancer"
  parent_id = data.azapi_resource.enterprise_aio_broker.id

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.enterprise_custom_locations.id
    }
    properties = {
      brokerRef = "broker"
      ports = [
        {
          port              = var.enterprise_broker_port
          protocol          = "Mqtt"
          authenticationRef = "default"
          tls = {
            mode = "Manual"
            manual = {
              secretRef = var.enterprise_broker_tls_cert_secret_name
            }
          }
        }
      ]
      serviceName = "aio-broker"
      serviceType = "LoadBalancer"
    }
  }

  depends_on                = [azapi_resource.enterprise_mqtt_broker_authentication]
  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2025-04-01 until azapi provider supports it
}
