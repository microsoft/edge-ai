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

# Apply run block to create a default VM
run "create_default_vm" {
  command = plan

  variables {
    resource_prefix    = run.setup_tests.resource_prefix
    environment        = "test"
    location           = run.setup_tests.location
    resource_group     = run.setup_tests.aio_resource_group
    subnet_id          = run.setup_tests.subnet_id
    host_machine_count = 1
  }

  # SSH key assertions
  assert {
    condition     = local_sensitive_file.private_key.file_permission == "600"
    error_message = "SSH permissions should be set to 600"
  }

  # # Network assertions
  # assert {
  #   condition     = length(keys(module.virtual_network)) > 0
  #   error_message = "Virtual network module should be created"
  # }

  # VM assertions
  assert {
    condition     = length(module.virtual_machine) == 1
    error_message = "Should create exactly 1 virtual machine"
  }

  assert {
    condition     = contains(keys(module.virtual_machine[0]), "public_ip")
    error_message = "Virtual machine should have a public IP output"
  }

  assert {
    condition     = local.vm_username == run.setup_tests.resource_prefix
    error_message = "Default VM username should match resource prefix when not specified"
  }
}

# Test VM with user assigned managed identity
run "create_non_default_vm_with_uami" {
  command = plan

  variables {
    resource_prefix         = run.setup_tests.resource_prefix
    location                = run.setup_tests.location
    environment             = "test"
    subnet_id               = run.setup_tests.subnet_id
    vm_username             = "testuser"
    vm_sku_size             = "Standard_D8s_v3"
    resource_group          = run.setup_tests.aio_resource_group
    arc_onboarding_identity = run.setup_tests.arc_onboarding_user_assigned_identity
    host_machine_count      = 1
  }

  # Custom username assertion
  assert {
    condition     = local.vm_username == "testuser"
    error_message = "VM username should match specified value"
  }

  # VM SKU size assertion
  assert {
    condition     = var.vm_sku_size == "Standard_D8s_v3"
    error_message = "VM SKU size should match specified value"
  }

  # User assigned identity assertion
  assert {
    condition     = try(var.arc_onboarding_identity.id, "") != ""
    error_message = "User assigned identity ID should be provided"
  }

  # Virtual machine module assertions
  assert {
    condition     = length(module.virtual_machine) == 1
    error_message = "Should create exactly 1 virtual machine with user assigned identity"
  }
}
