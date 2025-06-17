##########################################
### Resources
##########################################

resource "azurerm_resource_group" "aio" {
  name     = coalesce(var.azure_resource_group, "rg-${var.cluster_name}")
  location = var.azure_location
}

resource "tls_private_key" "arc_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "connectedk8s" {
  source = "../connectedk8s"

  azure_resource_group = azurerm_resource_group.aio
  cluster_name         = var.cluster_name
  private_key_pem      = tls_private_key.arc_key.private_key_pem
}

module "rancher_common" {
  source     = "../ranchercommon"
  http_proxy = var.http_proxy
}

locals {
  selected_machine_pool = coalesce(var.rancher_config.rancher_machine_pools, module.rancher_common.rancher_machine_pools[var.rancher_config.cluster_size])
}

module "aio_cluster" {
  source = "../rke2guestclusterv2"

  rancher_api_url                 = var.rancher_api_url
  rancher_access_key              = var.rancher_access_key
  rancher_secret_key              = var.rancher_secret_key
  harvester_cluster_id            = var.rancher_config.harvester_cluster_id
  harvester_cloud_credential_name = var.rancher_config.harvester_cloud_credential_name
  system_default_registry         = var.rancher_config.system_default_registry
  container_registry_mirrors      = var.rancher_config.container_registry_mirrors
  cluster_name                    = var.cluster_name
  harvester_namespace             = var.rancher_config.harvester_namespace
  rke2_version                    = var.rancher_config.k8s_version
  container_network               = var.rancher_config.container_network
  cilium_options                  = var.rancher_config.cilium_options
  agent_environment_vars          = nonsensitive(coalesce(var.rancher_config.agent_environment_vars, module.rancher_common.http_proxy_env))
  enable_network_policy           = var.rancher_config.enable_network_policy
  local_auth_endpoint             = var.rancher_config.local_auth_endpoint
  enable_kube_vip                 = var.rancher_config.enable_kube_vip
  kubelet_args_max_pods           = var.rancher_config.kubelet_args_max_pods
  node_network_cidr               = var.rancher_config.node_network_cidr
  nginx_enable_ssl_passthrough    = var.rancher_config.nginx_enable_ssl_passthrough
  cluster_admin_group_name        = var.rancher_config.cluster_admin_group_name
  rancher_machine_pools           = local.selected_machine_pool
  machine_global_config = {
    kube_apiserver_arg = [
      "service-account-issuer=${module.connectedk8s.oidc_issuer_url}",
      "service-account-max-token-expiration=24h"
    ]
  }
}

resource "rancher2_cluster_sync" "arc_sync" {
  cluster_id = module.aio_cluster.rancher_guest_cluster.cluster_v1_id
}

module "azure_arc_k8s" {
  source = "../arck8sagents"

  azure_resource_group      = azurerm_resource_group.aio
  cluster_name              = module.connectedk8s.cluster_name
  private_key_pem           = tls_private_key.arc_key.private_key_pem
  http_proxy                = var.http_proxy
  custom_location_object_id = var.custom_location_object_id
}

locals {
  broker_config = {
    frontend = {
      replicas = 2
      workers  = 2
    }
    backend_chain = {
      partitions        = 2
      redundancy_factor = 2
      workers           = 2
    }
  }
  aio_available_features = {
    "connectors" = {
      connectors : {
        settings : {
          preview : "Enabled"
        }
      }
    }
  }
  aio_features = merge([for feature, enabled in var.aio_features : lookup(local.aio_available_features, feature, null) if enabled]...)
  # Calculate if the current machine pool can support the broker CPU limits
  # The broker CPU limits are supported if:
  # 1. The total available CPU across all worker nodes is greater than or equal to the total required CPU
  # 2. Each worker node has enough CPU to support the minimum required CPU per broker pod
  #    (calculated as the maximum of the frontend and backend worker CPU requirements)
  # For calulating the total required CPU, we consider that frontend workers need 1.0 CPU per worker, backend workers need 2.0 CPU per worker
  # for more information see https://learn.microsoft.com/en-us/azure/iot-operations/manage-mqtt-broker/howto-configure-availability-scale?tabs=portal#cardinality-and-kubernetes-resource-limits
  worker_nodes_cpus           = [for machine in local.selected_machine_pool : machine.cpu_count if machine.worker_role]
  total_available_cpu         = sum(local.worker_nodes_cpus)
  total_required_cpu          = (local.broker_config.frontend.replicas * local.broker_config.frontend.workers) + (local.broker_config.backend_chain.partitions * local.broker_config.backend_chain.redundancy_factor * local.broker_config.backend_chain.workers * 2)
  min_required_cpu_per_node   = max(local.broker_config.frontend.workers, local.broker_config.backend_chain.workers * 2)
  all_nodes_enough_cpus       = alltrue([for cpu_count in local.worker_nodes_cpus : cpu_count >= local.min_required_cpu_per_node])
  enough_total_cpu            = local.total_available_cpu >= (local.total_required_cpu + (2 * length(local.worker_nodes_cpus))) # Add 2 CPUs for other workloads per node
  broker_cpu_limits_supported = local.enough_total_cpu && local.all_nodes_enough_cpus
}
