mock_provider "azurerm" {}

# Call the setup module to create a random Arc connected cluster
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Test 1: CI defaults, both extensions are created with the default versions
run "create_default_configuration" {
  command = plan

  variables {
    arc_connected_cluster = run.setup_tests.arc_connected_cluster
  }

  assert {
    condition     = length(module.cert_manager_extension) == 1
    error_message = "cert-manager extension should be created by default"
  }

  assert {
    condition     = length(module.container_storage_extension) == 1
    error_message = "Container storage extension should be created by default"
  }

  assert {
    condition     = output.cert_manager_extension_name == "arc-cert-manager"
    error_message = "cert-manager extension name is not correct"
  }

  assert {
    condition     = output.container_storage_extension_name == "azure-arc-containerstorage"
    error_message = "Container storage extension name is not correct"
  }

  assert {
    condition     = module.cert_manager_extension[0].cert_manager.enabled && module.cert_manager_extension[0].cert_manager.version == "1.1.2" && module.cert_manager_extension[0].cert_manager.train == "stable"
    error_message = "cert-manager extension should use the default version and train"
  }

  assert {
    condition     = module.container_storage_extension[0].container_storage.enabled && module.container_storage_extension[0].container_storage.version == "2.12.0" && module.container_storage_extension[0].container_storage.train == "stable"
    error_message = "Container storage extension should use the default version and train"
  }
}

# Test 2: Both extensions disabled, nothing is created and the outputs are null
run "create_without_extensions" {
  command = plan

  variables {
    arc_connected_cluster = run.setup_tests.arc_connected_cluster

    arc_extensions = {
      cert_manager_extension = {
        enabled = false
      }
      container_storage_extension = {
        enabled = false
      }
    }
  }

  assert {
    condition     = length(module.cert_manager_extension) == 0
    error_message = "cert-manager extension should not be created when it is disabled"
  }

  assert {
    condition     = length(module.container_storage_extension) == 0
    error_message = "Container storage extension should not be created when it is disabled"
  }

  assert {
    condition     = output.cert_manager_extension == null && output.cert_manager_extension_id == null && output.cert_manager_extension_name == null
    error_message = "cert-manager outputs should be null when the extension is disabled"
  }

  assert {
    condition     = output.container_storage_extension == null && output.container_storage_extension_id == null && output.container_storage_extension_name == null
    error_message = "Container storage outputs should be null when the extension is disabled"
  }
}

# Test 3: Only cert-manager enabled, with a custom version and train
run "create_cert_manager_only" {
  command = plan

  variables {
    arc_connected_cluster = run.setup_tests.arc_connected_cluster

    arc_extensions = {
      cert_manager_extension = {
        enabled                            = true
        version                            = "1.2.0"
        train                              = "preview"
        auto_upgrade_minor_version         = false
        agent_operation_timeout_in_minutes = 30
        global_telemetry_enabled           = false
      }
      container_storage_extension = {
        enabled = false
      }
    }
  }

  assert {
    condition     = length(module.cert_manager_extension) == 1
    error_message = "cert-manager extension should be created when it is enabled"
  }

  assert {
    condition     = length(module.container_storage_extension) == 0
    error_message = "Container storage extension should not be created when it is disabled"
  }

  assert {
    condition     = module.cert_manager_extension[0].cert_manager.version == "1.2.0" && module.cert_manager_extension[0].cert_manager.train == "preview"
    error_message = "cert-manager extension should use the provided version and train"
  }
}

# Test 4: Container storage settings without fault tolerance use the default local storage class
run "container_storage_without_fault_tolerance" {
  command = plan

  module {
    source = "./modules/container-storage"
  }

  variables {
    arc_connected_cluster_id = run.setup_tests.arc_connected_cluster.id

    container_storage_extension = {
      enabled                    = true
      version                    = "2.12.0"
      train                      = "stable"
      auto_upgrade_minor_version = false
      disk_storage_class         = ""
      fault_tolerance_enabled    = false
      disk_mount_point           = "/mnt"
    }
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.container_storage.extension_type == "microsoft.arc.containerstorage"
    error_message = "Container storage extension type is not correct"
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.container_storage.cluster_id == var.arc_connected_cluster_id
    error_message = "Container storage extension should be installed on the Arc connected cluster"
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.container_storage.configuration_settings["feature.diskStorageClass"] == "default,local-path"
    error_message = "Default storage class should be used when fault tolerance is disabled"
  }

  assert {
    condition     = !contains(keys(azurerm_arc_kubernetes_cluster_extension.container_storage.configuration_settings), "acstorConfiguration.create")
    error_message = "ACStor configuration should not be set when fault tolerance is disabled"
  }
}

# Test 5: Container storage settings with fault tolerance use the ACStor storage pool and mount point
run "container_storage_with_fault_tolerance" {
  command = plan

  module {
    source = "./modules/container-storage"
  }

  variables {
    arc_connected_cluster_id = run.setup_tests.arc_connected_cluster.id

    container_storage_extension = {
      enabled                    = true
      version                    = "2.12.0"
      train                      = "stable"
      auto_upgrade_minor_version = false
      disk_storage_class         = ""
      fault_tolerance_enabled    = true
      disk_mount_point           = "/mnt/acstor"
    }
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.container_storage.configuration_settings["feature.diskStorageClass"] == "acstor-arccontainerstorage-storage-pool"
    error_message = "ACStor storage pool class should be used when fault tolerance is enabled"
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.container_storage.configuration_settings["acstorConfiguration.create"] == "true"
    error_message = "ACStor configuration should be created when fault tolerance is enabled"
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.container_storage.configuration_settings["acstorConfiguration.properties.diskMountPoint"] == "/mnt/acstor"
    error_message = "ACStor disk mount point should match disk_mount_point"
  }
}

# Test 6: A custom disk storage class overrides the default storage class
run "container_storage_with_custom_disk_storage_class" {
  command = plan

  module {
    source = "./modules/container-storage"
  }

  variables {
    arc_connected_cluster_id = run.setup_tests.arc_connected_cluster.id

    container_storage_extension = {
      enabled                    = true
      version                    = "2.12.0"
      train                      = "stable"
      auto_upgrade_minor_version = false
      disk_storage_class         = "custom-storage-class"
      fault_tolerance_enabled    = true
      disk_mount_point           = "/mnt"
    }
  }

  assert {
    condition     = azurerm_arc_kubernetes_cluster_extension.container_storage.configuration_settings["feature.diskStorageClass"] == "custom-storage-class"
    error_message = "disk_storage_class should override the default storage class"
  }
}
