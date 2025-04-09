/**
 * # Azure Managed DevOps Pool for Accelerator
 *
 * Create a Dev Center and Project to host a Managed DevOps Pool for Accelerator
 *
 */

locals {
  azdo_org_name = coalesce(var.azdo_org_name, "ai-at-the-edge-flagship-accelerator")
}

resource "azurerm_dev_center" "dev_center" {
  name                = "dc-${var.resource_prefix}-${var.environment}-${var.instance}"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
}

resource "azurerm_dev_center_project" "dev_center_project" {
  name                = "dcp-${var.resource_prefix}-${var.environment}-${var.instance}"
  dev_center_id       = azurerm_dev_center.dev_center.id
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
}

resource "azapi_resource" "managed_devops_pool" {
  type                      = "Microsoft.DevOpsInfrastructure/pools@2024-10-19"
  location                  = var.resource_group.location
  name                      = "mdp-${var.resource_prefix}-${var.environment}-${var.instance}"
  parent_id                 = var.resource_group.id
  schema_validation_enabled = false

  body = {
    properties = {
      devCenterProjectResourceId = azurerm_dev_center_project.dev_center_project.id
      maximumConcurrency         = 2
      organizationProfile = {
        kind = "AzureDevOps"
        organizations = [{
          url         = "https://dev.azure.com/${local.azdo_org_name}"
          projects    = []
          parallelism = 2
        }]
      }
      agentProfile = {
        maxAgentLifetime    = "01:00:00"
        gracePeriodTimeSpan = "00:01:00"
        kind                = "Stateful"
        resourcePredictions = {
          timeZone = "UTC"
          daysData = [{
            "00:00:00" = 2
          }]
        }
        resourcePredictionsProfile = {
          kind = "Manual"
        }
      }
      fabricProfile = {
        sku = {
          name = "Standard_DS2_v2"
        },
        images = [
          {
            aliases = [
              "ubuntu-22.04",
              "ubuntu-latest",
              "ubuntu-22.04/latest"
            ]
            buffer             = "75"
            wellKnownImageName = "ubuntu-22.04"
          },
          {
            aliases = [
              "windows-2022",
              "windows-latest",
              "windows-2022/latest"
            ]
            buffer             = "25"
            wellKnownImageName = "windows-2022"
          }
        ]
        osProfile = {
          logonType = "Service"
        }
        storageProfile = {
          osDiskStorageAccountType = "Premium"
          dataDisks = [
            {
              diskSizeGiB        = 200
              caching            = "ReadWrite"
              storageAccountType = "StandardSSD_LRS"
              driveLetter        = "f"
            }
          ]
        }
        networkProfile = {
          subnetId = var.snet_pool.id
        },
        kind = "Vmss"
      }
    }
  }
}
