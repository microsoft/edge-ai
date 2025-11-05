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

run "create_default_configuration" {
  command = plan

  variables {
    resource_prefix        = run.setup_tests.resource_prefix
    environment            = run.setup_tests.environment
    location               = run.setup_tests.location
    instance               = run.setup_tests.instance
    resource_group         = run.setup_tests.resource_group
    network_security_group = run.setup_tests.network_security_group
    virtual_network        = run.setup_tests.virtual_network
    acr                    = run.setup_tests.acr
  }

  assert {
    condition     = module.network.snet_aks.name == "subnet-${var.resource_prefix}-aks-${var.environment}-${var.instance}"
    error_message = "Subnet name for AKS does not match expected pattern"
  }
  assert {
    condition     = module.network.snet_aks_pod.name == "subnet-${var.resource_prefix}-aks-pod-${var.environment}-${var.instance}"
    error_message = "Subnet name for AKS pod does not match expected pattern"
  }
}

run "create_non_default_configuration" {
  command = plan

  variables {
    resource_prefix                     = run.setup_tests.resource_prefix
    environment                         = run.setup_tests.environment
    location                            = run.setup_tests.location
    instance                            = run.setup_tests.instance
    resource_group                      = run.setup_tests.resource_group
    network_security_group              = run.setup_tests.network_security_group
    virtual_network                     = run.setup_tests.virtual_network
    acr                                 = run.setup_tests.acr
    should_create_aks                   = true
    should_enable_azure_monitor_metrics = false
    node_count                          = 3
    node_vm_size                        = "Standard_DS2_v2"
    dns_prefix                          = "dns-prefix"
  }

  assert {
    condition     = module.aks_cluster[0].aks.default_node_pool[0].node_count == 3
    error_message = "AKS node count does not match expected value"
  }

  assert {
    condition     = module.aks_cluster[0].aks.default_node_pool[0].vm_size == "Standard_DS2_v2"
    error_message = "AKS VM size does not match expected value"
  }

  assert {
    condition     = module.aks_cluster[0].aks.dns_prefix == "dns-prefix"
    error_message = "AKS DNS prefix does not match expected value"
  }
}
