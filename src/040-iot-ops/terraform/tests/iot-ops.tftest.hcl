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

# Apply run block to create the cluster
run "create_default_cluster" {

  command = plan
  variables {
    aio_resource_group         = run.setup_tests.aio_resource_group
    sse_key_vault              = run.setup_tests.sse_key_vault
    sse_user_assigned_identity = run.setup_tests.sse_user_assigned_identity
    aio_user_assigned_identity = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry        = run.setup_tests.adr_schema_registry
    arc_connected_cluster      = run.setup_tests.arc_connected_cluster
  }
}

run "create_custom_generated_issuer_cluster" {
  command = plan
  variables {
    aio_resource_group         = run.setup_tests.aio_resource_group
    sse_key_vault              = run.setup_tests.sse_key_vault
    sse_user_assigned_identity = run.setup_tests.sse_user_assigned_identity
    aio_user_assigned_identity = run.setup_tests.aio_user_assigned_identity
    adr_schema_registry        = run.setup_tests.adr_schema_registry
    arc_connected_cluster      = run.setup_tests.arc_connected_cluster
    trust_config_source        = "CustomerManagedGenerateIssuer"
    enable_opc_ua_simulator    = false

    aio_ca = {
      root_ca_cert_pem  = "root_ca_cert_pem"
      ca_cert_chain_pem = "ca_cert_chain_pem"
      ca_key_pem        = "ca_key_pem"
    }
  }
}
