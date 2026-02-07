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

run "test__aio_ca__error_with_missing_key" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test
    trust_config_source = "CustomerManagedGenerateIssuer"
    aio_ca = {
      root_ca_cert_pem  = "test"
      ca_cert_chain_pem = "test"
      ca_key_pem        = ""
    }
  }
  expect_failures = [var.aio_ca]
}

run "test__aio_ca__error_with_missing_cert_chain" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test
    trust_config_source = "CustomerManagedGenerateIssuer"
    aio_ca = {
      root_ca_cert_pem  = "test"
      ca_cert_chain_pem = ""
      ca_key_pem        = "test"
    }
  }
  expect_failures = [var.aio_ca]
}

run "test__aio_ca__error_with_missing_cert" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test
    trust_config_source = "CustomerManagedGenerateIssuer"
    aio_ca = {
      root_ca_cert_pem  = ""
      ca_cert_chain_pem = "test"
      ca_key_pem        = "test"
    }
  }
  expect_failures = [var.aio_ca]
}

run "test__aio_ca__error_with_incompatible_source" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test
    trust_config_source = "SelfSigned"
    aio_ca = {
      root_ca_cert_pem  = "test"
      ca_cert_chain_pem = "test"
      ca_key_pem        = "test"
    }
  }
  expect_failures = [var.aio_ca]
}

run "test_trust_config_error_with_invalid_source" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test
    trust_config_source = "InvalidSource"
  }
  expect_failures = [var.trust_config_source]
}

run "test_trust_config_byo_issuer_null_trust_and_platform_config_settings" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test
    trust_config_source       = "CustomerManagedByoIssuer"
    byo_issuer_trust_settings = null
  }
  expect_failures = [var.byo_issuer_trust_settings]
}

run "test_trust_config_should_pass_generated_issuer_without_extra_settings" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test
    trust_config_source = "CustomerManagedGenerateIssuer"
  }
}

run "test_trust_config_byo_issuer_error_issuer_settings_missing_name" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test
    trust_config_source = "CustomerManagedByoIssuer"

    byo_issuer_trust_settings = {
      issuer_name    = ""
      issuer_kind    = "test"
      configmap_name = "test"
      configmap_key  = "test"
    }
  }
  expect_failures = [var.byo_issuer_trust_settings]
}

run "test_trust_config_byo_issuer_error_issuer_settings_missing_kind" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test
    trust_config_source = "CustomerManagedByoIssuer"

    byo_issuer_trust_settings = {
      issuer_name    = "test"
      issuer_kind    = ""
      configmap_name = "test"
      configmap_key  = "test"
    }
  }
  expect_failures = [var.byo_issuer_trust_settings]
}

run "test_trust_config_byo_issuer_error_issuer_settings_missing_cm_name" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test
    trust_config_source = "CustomerManagedByoIssuer"

    byo_issuer_trust_settings = {
      issuer_name    = "test"
      issuer_kind    = "test"
      configmap_name = ""
      configmap_key  = "test"
    }
  }
  expect_failures = [var.byo_issuer_trust_settings]
}

run "test_trust_config_byo_issuer_error_issuer_settings_missing_cm_key" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test
    trust_config_source = "CustomerManagedByoIssuer"

    byo_issuer_trust_settings = {
      issuer_name    = "test"
      issuer_kind    = "test"
      configmap_name = "test"
      configmap_key  = ""
    }
  }
  expect_failures = [var.byo_issuer_trust_settings]
}

run "test_trust_config_generated_issuer_invalid_trust_settings" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test
    trust_config_source = "CustomerManagedGenerateIssuer"
    byo_issuer_trust_settings = {
      issuer_name    = "hello"
      issuer_kind    = "test"
      configmap_name = "test"
      configmap_key  = "test"
    }
  }
  expect_failures = [var.byo_issuer_trust_settings]
}

# Test cases for aio_features validation

run "test_aio_features_invalid_mode" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing invalid mode
    aio_features = {
      dataFlows = {
        mode = "Experimental" # Invalid mode - should be one of Stable, Preview, or Disabled
      }
    }
  }
  expect_failures = [var.aio_features]
}

run "test_aio_features_invalid_settings" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing invalid settings value
    aio_features = {
      mqttBroker = {
        settings = {
          preview = "On" # Invalid setting - should be one of Enabled or Disabled
        }
      }
    }
  }
  expect_failures = [var.aio_features]
}

run "test_aio_features_valid_configuration" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing valid configuration
    aio_features = {
      dataFlows = {
        mode = "Preview"
      },
      mqttBroker = {
        mode = "Stable",
        settings = {
          preview     = "Enabled",
          featureFlag = "Disabled"
        }
      },
      akri = {
        mode = "Disabled"
      }
    }
  }
  # This should pass validation
}

run "test_aio_features_with_null_properties" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing with null properties
    aio_features = {
      dataFlows = {
        mode = null
      },
      mqttBroker = {
        settings = null
      },
      akri = {}
    }
  }
  # This should pass validation
}

# Test cases for adr_namespace validation

run "test_adr_namespace_valid_configuration" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing valid ADR namespace configuration
  }
  # This should pass validation
}

run "test_adr_namespace_null_configuration" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = null

    # Variables under test - Testing null ADR namespace configuration
  }
  # This should pass validation - ADR namespace is optional
}

# Test cases for mqtt_broker_persistence_config validation

run "test_persistence_config_invalid_max_size" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing invalid max_size format
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "invalid-size"
    }
  }
  expect_failures = [var.mqtt_broker_persistence_config, var.mqtt_broker_persistence_config.max_size]
}

run "test_persistence_config_invalid_retain_policy_mode" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing invalid retain_policy mode
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "1G"
      retain_policy = {
        mode = "InvalidMode" # Should be All, None, or Custom
      }
    }
  }
  expect_failures = [var.mqtt_broker_persistence_config.retain_policy.mode]
}

run "test_persistence_config_invalid_key_type" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing invalid key_type
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "1G"
      state_store_policy = {
        mode = "Custom"
        custom_settings = {
          state_store_resources = [
            {
              key_type = "InvalidType" # Should be Pattern, String, or Binary
              keys     = ["test"]
            }
          ]
        }
      }
    }
  }
  expect_failures = [var.mqtt_broker_persistence_config]
}

run "test_persistence_config_invalid_access_mode" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing invalid access_modes
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "1G"
      persistent_volume_claim_spec = {
        access_modes = ["InvalidAccessMode"] # Should be valid Kubernetes access modes
      }
    }
  }
  expect_failures = [var.mqtt_broker_persistence_config]
}

run "test_persistence_config_invalid_volume_mode" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing invalid volume_mode
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "1G"
      persistent_volume_claim_spec = {
        volume_mode = "InvalidVolumeMode" # Should be Filesystem or Block
      }
    }
  }
  expect_failures = [var.mqtt_broker_persistence_config]
}

run "test_persistence_config_invalid_operator" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing invalid match expression operator
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "1G"
      persistent_volume_claim_spec = {
        selector = {
          match_expressions = [
            {
              key      = "test"
              operator = "InvalidOperator" # Should be In, NotIn, Exists, or DoesNotExist
              values   = ["test"]
            }
          ]
        }
      }
    }
  }
  expect_failures = [var.mqtt_broker_persistence_config]
}

run "test_persistence_config_valid_configuration" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing valid persistence configuration
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "10G"
      retain_policy = {
        mode = "Custom"
        custom_settings = {
          topics = ["sensor/#"]
        }
      }
      state_store_policy = {
        mode = "Custom"
        custom_settings = {
          state_store_resources = [
            {
              key_type = "Pattern"
              keys     = ["sensor/*"]
            }
          ]
        }
      }
      persistent_volume_claim_spec = {
        access_modes = ["ReadWriteOncePod"]
        volume_mode  = "Filesystem"
        selector = {
          match_expressions = [
            {
              key      = "environment"
              operator = "In"
              values   = ["production"]
            }
          ]
        }
      }
    }
  }
  # This should pass all validations
}

# Test cases for mqtt_broker_persistence_config validation

run "test_mqtt_broker_persistence_config_invalid_max_size" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing invalid max_size format
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "invalid-size"
    }
  }
  expect_failures = [var.mqtt_broker_persistence_config]
}

run "test_mqtt_broker_persistence_config_invalid_retain_policy_mode" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing invalid retain_policy mode
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "1G"
      retain_policy = {
        mode = "InvalidMode" # Should be "All", "None", or "Custom"
      }
    }
  }
  expect_failures = [var.mqtt_broker_persistence_config]
}

run "test_mqtt_broker_persistence_config_invalid_state_store_policy_mode" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing invalid state_store_policy mode
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "1G"
      state_store_policy = {
        mode = "InvalidMode" # Should be "All", "None", or "Custom"
      }
    }
  }
  expect_failures = [var.mqtt_broker_persistence_config]
}

run "test_mqtt_broker_persistence_config_invalid_subscriber_queue_policy_mode" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing invalid subscriber_queue_policy mode
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "1G"
      subscriber_queue_policy = {
        mode = "InvalidMode" # Should be "All", "None", or "Custom"
      }
    }
  }
  expect_failures = [var.mqtt_broker_persistence_config]
}

run "test_mqtt_broker_persistence_config_invalid_key_type" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing invalid key_type in state_store_resources
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "1G"
      state_store_policy = {
        mode = "Custom"
        custom_settings = {
          state_store_resources = [
            {
              key_type = "InvalidKeyType" # Should be "Pattern", "String", or "Binary"
              keys     = ["test"]
            }
          ]
        }
      }
    }
  }
  expect_failures = [var.mqtt_broker_persistence_config]
}

run "test_mqtt_broker_persistence_config_invalid_access_modes" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing invalid access_modes
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "1G"
      persistent_volume_claim_spec = {
        access_modes = ["InvalidAccessMode"] # Should be valid Kubernetes access modes
      }
    }
  }
  expect_failures = [var.mqtt_broker_persistence_config]
}

run "test_mqtt_broker_persistence_config_invalid_volume_mode" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing invalid volume_mode
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "1G"
      persistent_volume_claim_spec = {
        volume_mode = "InvalidMode" # Should be "Filesystem" or "Block"
      }
    }
  }
  expect_failures = [var.mqtt_broker_persistence_config]
}

run "test_mqtt_broker_persistence_config_invalid_selector_operator" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing invalid selector operator
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "1G"
      persistent_volume_claim_spec = {
        selector = {
          match_expressions = [
            {
              key      = "test"
              operator = "InvalidOperator" # Should be "In", "NotIn", "Exists", or "DoesNotExist"
              values   = ["test"]
            }
          ]
        }
      }
    }
  }
  expect_failures = [var.mqtt_broker_persistence_config]
}

run "test_mqtt_broker_persistence_config_valid_configuration" {
  command = plan
  variables {
    # Map the setup test outputs to the expected variable names
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    # Variables under test - Testing valid configuration
    mqtt_broker_persistence_config = {
      enabled  = true
      max_size = "10G" # Valid pattern
      retain_policy = {
        mode = "All" # Valid mode
      }
      state_store_policy = {
        mode = "Custom" # Valid mode
        custom_settings = {
          state_store_resources = [
            {
              key_type = "Pattern" # Valid key_type
              keys     = ["sensor/*"]
            }
          ]
        }
      }
      subscriber_queue_policy = {
        mode = "None" # Valid mode
      }
      persistent_volume_claim_spec = {
        access_modes = ["ReadWriteOncePod"] # Valid access mode
        volume_mode  = "Filesystem"         # Valid volume mode
        selector = {
          match_expressions = [
            {
              key      = "storage-type"
              operator = "In" # Valid operator
              values   = ["ssd"]
            }
          ]
        }
      }
    }
  }
  # This should pass validation
}

# Test custom Akri connector with invalid type
run "test__custom_akri_connectors__error_with_invalid_type" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    custom_akri_connectors = [
      {
        name = "test-connector"
        type = "invalid-type" # Invalid type
      }
    ]
  }
  expect_failures = [var.custom_akri_connectors]
}

# Test custom Akri connector missing required fields for custom type
run "test__custom_akri_connectors__error_with_missing_custom_fields" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    custom_akri_connectors = [
      {
        name = "test-connector"
        type = "custom"
        # Missing custom_endpoint_type and custom_image_name
      }
    ]
  }
  expect_failures = [var.custom_akri_connectors]
}

# Test custom Akri connector with invalid name format
run "test__custom_akri_connectors__error_with_invalid_name" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    custom_akri_connectors = [
      {
        name                 = "Test_Connector" # Invalid: contains uppercase and underscore
        type                 = "custom"
        custom_endpoint_type = "Contoso.Modbus"
        custom_image_name    = "my_acr.azurecr.io/modbus-connector"
      }
    ]
  }
  expect_failures = [var.custom_akri_connectors]
}

# Test custom Akri connector with invalid log level
run "test__custom_akri_connectors__error_with_invalid_log_level" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    custom_akri_connectors = [
      {
        name                 = "test-connector"
        type                 = "custom"
        custom_endpoint_type = "Contoso.Modbus"
        custom_image_name    = "my_acr.azurecr.io/modbus-connector"
        log_level            = "invalid" # Invalid log level
      }
    ]
  }
  expect_failures = [var.custom_akri_connectors]
}

# Test custom Akri connector with invalid replicas count
run "test__custom_akri_connectors__error_with_invalid_replicas" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    custom_akri_connectors = [
      {
        name                 = "test-connector"
        type                 = "custom"
        custom_endpoint_type = "Contoso.Modbus"
        custom_image_name    = "my_acr.azurecr.io/modbus-connector"
        replicas             = 15 # Invalid: exceeds maximum of 10
      }
    ]
  }
  expect_failures = [var.custom_akri_connectors]
}

# Test custom Akri connector with valid custom configuration
run "test__custom_akri_connectors__valid_custom_configuration" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    custom_akri_connectors = [
      {
        name                    = "modbus-telemetry-connector"
        type                    = "custom"
        custom_endpoint_type    = "Contoso.Modbus"
        custom_image_name       = "my_acr.azurecr.io/modbus-telemetry-connector"
        custom_endpoint_version = "2.0"
        registry                = "my_acr.azurecr.io"
        image_tag               = "latest"
        replicas                = 3
        log_level               = "debug"
      }
    ]
  }
  # This should pass validation
}

# Test cases for registry_endpoints validation

# Test registry endpoint with reserved name 'mcr'
run "test__registry_endpoints__error_with_reserved_name_mcr" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    registry_endpoints = [
      {
        name = "mcr" # Reserved name
        host = "custom.azurecr.io"
        authentication = {
          method = "SystemAssignedManagedIdentity"
        }
      }
    ]
  }
  expect_failures = [var.registry_endpoints]
}

# Test registry endpoint with reserved name 'default'
run "test__registry_endpoints__error_with_reserved_name_default" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    registry_endpoints = [
      {
        name = "default" # Reserved name
        host = "custom.azurecr.io"
        authentication = {
          method = "SystemAssignedManagedIdentity"
        }
      }
    ]
  }
  expect_failures = [var.registry_endpoints]
}

# Test registry endpoint with invalid name format (uppercase)
run "test__registry_endpoints__error_with_invalid_name_uppercase" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    registry_endpoints = [
      {
        name = "MyACR" # Invalid: contains uppercase
        host = "myacr.azurecr.io"
        authentication = {
          method = "SystemAssignedManagedIdentity"
        }
      }
    ]
  }
  expect_failures = [var.registry_endpoints]
}

# Test registry endpoint with invalid name format (too short)
run "test__registry_endpoints__error_with_invalid_name_too_short" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    registry_endpoints = [
      {
        name = "ab" # Invalid: less than 3 characters
        host = "myacr.azurecr.io"
        authentication = {
          method = "SystemAssignedManagedIdentity"
        }
      }
    ]
  }
  expect_failures = [var.registry_endpoints]
}

# Test registry endpoint with invalid authentication method
run "test__registry_endpoints__error_with_invalid_auth_method" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    registry_endpoints = [
      {
        name = "myacr"
        host = "myacr.azurecr.io"
        authentication = {
          method = "InvalidMethod" # Invalid authentication method
        }
      }
    ]
  }
  expect_failures = [var.registry_endpoints]
}

# Test registry endpoint with acr_resource_id on non-SystemAssignedManagedIdentity auth
run "test__registry_endpoints__error_with_acr_resource_id_wrong_auth" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    registry_endpoints = [
      {
        name            = "myacr"
        host            = "myacr.azurecr.io"
        acr_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerRegistry/registries/myacr"
        authentication = {
          method = "ArtifactPullSecret" # acr_resource_id requires SystemAssignedManagedIdentity
          artifact_pull_secret_settings = {
            secret_ref = "acr-creds"
          }
        }
      }
    ]
  }
  expect_failures = [var.registry_endpoints]
}

# Test registry endpoint with UserAssignedManagedIdentity missing required settings
run "test__registry_endpoints__error_with_uami_missing_settings" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    registry_endpoints = [
      {
        name = "myacr"
        host = "myacr.azurecr.io"
        authentication = {
          method = "UserAssignedManagedIdentity"
          # Missing required user_assigned_managed_identity_settings
        }
      }
    ]
  }
  expect_failures = [var.registry_endpoints]
}

# Test registry endpoint with ArtifactPullSecret missing required settings
run "test__registry_endpoints__error_with_artifact_secret_missing_settings" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    registry_endpoints = [
      {
        name = "myregistry"
        host = "myregistry.example.com"
        authentication = {
          method = "ArtifactPullSecret"
          # Missing required artifact_pull_secret_settings
        }
      }
    ]
  }
  expect_failures = [var.registry_endpoints]
}

# Test registry endpoint with valid SystemAssignedManagedIdentity and acr_resource_id
run "test__registry_endpoints__valid_with_acr_resource_id" {
  command = plan
  variables {
    resource_group        = run.setup_tests.aio_resource_group
    secret_sync_key_vault = run.setup_tests.sse_key_vault
    secret_sync_identity  = run.setup_tests.sse_user_assigned_identity
    aio_identity          = run.setup_tests.aio_user_assigned_identity
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
    adr_schema_registry   = run.setup_tests.adr_schema_registry
    adr_namespace         = run.setup_tests.adr_namespace

    registry_endpoints = [
      {
        name                           = "myacr"
        host                           = "myacr.azurecr.io"
        acr_resource_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerRegistry/registries/myacr"
        should_assign_acr_pull_for_aio = true
        authentication = {
          method = "SystemAssignedManagedIdentity"
        }
      }
    ]
  }
  # This should pass validation
}
