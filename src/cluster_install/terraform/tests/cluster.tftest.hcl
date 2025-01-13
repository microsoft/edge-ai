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
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "dev"
    location        = "centralus"
    trust_config = {
      source = "SelfSigned"
    }
  }

  # Check that a SP is not created when providing the SP credentials
  assert {
    condition     = length(module.arc_service_principal) == 0
    error_message = "SP should not have been created"
  }

  # Check the the cluster name is not empty
  assert {
    condition     = length(module.edge_device.connected_cluster_name) > 0
    error_message = "edge device has a length"
  }

  # Check that permissions on the public key are set correctly
  assert {
    condition     = module.edge_device.public_ssh_permissions == "600"
    error_message = "SSH Permissions should be set to 0600"
  }

  # Check that all resources use the same location
  assert {
    condition     = module.edge_device.connected_cluster_location == "centralus"
    error_message = "Location should be centralus"
  }
}

run "create_non_default_cluster" {
  command = plan
  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "dev"
    location        = "centralus"
    trust_config = {
      source = "CustomerManaged"
    }
    enable_aio_instance_secret_sync      = false
    add_current_entra_user_cluster_admin = true
  }
}
