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
    vm_count           = 1
  }

  # Check that permissions on the public key are set correctly
  assert {
    condition     = local_sensitive_file.private_key.file_permission == "600"
    error_message = "SSH Permissions should be set to 600"
  }

  # Check that all resources use the same location
  assert {
    condition     = module.virtual_machine[0].virtual_machine.location == "centralus"
    error_message = "Location should be centralus"
  }

  # Check that the virtual network module was created
  assert {
    condition     = length(module.virtual_network) > 0
    error_message = "Virtual network module should be created"
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
    vm_count                              = 1
  }

  assert {
    condition     = strcontains(one(module.virtual_machine[0].virtual_machine.identity[0].identity_ids), "id-")
    error_message = "'arc_onboarding_user_assigned_identity' must be used when creating the VM"
  }

  # Check that subnet from virtual network is used by VM
  assert {
    condition     = contains(keys(module.virtual_machine[0].virtual_machine), "network_interface_ids")
    error_message = "VM should have network interfaces connected to the subnet"
  }
}

# Test multiple VM creation with vm_count = 3
run "create_multiple_vms" {
  command = plan

  variables {
    resource_prefix    = run.setup_tests.resource_prefix
    environment        = "test"
    location           = "centralus"
    aio_resource_group = run.setup_tests.aio_resource_group
    vm_count           = 3
  }

  # Check that exactly 3 VMs are created
  assert {
    condition     = length(module.virtual_machine) == 3
    error_message = "Expected 3 virtual machines to be created when vm_count = 3"
  }

  # Check that each VM has a unique name with proper index
  assert {
    condition = ((module.virtual_machine[0].linux_virtual_machine_name != module.virtual_machine[1].linux_virtual_machine_name &&
      module.virtual_machine[1].linux_virtual_machine_name != module.virtual_machine[2].linux_virtual_machine_name &&
    module.virtual_machine[0].linux_virtual_machine_name != module.virtual_machine[2].linux_virtual_machine_name))
    error_message = "Each VM should have a unique name"
  }

  # Verify that each VM uses the correct index in its resource names
  assert {
    condition = (endswith(module.virtual_machine[0].linux_virtual_machine_name, "-0") &&
      endswith(module.virtual_machine[1].linux_virtual_machine_name, "-1") &&
    endswith(module.virtual_machine[2].linux_virtual_machine_name, "-2"))
    error_message = "VM names should include the correct index suffix"
  }

  # Check that all VMs are in the same location
  assert {
    condition = alltrue([
      for vm in module.virtual_machine : vm.virtual_machine.location == "centralus"
    ])
    error_message = "All VMs should be in the centralus location"
  }

  # Check that SSH file permissions are set correctly
  assert {
    condition     = local_sensitive_file.private_key.file_permission == "600"
    error_message = "SSH private key file permissions should be set to 600"
  }

  # Validate that each VM has a network interface
  assert {
    condition = alltrue([
      for vm in module.virtual_machine : contains(keys(vm.virtual_machine), "network_interface_ids")
    ])
    error_message = "All VMs should have network interfaces configured"
  }
}
