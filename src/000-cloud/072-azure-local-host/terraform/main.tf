/**
 * # Azure Local Host
 *
 * Creates Azure Stack HCI (Azure Local) cluster resources.
 */

locals {
  ssh_public_key = coalesce(var.ssh_public_key, tls_private_key.cluster_ssh.public_key_openssh)
  tenant_id      = coalesce(var.aad_profile.tenant_id, data.azurerm_client_config.current.tenant_id)
}

data "azurerm_client_config" "current" {}

data "azapi_resource" "logical_network" {
  type      = "Microsoft.AzureStackHCI/logicalNetworks@2025-06-01-preview"
  name      = var.logical_network_name
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.logical_network_resource_group_name}"
}

resource "tls_private_key" "cluster_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azapi_resource" "connected_cluster" {

  location  = var.location
  name      = "arck-${var.resource_prefix}-${var.environment}-${var.instance}"
  parent_id = var.resource_group.id
  type      = "Microsoft.Kubernetes/connectedClusters@2025-08-01-preview"
  body = {
    kind = "ProvisionedCluster"
    properties = {
      aadProfile = {
        enableAzureRBAC     = var.aad_profile.enable_azure_rbac
        tenantID            = local.tenant_id
        adminGroupObjectIDs = var.aad_profile.enable_azure_rbac ? [] : var.aad_profile.admin_group_object_ids
      }
      agentPublicKeyCertificate = ""
      arcAgentProfile = {
        agentAutoUpgrade = "Enabled"
      }
      oidcIssuerProfile = {
        enabled = true
      }
      securityProfile = {
        workloadIdentity = {
          enabled = true
        }
      }
    }

    identity = {
      type = "SystemAssigned"
    }
  }

  lifecycle {
    ignore_changes = [
      identity[0],
      body.properties.azureHybridBenefit,
      body.properties.distribution,
      body.properties.infrastructure,
      body.properties.privateLinkState,
      body.properties.provisioningState,
    ]
  }
}

resource "azapi_resource" "provisioned_cluster_instance" {

  name      = "default"
  parent_id = azapi_resource.connected_cluster.id
  type      = "Microsoft.HybridContainerService/provisionedClusterInstances@2024-01-01"
  body = {
    extendedLocation = {
      name = var.custom_locations_oid
      type = "CustomLocation"
    }
    properties = {
      agentPoolProfiles = [
        {
          count  = var.node_pool_count
          name   = "nodepool1"
          osType = "Linux"
          osSKU  = "CBLMariner"
          vmSize = var.node_pool_vm_size
        }
      ]
      cloudProviderProfile = {
        infraNetworkProfile = {
          vnetSubnetIds = [
            data.azapi_resource.logical_network.id,
          ]
        }
      }
      controlPlane = {
        count  = var.control_plane_count
        vmSize = var.control_plane_vm_size
        controlPlaneEndpoint = {
          hostIP = var.control_plane_ip
        }
      }
      kubernetesVersion = var.kubernetes_version
      linuxProfile = {
        ssh = {
          publicKeys = [
            {
              keyData = local.ssh_public_key
            },
          ]
        }
      }
      networkProfile = {
        podCidr       = var.pod_cidr
        networkPolicy = "calico"
        loadBalancerProfile = {
          count = var.load_balancer_count
        }
      }
      storageProfile = {
        smbCsiDriver = {
          enabled = var.smb_csi_driver_enabled
        }
        nfsCsiDriver = {
          enabled = var.nfs_csi_driver_enabled
        }
      }
      clusterVMAccessProfile = {}
      licenseProfile         = { azureHybridBenefit = var.azure_hybrid_benefit }
    }
  }

  timeouts {
    create = "2h"
    update = "2h"
  }

  depends_on = [azapi_resource.connected_cluster]

  lifecycle {
    ignore_changes = [
      body.properties.autoScalerProfile,
      body.properties.networkProfile.podCidr,
      body.properties.provisioningStateTransitionTime,
      body.properties.provisioningStateUpdatedTime,
    ]
  }
}

resource "azapi_resource" "agent_pool" {
  count = length(var.additional_nodepools)

  name      = var.additional_nodepools[count.index].name
  parent_id = azapi_resource.provisioned_cluster_instance.id
  type      = "Microsoft.HybridContainerService/provisionedClusterInstances/agentPools@2024-01-01"
  body = {
    extendedLocation = {
      name = var.custom_locations_oid
      type = "CustomLocation"
    }
    properties = {
      count  = var.additional_nodepools[count.index].count
      osType = var.additional_nodepools[count.index].osType
      osSKU  = var.additional_nodepools[count.index].osSKU
      vmSize = var.additional_nodepools[count.index].vmSize
    }
  }

  lifecycle {
    ignore_changes = [
      body.properties.status
    ]
  }
}
