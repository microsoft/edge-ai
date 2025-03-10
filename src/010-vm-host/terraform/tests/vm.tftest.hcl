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
run "create_default_vm" {
  command = plan

  variables {
    resource_prefix    = run.setup_tests.resource_prefix
    environment        = "test"
    location           = "centralus"
    aio_resource_group = run.setup_tests.aio_resource_group
  }

  # Check that permissions on the public key are set correctly
  assert {
    condition     = local_sensitive_file.ssh.file_permission == "600"
    error_message = "SSH Permissions should be set to 0600"
  }

  # Check that all resources use the same location
  assert {
    condition     = azurerm_linux_virtual_machine.aio_edge.location == "centralus"
    error_message = "Location should be centralus"
  }
}

run "create_non_default_vm_with_uami" {
  command = plan

  variables {
    resource_prefix                       = run.setup_tests.resource_prefix
    location                              = "centralus"
    environment                           = "test"
    vm_username                           = "1234"
    vm_sku_size                           = "Standard_D8s_v3"
    aio_resource_group                    = run.setup_tests.aio_resource_group
    arc_onboarding_user_assigned_identity = run.setup_tests.arc_onboarding_user_assigned_identity
  }

  assert {
    condition     = strcontains(one(azurerm_linux_virtual_machine.aio_edge.identity[0].identity_ids), "uami-")
    error_message = "'arc_onboarding_user_assigned_identity' must be used when creating the VM"
  }
}
