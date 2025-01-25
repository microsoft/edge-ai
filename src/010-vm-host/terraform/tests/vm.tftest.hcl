# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

mock_provider "azurerm" {
  mock_data "azurerm_resource_group" {
    defaults = {
      name = "test_name"
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
  mock_data "azurerm_subscription" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
  mock_data "azurerm_user_assigned_identity" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-resource-group/providers/Microsoft.ManagedIdentity/userAssignedIdentities/userAssignedIdentityValue"
      output = {
        principalId = "test_principal_id"
      }
    }
    
  }
}

# Apply run block to create the cluster
run "create_default_vm" {

  command = plan
  variables {
    resource_prefix = run.setup_tests.resource_prefix
    environment     = "dev"
    location        = "centralus"
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

run "create_non_default_vm" {
  command = plan
  variables {
    resource_prefix                             = run.setup_tests.resource_prefix
    environment                                 = "dev"
    location                                    = "centralus"
    instance                                    = "002"
    vm_username                                 = "1234"
    vm_sku_size                                 = "Standard_D8s_v3"
    arc_onboarding_user_managed_identity_name   = "mi-test-user"
    enable_arc_onboarding_user_managed_identity = false
  }
}
