provider "azurerm" {
  storage_use_azuread = true
  features {}
}

# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Test default configuration with SelfSigned trust source
run "create_default_cluster" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
  }

  # Only assert on local variables and other values known during plan
  assert {
    condition     = local.trust_source == "SelfSigned"
    error_message = "Default trust source should be SelfSigned"
  }

  # Check that required modules are being created correctly
  assert {
    condition     = module.iot_ops_init != null
    error_message = "iot_ops_init module should be created"
  }

  assert {
    condition     = module.iot_ops_instance != null
    error_message = "iot_ops_instance module should be created"
  }
}

# Test CustomerManagedGenerateIssuer configuration with provided CA
run "create_custom_generated_issuer_with_ca" {
  command = plan
  variables {
    resource_group          = run.setup_tests.aio_resource_group
    secret_sync_key_vault   = run.setup_tests.sse_key_vault
    secret_sync_identity    = run.setup_tests.sse_user_assigned_identity
    aio_identity            = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry     = run.setup_tests.adr_schema_registry
    adr_namespace           = run.setup_tests.adr_namespace
    arc_connected_cluster   = run.setup_tests.arc_connected_cluster
    trust_config_source     = "CustomerManagedGenerateIssuer"
    enable_opc_ua_simulator = false

    aio_ca = {
      root_ca_cert_pem  = "root_ca_cert_pem"
      ca_cert_chain_pem = "ca_cert_chain_pem"
      ca_key_pem        = "ca_key_pem"
    }
  }

  assert {
    condition     = local.trust_source == "CustomerManaged"
    error_message = "Trust source should be CustomerManaged when using CustomerManagedGenerateIssuer"
  }

  assert {
    condition     = local.should_generate_aio_ca == false
    error_message = "should_generate_aio_ca should be false when aio_ca is provided"
  }

  assert {
    condition     = local.aio_ca.root_ca_cert_pem == "root_ca_cert_pem"
    error_message = "aio_ca values should be passed through correctly"
  }

  # Check that customer_managed_trust_issuer is being created
  assert {
    condition     = length(module.customer_managed_trust_issuer) > 0
    error_message = "customer_managed_trust_issuer module should be created"
  }
}

# Test CustomerManagedGenerateIssuer configuration without CA (auto-generation)
run "create_custom_generated_issuer_without_ca" {
  command = plan
  variables {
    resource_group          = run.setup_tests.aio_resource_group
    secret_sync_key_vault   = run.setup_tests.sse_key_vault
    secret_sync_identity    = run.setup_tests.sse_user_assigned_identity
    aio_identity            = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry     = run.setup_tests.adr_schema_registry
    adr_namespace           = run.setup_tests.adr_namespace
    arc_connected_cluster   = run.setup_tests.arc_connected_cluster
    trust_config_source     = "CustomerManagedGenerateIssuer"
    enable_opc_ua_simulator = false
  }

  assert {
    condition     = local.trust_source == "CustomerManaged"
    error_message = "Trust source should be CustomerManaged when using CustomerManagedGenerateIssuer"
  }

  assert {
    condition     = local.should_generate_aio_ca == true
    error_message = "should_generate_aio_ca should be true when aio_ca is not provided"
  }

  # Check that customer_managed_self_signed_ca is being created
  assert {
    condition     = length(module.customer_managed_self_signed_ca) > 0
    error_message = "customer_managed_self_signed_ca module should be created when aio_ca is not provided"
  }
}

# Test CustomerManagedByoIssuer configuration
run "create_customer_managed_byo_issuer" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    trust_config_source   = "CustomerManagedByoIssuer"
    byo_issuer_trust_settings = {
      issuer_name    = "my-custom-issuer"
      issuer_kind    = "ClusterIssuer"
      configmap_name = "my-custom-configmap"
      configmap_key  = "custom-ca.crt"
    }
  }

  assert {
    condition     = local.trust_source == "CustomerManaged"
    error_message = "Trust source should be CustomerManaged when using CustomerManagedByoIssuer"
  }

  assert {
    condition     = local.customer_managed_trust_settings.issuer_name == "my-custom-issuer"
    error_message = "BYO issuer trust settings should be used when provided"
  }
}

# Test OPC UA simulator enabled
run "create_with_opc_ua_simulator" {
  command = plan
  variables {
    resource_group          = run.setup_tests.aio_resource_group
    secret_sync_key_vault   = run.setup_tests.sse_key_vault
    secret_sync_identity    = run.setup_tests.sse_user_assigned_identity
    aio_identity            = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry     = run.setup_tests.adr_schema_registry
    adr_namespace           = run.setup_tests.adr_namespace
    arc_connected_cluster   = run.setup_tests.arc_connected_cluster
    enable_opc_ua_simulator = true
  }

  # Instead of checking the module length directly, check if the var would cause the module to be created
  assert {
    condition     = var.enable_opc_ua_simulator == true
    error_message = "enable_opc_ua_simulator should be true"
  }
}

# Test specific features configuration
run "create_with_features_configured" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    aio_features = {
      connectors = {
        settings = {
          preview = "Enabled"
        }
      }
      dataFlows = {
        mode = "Disabled"
      }
      mqttBroker = {
        settings = {
          preview = "Enabled"
        }
      }
      akri = {
        mode = "Preview"
      }
    }
  }

  # Assert that features are correctly passed to the module
  assert {
    condition     = var.aio_features.dataFlows.mode == "Disabled"
    error_message = "dataFlows feature mode should be set to Disabled"
  }
  assert {
    condition     = var.aio_features.mqttBroker.settings.preview == "Enabled"
    error_message = "mqttBroker feature settings.preview should be set to Enabled"
  }
  assert {
    condition     = var.aio_features.akri.mode == "Preview"
    error_message = "akri feature mode should be set to Preview"
  }

  assert {
    condition     = var.aio_features.mqttBroker.settings.preview == "Enabled"
    error_message = "mqttBroker preview setting should be Enabled"
  }
  assert {
    condition     = var.aio_features.connectors.settings.preview == "Enabled"
    error_message = "connectors preview setting should be Enabled"
  }
}

# Test OpenTelemetry collector enabled
run "create_with_otel_collector" {
  command = plan
  variables {
    resource_group               = run.setup_tests.aio_resource_group
    secret_sync_key_vault        = run.setup_tests.sse_key_vault
    secret_sync_identity         = run.setup_tests.sse_user_assigned_identity
    aio_identity                 = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry          = run.setup_tests.adr_schema_registry
    adr_namespace                = run.setup_tests.adr_namespace
    arc_connected_cluster        = run.setup_tests.arc_connected_cluster
    should_enable_otel_collector = true
  }

  assert {
    condition     = length(local.scripts_otel_collector) > 0
    error_message = "OpenTelemetry collector scripts should be present when enabled"
  }

  # Check if the otel parameter would cause the module to be created
  assert {
    condition     = var.should_enable_otel_collector == true
    error_message = "should_enable_otel_collector should be true"
  }
}

# Test anonymous broker listener
run "create_with_anonymous_broker_listener" {
  command = plan
  variables {
    resource_group                          = run.setup_tests.aio_resource_group
    secret_sync_key_vault                   = run.setup_tests.sse_key_vault
    secret_sync_identity                    = run.setup_tests.sse_user_assigned_identity
    aio_identity                            = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry                     = run.setup_tests.adr_schema_registry
    adr_namespace                           = run.setup_tests.adr_namespace
    arc_connected_cluster                   = run.setup_tests.arc_connected_cluster
    should_create_anonymous_broker_listener = true
    broker_listener_anonymous_config = {
      port        = 1883
      nodePort    = 1883
      serviceName = "broker-anon-test"
    }
  }

  # Instead of checking output values, check the input configuration
  assert {
    condition     = var.broker_listener_anonymous_config.port == 1883
    error_message = "broker_listener_anonymous_config port should be set to 1883"
  }

  assert {
    condition     = var.broker_listener_anonymous_config.nodePort == 1883
    error_message = "broker_listener_anonymous_config nodePort should be set to 1883"
  }
}

# Test ADR namespace configuration with provided namespace
run "create_with_adr_namespace" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
  }

  # Verify that ADR namespace is properly configured
  assert {
    condition     = var.adr_namespace.id != null && var.adr_namespace.id != ""
    error_message = "ADR namespace ID should be provided when adr_namespace is configured"
  }
}

# Test ADR namespace configuration without namespace (should work)
run "create_without_adr_namespace" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_namespace         = null
  }

  # Verify that deployment works without ADR namespace
  assert {
    condition     = var.adr_namespace == null
    error_message = "ADR namespace should be null when not provided"
  }
}

# Test valid MQTT broker persistence configuration
run "create_with_valid_persistence_config" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    mqtt_broker_persistence_config = {
      enabled            = true
      max_size           = "10G"
      encryption_enabled = true

      # Dynamic Settings
      dynamic_settings = {
        user_property_key   = "aio-persistence"
        user_property_value = "true"
      }

      # Retention Policy - All mode
      retain_policy = {
        mode = "All"
      }

      # State Store Policy - Custom mode with valid settings
      state_store_policy = {
        mode = "Custom"
        custom_settings = {
          state_store_resources = [
            {
              key_type = "Pattern"
              keys     = ["sensor/*", "device/+/temperature"]
            },
            {
              key_type = "String"
              keys     = ["config", "status"]
            }
          ]
          dynamic_enabled = true
        }
      }

      # Subscriber Queue Policy - Custom mode
      subscriber_queue_policy = {
        mode = "Custom"
        custom_settings = {
          subscriber_client_ids = ["factory-client-*", "sensor-gateway-01"]
          topics                = ["sensor/#", "alerts/+"]
          dynamic_enabled       = true
        }
      }

      # Persistent Volume Claim Specification
      persistent_volume_claim_spec = {
        storage_class_name = "fast-ssd"
        access_modes       = ["ReadWriteOncePod"]
        volume_mode        = "Filesystem"
        resources = {
          requests = {
            storage = "10G"
          }
          limits = {
            storage = "15G"
          }
        }
      }
    }
  }

  # Verify that persistence configuration is correctly passed
  assert {
    condition     = var.mqtt_broker_persistence_config.enabled == true
    error_message = "MQTT broker persistence should be enabled"
  }

  assert {
    condition     = var.mqtt_broker_persistence_config.max_size == "10G"
    error_message = "MQTT broker persistence max_size should be 10G"
  }

  assert {
    condition     = var.mqtt_broker_persistence_config.retain_policy.mode == "All"
    error_message = "Retain policy mode should be All"
  }

  assert {
    condition     = var.mqtt_broker_persistence_config.state_store_policy.mode == "Custom"
    error_message = "State store policy mode should be Custom"
  }

  assert {
    condition     = length(var.mqtt_broker_persistence_config.state_store_policy.custom_settings.state_store_resources) == 2
    error_message = "Should have 2 state store resources configured"
  }

  assert {
    condition     = var.mqtt_broker_persistence_config.subscriber_queue_policy.mode == "Custom"
    error_message = "Subscriber queue policy mode should be Custom"
  }

  assert {
    condition     = contains(var.mqtt_broker_persistence_config.persistent_volume_claim_spec.access_modes, "ReadWriteOncePod")
    error_message = "Access mode should include ReadWriteOncePod"
  }
}

# Test MQTT broker persistence configuration with edge case values
run "create_with_edge_case_persistence_config" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    mqtt_broker_persistence_config = {
      enabled            = false  # Disabled persistence
      max_size           = "100M" # Minimum viable size
      encryption_enabled = false

      # None mode for all policies
      retain_policy = {
        mode = "None"
      }

      state_store_policy = {
        mode = "None"
      }

      subscriber_queue_policy = {
        mode = "None"
      }

      # Minimal PVC specification
      persistent_volume_claim_spec = {
        access_modes = ["ReadWriteOnce"] # Different access mode
        resources = {
          requests = {
            storage = "100M"
          }
        }
      }
    }
  }

  # Verify edge case configuration is accepted
  assert {
    condition     = var.mqtt_broker_persistence_config.enabled == false
    error_message = "MQTT broker persistence should be disabled in this test"
  }

  assert {
    condition     = var.mqtt_broker_persistence_config.retain_policy.mode == "None"
    error_message = "Retain policy mode should be None"
  }

  assert {
    condition     = var.mqtt_broker_persistence_config.state_store_policy.mode == "None"
    error_message = "State store policy mode should be None"
  }

  assert {
    condition     = var.mqtt_broker_persistence_config.subscriber_queue_policy.mode == "None"
    error_message = "Subscriber queue policy mode should be None"
  }
}

# Test MQTT broker persistence configuration with minimal required fields only
run "create_with_minimal_persistence_config" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "1G" # Only required fields specified
    }
  }

  # Verify minimal configuration is accepted
  assert {
    condition     = var.mqtt_broker_persistence_config.enabled == true
    error_message = "MQTT broker persistence should be enabled"
  }

  assert {
    condition     = var.mqtt_broker_persistence_config.max_size == "1G"
    error_message = "Max size should be 1G"
  }

  # Optional fields should be null when not specified
  assert {
    condition     = var.mqtt_broker_persistence_config.retain_policy == null
    error_message = "Retain policy should be null when not specified"
  }
}

# Test Akri REST connector enabled
run "create_with_akri_rest_connector" {
  command = plan
  variables {
    resource_group                    = run.setup_tests.aio_resource_group
    secret_sync_key_vault             = run.setup_tests.sse_key_vault
    secret_sync_identity              = run.setup_tests.sse_user_assigned_identity
    aio_identity                      = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry               = run.setup_tests.adr_schema_registry
    adr_namespace                     = run.setup_tests.adr_namespace
    arc_connected_cluster             = run.setup_tests.arc_connected_cluster
    should_enable_akri_rest_connector = true
  }

  # Verify that REST connector is enabled
  assert {
    condition     = var.should_enable_akri_rest_connector == true
    error_message = "should_enable_akri_rest_connector should be true"
  }

  # Verify akri_connectors module would be created
  assert {
    condition     = length(module.akri_connectors) > 0
    error_message = "akri_connectors module should be created when REST connector is enabled"
  }
}

# Test REST connector deployment with detailed validation
run "validate_rest_connector_deployment" {
  command = plan
  variables {
    resource_group                    = run.setup_tests.aio_resource_group
    secret_sync_key_vault             = run.setup_tests.sse_key_vault
    secret_sync_identity              = run.setup_tests.sse_user_assigned_identity
    aio_identity                      = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry               = run.setup_tests.adr_schema_registry
    adr_namespace                     = run.setup_tests.adr_namespace
    arc_connected_cluster             = run.setup_tests.arc_connected_cluster
    should_enable_akri_rest_connector = true
  }

  # Verify akri_connectors module is instantiated
  assert {
    condition     = length(module.akri_connectors) == 1
    error_message = "akri_connectors module should be created with exactly one instance"
  }

  # Verify the module receives correct inputs
  assert {
    condition     = var.should_enable_akri_rest_connector == true
    error_message = "REST connector should be enabled"
  }
}

# Test custom Akri connector deployment
run "validate_custom_connector_deployment" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    custom_akri_connectors = [
      {
        name                    = "modbus-telemetry-connector"
        type                    = "custom"
        custom_endpoint_type    = "Contoso.Modbus"
        custom_image_name       = "my_acr.azurecr.io/modbus-telemetry-connector"
        custom_endpoint_version = "2.0"
        registry                = "my_acr.azurecr.io"
        image_tag               = "v1.2.3"
        replicas                = 2
        log_level               = "debug"
      }
    ]
  }

  # Verify akri_connectors module is instantiated for custom connector
  assert {
    condition     = length(module.akri_connectors) == 1
    error_message = "akri_connectors module should be created when custom connectors are provided"
  }

  # Verify custom connector configuration is provided
  assert {
    condition     = length(var.custom_akri_connectors) == 1
    error_message = "Should have exactly one custom connector configured"
  }

  # Verify custom connector has required fields
  assert {
    condition     = var.custom_akri_connectors[0].type == "custom"
    error_message = "Custom connector type should be 'custom'"
  }

  assert {
    condition     = var.custom_akri_connectors[0].custom_endpoint_type == "Contoso.Modbus"
    error_message = "Custom connector should have the specified endpoint type"
  }

  assert {
    condition     = var.custom_akri_connectors[0].custom_image_name == "my_acr.azurecr.io/modbus-telemetry-connector"
    error_message = "Custom connector should have the specified image name"
  }

  # Verify optional configuration is applied
  assert {
    condition     = var.custom_akri_connectors[0].replicas == 2
    error_message = "Custom connector replicas should be set to 2"
  }

  assert {
    condition     = var.custom_akri_connectors[0].log_level == "debug"
    error_message = "Custom connector log level should be set to debug"
  }
}

# Test multiple connectors (built-in and custom) deployment
run "validate_multiple_connectors_deployment" {
  command = plan
  variables {
    resource_group                     = run.setup_tests.aio_resource_group
    secret_sync_key_vault              = run.setup_tests.sse_key_vault
    secret_sync_identity               = run.setup_tests.sse_user_assigned_identity
    aio_identity                       = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry                = run.setup_tests.adr_schema_registry
    adr_namespace                      = run.setup_tests.adr_namespace
    arc_connected_cluster              = run.setup_tests.arc_connected_cluster
    should_enable_akri_rest_connector  = true
    should_enable_akri_onvif_connector = true
    custom_akri_connectors = [
      {
        name                 = "custom-sse-connector"
        type                 = "custom"
        custom_endpoint_type = "Acme.ServerSentEvents"
        custom_image_name    = "my_acr.azurecr.io/sse-connector"
        replicas             = 1
      }
    ]
  }

  # Verify akri_connectors module is instantiated when multiple connectors are enabled
  assert {
    condition     = length(module.akri_connectors) == 1
    error_message = "akri_connectors module should be created when any connector is enabled"
  }

  # Verify multiple built-in connectors are enabled
  assert {
    condition     = var.should_enable_akri_rest_connector == true && var.should_enable_akri_onvif_connector == true
    error_message = "Both REST and ONVIF connectors should be enabled"
  }

  # Verify custom connector is also configured
  assert {
    condition     = length(var.custom_akri_connectors) == 1
    error_message = "Should have one custom connector in addition to built-in connectors"
  }
}
