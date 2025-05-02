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

    # Variables under test
    trust_config_source       = "CustomerManagedByoIssuer"
    byo_issuer_trust_settings = null

    aio_platform_config = {
      install_cert_manager  = true
      install_trust_manager = true
    }
  }
  expect_failures = [var.byo_issuer_trust_settings, var.aio_platform_config]
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

    # Variables under test
    trust_config_source = "CustomerManagedByoIssuer"

    byo_issuer_trust_settings = {
      issuer_name    = ""
      issuer_kind    = "test"
      configmap_name = "test"
      configmap_key  = "test"
    }

    aio_platform_config = {
      install_cert_manager  = false
      install_trust_manager = false
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

    # Variables under test
    trust_config_source = "CustomerManagedByoIssuer"

    byo_issuer_trust_settings = {
      issuer_name    = "test"
      issuer_kind    = ""
      configmap_name = "test"
      configmap_key  = "test"
    }

    aio_platform_config = {
      install_cert_manager  = false
      install_trust_manager = false
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

    # Variables under test
    trust_config_source = "CustomerManagedByoIssuer"

    byo_issuer_trust_settings = {
      issuer_name    = "test"
      issuer_kind    = "test"
      configmap_name = ""
      configmap_key  = "test"
    }

    aio_platform_config = {
      install_cert_manager  = false
      install_trust_manager = false
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

    # Variables under test
    trust_config_source = "CustomerManagedByoIssuer"

    byo_issuer_trust_settings = {
      issuer_name    = "test"
      issuer_kind    = "test"
      configmap_name = "test"
      configmap_key  = ""
    }

    aio_platform_config = {
      install_cert_manager  = false
      install_trust_manager = false
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
