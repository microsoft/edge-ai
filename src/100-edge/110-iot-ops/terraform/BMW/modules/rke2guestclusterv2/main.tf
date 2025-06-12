##########################################
### Resources
##########################################

# Get imported harvester cluster info
data "rancher2_cluster_v2" "harvester_cluster" {
  name = var.harvester_cluster_id
}

# Create a service account in Harvester for the Guest cluster
data "http" "harvester_sa" {
  provider = http-full

  url = "${var.rancher_api_url}/k8s/clusters/${var.harvester_cluster_id}/v1/harvester/kubeconfig"

  method = "POST"

  request_headers = {
    content-type  = "application/json"
    authorization = "Bearer ${var.rancher_access_key}:${var.rancher_secret_key}"
  }

  request_body = jsonencode({ "clusterRoleName" = "harvesterhci.io:cloudprovider", "namespace" = "${var.harvester_namespace}", "serviceAccountName" = "${var.cluster_name}" })
}

# Cloud Credential created in prerequisites
data "rancher2_cloud_credential" "harvester_cluster" {
  name = var.harvester_cloud_credential_name
}

# local variables
locals {
  machine_selector_config = {
    cloud-provider-name     = "harvester"
    cloud-provider-config   = trim(replace(data.http.harvester_sa.body, "\\n", "\n"), "\"")
    system-default-registry = "${var.system_default_registry}"
    kubelet-arg             = ["--max-pods=${var.kubelet_args_max_pods}"]
  }

  registry_mirrors = flatten([for key, val in var.container_registry_mirrors : {
    hostname  = key
    endpoints = val.endpoints
  }])

  rancher_machine_pools = tomap({
    for k, v in var.rancher_machine_pools : k => v
  })
}

# Create the machine config for the control plane nodes
resource "rancher2_machine_config_v2" "machine_config_pool_nodes" {
  for_each = local.rancher_machine_pools

  generate_name = "${var.cluster_name}-${each.value["name"]}"

  harvester_config {
    vm_namespace = var.harvester_namespace
    cpu_count    = each.value["cpu_count"]
    memory_size  = each.value["memory_size"]
    disk_info    = <<EOF
    {
        "disks": [{
            "imageName": "${each.value["image_name"]}",
            "size": ${each.value["disk_size"]},
            "bootOrder": 1
        }]
    }
    EOF
    network_info = <<EOF
    {
        "interfaces": [{
            "networkName": "${each.value["network_name"]}"
        }]
    }
    EOF
    ssh_user     = each.value["ssh_user"]
    user_data    = each.value["user_data"]
    vm_affinity  = each.value["availability_zone"] != "" ? base64encode("{\"nodeAffinity\":{\"requiredDuringSchedulingIgnoredDuringExecution\":{\"nodeSelectorTerms\":[{\"matchExpressions\":[{\"key\":\"topology.kubernetes.io/zone\",\"operator\":\"In\",\"values\":[\"${each.value["availability_zone"]}\"]}]}]}}}") : ""
  }
}

resource "rancher2_cluster_v2" "rancher_guest_cluster" {
  lifecycle {
    ignore_changes = [
      rke_config[0].machine_selector_config[0].config
    ]
  }

  name                         = var.cluster_name
  cloud_credential_secret_name = data.rancher2_cloud_credential.harvester_cluster.id
  enable_network_policy        = var.enable_network_policy
  local_auth_endpoint {
    enabled = var.local_auth_endpoint
  }
  kubernetes_version = var.rke2_version
  labels = {
    kube-vip = "${var.enable_kube_vip}"
  }
  dynamic "agent_env_vars" {
    for_each = var.agent_environment_vars
    content {
      name  = agent_env_vars.key
      value = agent_env_vars.value
    }
  }
  rke_config {
    dynamic "machine_pools" {
      for_each = local.rancher_machine_pools
      content {
        name                         = machine_pools.value["name"]
        cloud_credential_secret_name = data.rancher2_cloud_credential.harvester_cluster.id
        control_plane_role           = machine_pools.value["control_plane_role"]
        etcd_role                    = machine_pools.value["etcd_role"]
        worker_role                  = machine_pools.value["worker_role"]
        drain_before_delete          = true
        quantity                     = machine_pools.value["node_count"]
        machine_config {
          kind = rancher2_machine_config_v2.machine_config_pool_nodes[machine_pools.key].kind
          name = rancher2_machine_config_v2.machine_config_pool_nodes[machine_pools.key].name
        }
        machine_labels = machine_pools.value["labels"]
      }
    }
    machine_selector_config {
      config = yamlencode(local.machine_selector_config)
    }
    machine_global_config = yamlencode(merge({
      "cni"                         = var.container_network
      "kube-controller-manager-arg" = concat(["--node-cidr-mask-size=${var.node_network_cidr}"], var.machine_global_config.kube_controller_manager_arg)
      "kube-apiserver-arg"          = var.machine_global_config.kube_apiserver_arg
      "disable-kube-proxy"          = false
      "etcd-expose-metrics"         = var.machine_global_config.etcd_expose_metrics
    }))
    registries {
      dynamic "mirrors" {
        for_each = local.registry_mirrors
        content {
          hostname  = mirrors.value.hostname
          endpoints = mirrors.value.endpoints
        }
      }
    }
    upgrade_strategy {
      control_plane_concurrency = "10%"
      worker_concurrency        = "10%"
    }
    etcd {
      snapshot_schedule_cron = "0 */5 * * *"
      snapshot_retention     = 5
    }
    chart_values = <<EOF
harvester-cloud-provider:
  clusterName: ${var.cluster_name}
  cloudConfigPath: /var/lib/rancher/rke2/etc/config-files/cloud-provider-config
%{if var.container_network == "cilium"}
rke2-cilium:
  %{if var.cilium_options.enable_hubble}
  hubble:
    enabled: true
    relay:
      enabled: true
    ui:
      enabled: true
  %{endif}
  %{if var.cilium_options.enable_egressGateway}
  egressGateway:
    enabled: true
  bpf:
    masquerade: true
  kubeProxyReplacement: true
  l7Proxy: false
  %{endif}
%{endif}
EOF

    additional_manifest = <<EOT
${var.additional_manifest}
---
%{if var.nginx_enable_ssl_passthrough == true}---
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      extraArgs:
        enable-ssl-passthrough: true%{endif}
EOT
  }
}

resource "rancher2_cluster_role_template_binding" "rancher_guest_cluster" {
  name               = "crb-${rancher2_cluster_v2.rancher_guest_cluster.cluster_v1_id}"
  cluster_id         = rancher2_cluster_v2.rancher_guest_cluster.cluster_v1_id
  role_template_id   = "cluster-admin"
  group_principal_id = var.cluster_admin_group_name
}
