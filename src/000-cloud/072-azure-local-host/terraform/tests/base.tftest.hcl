mock_provider "azapi" {}

mock_provider "azurerm" {
  override_data {
    target = data.azurerm_client_config.current
    values = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "11111111-1111-1111-1111-111111111111"
    }
  }
}

mock_provider "tls" {}

# Call the setup module to create a random resource prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Test 1: Default configuration creates the connected cluster and a single-node provisioned cluster
run "create_default_configuration" {
  command = plan

  variables {
    resource_prefix                     = run.setup_tests.resource_prefix
    environment                         = "test"
    instance                            = "001"
    location                            = run.setup_tests.location
    resource_group                      = run.setup_tests.resource_group
    custom_locations_oid                = run.setup_tests.custom_locations_oid
    logical_network_name                = run.setup_tests.logical_network_name
    logical_network_resource_group_name = run.setup_tests.logical_network_resource_group_name
  }

  assert {
    condition     = azapi_resource.connected_cluster.name == "arck-${var.resource_prefix}-${var.environment}-${var.instance}"
    error_message = "Connected cluster name does not match expected pattern"
  }

  assert {
    condition     = azapi_resource.connected_cluster.parent_id == var.resource_group.id
    error_message = "Connected cluster should be created in the provided resource group"
  }

  assert {
    condition     = azapi_resource.connected_cluster.body.kind == "ProvisionedCluster"
    error_message = "Connected cluster should be a ProvisionedCluster"
  }

  assert {
    condition     = azapi_resource.connected_cluster.body.properties.aadProfile.enableAzureRBAC == true
    error_message = "Azure RBAC should be enabled by default"
  }

  assert {
    condition     = length(azapi_resource.connected_cluster.body.properties.aadProfile.adminGroupObjectIDs) == 0
    error_message = "Admin group object IDs should be empty when Azure RBAC is enabled"
  }

  assert {
    condition     = azapi_resource.connected_cluster.body.properties.aadProfile.tenantID == "11111111-1111-1111-1111-111111111111"
    error_message = "Tenant ID should default to the current client tenant"
  }

  assert {
    condition     = data.azapi_resource.logical_network.parent_id == "/subscriptions/${run.setup_tests.subscription_id}/resourceGroups/${var.logical_network_resource_group_name}"
    error_message = "Logical network should be looked up in the provided resource group of the current subscription"
  }

  assert {
    condition     = data.azapi_resource.logical_network.name == var.logical_network_name
    error_message = "Logical network lookup should use the provided name"
  }

  assert {
    condition     = azapi_resource.provisioned_cluster_instance.body.extendedLocation.name == var.custom_locations_oid
    error_message = "Provisioned cluster should use the provided custom location"
  }

  assert {
    condition     = azapi_resource.provisioned_cluster_instance.body.properties.agentPoolProfiles[0].count == 1
    error_message = "Default node pool should have one node by default"
  }

  assert {
    condition     = azapi_resource.provisioned_cluster_instance.body.properties.agentPoolProfiles[0].vmSize == "Standard_D8s_v6"
    error_message = "Default node pool should use the Standard_D8s_v6 VM size by default"
  }

  assert {
    condition     = azapi_resource.provisioned_cluster_instance.body.properties.controlPlane.count == 1
    error_message = "Control plane should have one node by default"
  }

  assert {
    condition     = azapi_resource.provisioned_cluster_instance.body.properties.controlPlane.controlPlaneEndpoint.hostIP == null
    error_message = "Control plane IP should be dynamically assigned by default"
  }

  assert {
    condition     = azapi_resource.provisioned_cluster_instance.body.properties.networkProfile.podCidr == "10.244.0.0/16"
    error_message = "Pod CIDR should default to 10.244.0.0/16"
  }

  assert {
    condition     = azapi_resource.provisioned_cluster_instance.body.properties.storageProfile.smbCsiDriver.enabled == false && azapi_resource.provisioned_cluster_instance.body.properties.storageProfile.nfsCsiDriver.enabled == false
    error_message = "SMB and NFS CSI drivers should be disabled by default"
  }

  assert {
    condition     = length(azapi_resource.agent_pool) == 0
    error_message = "No additional node pools should be created by default"
  }
}

# Test 2: Provided cluster settings are passed through to the provisioned cluster
run "create_with_custom_cluster_settings" {
  command = plan

  variables {
    resource_prefix                     = run.setup_tests.resource_prefix
    environment                         = "test"
    instance                            = "002"
    location                            = run.setup_tests.location
    resource_group                      = run.setup_tests.resource_group
    custom_locations_oid                = run.setup_tests.custom_locations_oid
    logical_network_name                = run.setup_tests.logical_network_name
    logical_network_resource_group_name = run.setup_tests.logical_network_resource_group_name

    ssh_public_key         = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQtest test@example"
    control_plane_ip       = "10.0.0.10"
    control_plane_count    = 3
    control_plane_vm_size  = "Standard_A8_v2"
    node_pool_count        = 2
    node_pool_vm_size      = "Standard_D4s_v6"
    kubernetes_version     = "1.30.4"
    pod_cidr               = "10.250.0.0/16"
    load_balancer_count    = 1
    smb_csi_driver_enabled = true
    nfs_csi_driver_enabled = true
    azure_hybrid_benefit   = "True"
  }

  assert {
    condition     = azapi_resource.connected_cluster.name == "arck-${var.resource_prefix}-${var.environment}-002"
    error_message = "Connected cluster name should include the provided instance"
  }

  assert {
    condition     = azapi_resource.provisioned_cluster_instance.body.properties.linuxProfile.ssh.publicKeys[0].keyData == var.ssh_public_key
    error_message = "Provided SSH public key should be used instead of the generated key"
  }

  assert {
    condition     = azapi_resource.provisioned_cluster_instance.body.properties.controlPlane.controlPlaneEndpoint.hostIP == "10.0.0.10"
    error_message = "Control plane endpoint should use the provided IP"
  }

  assert {
    condition     = azapi_resource.provisioned_cluster_instance.body.properties.controlPlane.count == 3 && azapi_resource.provisioned_cluster_instance.body.properties.controlPlane.vmSize == "Standard_A8_v2"
    error_message = "Control plane should use the provided count and VM size"
  }

  assert {
    condition     = azapi_resource.provisioned_cluster_instance.body.properties.agentPoolProfiles[0].count == 2 && azapi_resource.provisioned_cluster_instance.body.properties.agentPoolProfiles[0].vmSize == "Standard_D4s_v6"
    error_message = "Default node pool should use the provided count and VM size"
  }

  assert {
    condition     = azapi_resource.provisioned_cluster_instance.body.properties.kubernetesVersion == "1.30.4"
    error_message = "Kubernetes version should be passed through"
  }

  assert {
    condition     = azapi_resource.provisioned_cluster_instance.body.properties.networkProfile.podCidr == "10.250.0.0/16" && azapi_resource.provisioned_cluster_instance.body.properties.networkProfile.loadBalancerProfile.count == 1
    error_message = "Network profile should use the provided pod CIDR and load balancer count"
  }

  assert {
    condition     = azapi_resource.provisioned_cluster_instance.body.properties.storageProfile.smbCsiDriver.enabled == true && azapi_resource.provisioned_cluster_instance.body.properties.storageProfile.nfsCsiDriver.enabled == true
    error_message = "SMB and NFS CSI drivers should be enabled when requested"
  }

  assert {
    condition     = azapi_resource.provisioned_cluster_instance.body.properties.licenseProfile.azureHybridBenefit == "True"
    error_message = "Azure Hybrid Benefit should be passed through"
  }
}

# Test 3: Admin groups and tenant are used when Azure RBAC is disabled
run "create_with_admin_groups" {
  command = plan

  variables {
    resource_prefix                     = run.setup_tests.resource_prefix
    environment                         = "test"
    location                            = run.setup_tests.location
    resource_group                      = run.setup_tests.resource_group
    custom_locations_oid                = run.setup_tests.custom_locations_oid
    logical_network_name                = run.setup_tests.logical_network_name
    logical_network_resource_group_name = run.setup_tests.logical_network_resource_group_name

    aad_profile = {
      enable_azure_rbac      = false
      admin_group_object_ids = ["22222222-2222-2222-2222-222222222222"]
      tenant_id              = "33333333-3333-3333-3333-333333333333"
    }
  }

  assert {
    condition     = azapi_resource.connected_cluster.body.properties.aadProfile.enableAzureRBAC == false
    error_message = "Azure RBAC should be disabled when requested"
  }

  assert {
    condition     = azapi_resource.connected_cluster.body.properties.aadProfile.adminGroupObjectIDs == tolist(["22222222-2222-2222-2222-222222222222"])
    error_message = "Admin group object IDs should be passed through when Azure RBAC is disabled"
  }

  assert {
    condition     = azapi_resource.connected_cluster.body.properties.aadProfile.tenantID == "33333333-3333-3333-3333-333333333333"
    error_message = "Provided tenant ID should take precedence over the current client tenant"
  }
}

# Test 4: Disabling Azure RBAC without admin groups fails validation
run "reject_disabled_rbac_without_admin_groups" {
  command = plan

  variables {
    resource_prefix                     = run.setup_tests.resource_prefix
    environment                         = "test"
    location                            = run.setup_tests.location
    resource_group                      = run.setup_tests.resource_group
    custom_locations_oid                = run.setup_tests.custom_locations_oid
    logical_network_name                = run.setup_tests.logical_network_name
    logical_network_resource_group_name = run.setup_tests.logical_network_resource_group_name

    aad_profile = {
      enable_azure_rbac = false
    }
  }

  expect_failures = [var.aad_profile]
}

# Test 5: Additional node pools are created with their defaults
run "create_additional_nodepools" {
  command = plan

  variables {
    resource_prefix                     = run.setup_tests.resource_prefix
    environment                         = "test"
    location                            = run.setup_tests.location
    resource_group                      = run.setup_tests.resource_group
    custom_locations_oid                = run.setup_tests.custom_locations_oid
    logical_network_name                = run.setup_tests.logical_network_name
    logical_network_resource_group_name = run.setup_tests.logical_network_resource_group_name

    additional_nodepools = [
      {
        name   = "gpupool"
        count  = 1
        vmSize = "Standard_NK6"
      },
      {
        name   = "winpool"
        count  = 2
        vmSize = "Standard_D8s_v6"
        osType = "Windows"
        osSKU  = "Windows2022"
      },
    ]
  }

  assert {
    condition     = length(azapi_resource.agent_pool) == 2
    error_message = "One agent pool should be created per additional node pool"
  }

  assert {
    condition     = azapi_resource.agent_pool[0].name == "gpupool" && azapi_resource.agent_pool[1].name == "winpool"
    error_message = "Agent pools should use the provided names"
  }

  assert {
    condition     = azapi_resource.agent_pool[0].body.properties.osType == "Linux" && azapi_resource.agent_pool[0].body.properties.osSKU == "CBLMariner"
    error_message = "Agent pools should default to Linux with CBLMariner"
  }

  assert {
    condition     = azapi_resource.agent_pool[1].body.properties.osType == "Windows" && azapi_resource.agent_pool[1].body.properties.osSKU == "Windows2022" && azapi_resource.agent_pool[1].body.properties.count == 2
    error_message = "Agent pools should use the provided OS type, SKU and count"
  }

  assert {
    condition     = azapi_resource.agent_pool[0].body.extendedLocation.name == var.custom_locations_oid
    error_message = "Agent pools should use the provided custom location"
  }
}
