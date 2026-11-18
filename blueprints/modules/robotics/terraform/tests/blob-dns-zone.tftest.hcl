# Plan-only tests with mocked providers, so they run without Azure credentials.
# Data sources for existing resources return fixed resource IDs that pass provider validation.

mock_provider "azurerm" {
  mock_data "azurerm_resource_group" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
      location = "eastus2"
    }
  }

  mock_data "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test"
    }
  }

  mock_data "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
    }
  }

  # Known at plan time so the storage account private DNS zone outputs can be checked
  mock_resource "azurerm_private_dns_zone" {
    override_during = plan
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    }
  }

  mock_data "azurerm_client_config" {
    defaults = {
      object_id = "00000000-0000-0000-0000-000000000001"
      tenant_id = "00000000-0000-0000-0000-000000000002"
    }
  }
}

mock_provider "azuread" {}

mock_provider "azapi" {}

mock_provider "tls" {}

variables {
  resource_prefix = "test"
  environment     = "dev"
  location        = "eastus2"
  instance        = "001"

  should_create_storage           = true
  should_enable_private_endpoints = true
}

# With existing Application Insights there is no cloud_observability module to share the blob
# private DNS zone, so cloud_data creates its own.
run "storage_private_endpoint_with_existing_observability" {
  command = plan

  variables {
    should_create_observability = false
  }

  assert {
    condition     = length(module.cloud_observability) == 0
    error_message = "cloud_observability should not be created"
  }

  assert {
    condition     = module.cloud_data[0].storage_account_private_dns_zones.blob.name == "privatelink.blob.core.windows.net"
    error_message = "cloud_data should create its own blob private DNS zone"
  }
}

# When this module creates cloud_observability, cloud_data reuses its blob private DNS zone.
run "storage_private_endpoint_with_created_observability" {
  command = plan

  variables {
    should_create_observability = true
  }

  assert {
    condition     = length(module.cloud_observability) == 1
    error_message = "cloud_observability should be created"
  }

  assert {
    condition     = module.cloud_data[0].storage_account_private_dns_zones.blob == null
    error_message = "cloud_data should reuse the cloud_observability blob private DNS zone instead of creating its own"
  }
}
