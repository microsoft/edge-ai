locals {
  default_http_proxy_env = {
    "HTTP_PROXY"  = "${var.http_proxy}"
    "HTTPS_PROXY" = "${var.http_proxy}"
    "NO_PROXY"    = "10.0.0.0/8,localhost,127.0.0.1,.bmwgroup.net,.muc,.bmw,.cloud"
    "http_proxy"  = "${var.http_proxy}"
    "https_proxy" = "${var.http_proxy}"
    "no_proxy"    = "10.0.0.0/8,localhost,127.0.0.1,.bmwgroup.net,.muc,.bmw,.cloud"
  }

  default_container_registry_mirrors = tomap({
    "registry.rancher.com" = {
      endpoints = ["https://rancher.edge-registry.bmwgroup.net"]
    },
    "docker.io" = {
      endpoints = ["https://docker.edge-registry.bmwgroup.net"]
    }
  })

  default_cilium_options = {
    enable_egressGateway = true
    enable_hubble        = true
  }

  default_image_name = var.image_name
  default_ssh_user   = "cloud" # "cloud" for SUSE images, "ubuntu" for ubuntu images
  default_user_data  = <<-EOF
    ## template: jinja
    #cloud-config
    package_update: true
    packages:
    - qemu-guest-agent
    - linux-modules-extra-{{ v1.kernel_release }}
    runcmd:
    - - systemctl
      - enable
      - '--now'
      - qemu-guest-agent.service
    # Configurations for Azure IOT Operations
    - echo "fs.inotify.max_user_instances=8192" | tee -a /etc/sysctl.conf
    - echo "fs.inotify.max_user_watches=524288" | tee -a /etc/sysctl.conf
    - echo "fs.file-max=100000" | tee -a /etc/sysctl.conf
    - echo 512 | tee /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
    - echo "vm.nr_hugepages=512" | tee /etc/sysctl.d/99-hugepages.conf
    - [sysctl, -p]
    EOF

  rancher_machine_pools = {
    "xs" = [
      {
        name               = "controlplane-zone1"
        node_count         = 1
        cpu_count          = 4
        memory_size        = 16
        disk_size          = 40
        network_name       = "harvester-public/public-vlan-2104"
        image_name         = local.default_image_name
        ssh_user           = "cloud"
        availability_zone  = "zone1"
        labels             = {}
        control_plane_role = true
        etcd_role          = true
        worker_role        = true
        user_data          = local.default_user_data
      },
    ],
    "s" = [
      {
        name               = "node-zone1"
        node_count         = 1
        cpu_count          = 8
        memory_size        = 16
        disk_size          = 40
        network_name       = "harvester-public/public-vlan-2104"
        image_name         = local.default_image_name
        ssh_user           = "cloud"
        availability_zone  = "zone1"
        labels             = {}
        control_plane_role = true
        etcd_role          = true
        worker_role        = true
        user_data          = local.default_user_data
      },
      {
        name               = "node-zone2"
        node_count         = 1
        cpu_count          = 8
        memory_size        = 16
        disk_size          = 40
        network_name       = "harvester-public/public-vlan-2104"
        image_name         = local.default_image_name
        ssh_user           = "cloud"
        availability_zone  = "zone2"
        labels             = {}
        control_plane_role = true
        etcd_role          = true
        worker_role        = true
        user_data          = local.default_user_data
      },
      {
        name               = "node-zone3"
        node_count         = 1
        cpu_count          = 8
        memory_size        = 16
        disk_size          = 40
        network_name       = "harvester-public/public-vlan-2104"
        image_name         = local.default_image_name
        ssh_user           = "cloud"
        availability_zone  = "zone3"
        labels             = {}
        control_plane_role = true
        etcd_role          = true
        worker_role        = true
        user_data          = local.default_user_data
      }
    ]
    "m" = [
      {
        name               = "controlplane-zone1"
        node_count         = 1
        cpu_count          = 4
        memory_size        = 8
        disk_size          = 40
        network_name       = "harvester-public/public-vlan-2104"
        image_name         = local.default_image_name
        ssh_user           = "cloud"
        availability_zone  = "zone1"
        labels             = {}
        control_plane_role = true
        etcd_role          = true
        worker_role        = false
        user_data          = local.default_user_data
      },
      {
        name               = "controlplane-zone2"
        node_count         = 1
        cpu_count          = 4
        memory_size        = 8
        disk_size          = 40
        network_name       = "harvester-public/public-vlan-2104"
        image_name         = local.default_image_name
        ssh_user           = "cloud"
        availability_zone  = "zone2"
        labels             = {}
        control_plane_role = true
        etcd_role          = true
        worker_role        = false
        user_data          = local.default_user_data
      },
      {
        name               = "controlplane-zone3"
        node_count         = 1
        cpu_count          = 4
        memory_size        = 8
        disk_size          = 40
        network_name       = "harvester-public/public-vlan-2104"
        image_name         = local.default_image_name
        ssh_user           = "cloud"
        availability_zone  = "zone3"
        labels             = {}
        control_plane_role = true
        etcd_role          = true
        worker_role        = false
        user_data          = local.default_user_data
      },
      {
        name               = "worker-zone1"
        node_count         = 1
        cpu_count          = 12
        memory_size        = 16
        disk_size          = 40
        network_name       = "harvester-public/public-vlan-2104"
        image_name         = local.default_image_name
        ssh_user           = "cloud"
        availability_zone  = "zone1"
        labels             = {}
        control_plane_role = false
        etcd_role          = false
        worker_role        = true
        user_data          = local.default_user_data
      },
      {
        name               = "worker-zone2"
        node_count         = 1
        cpu_count          = 12
        memory_size        = 16
        disk_size          = 40
        network_name       = "harvester-public/public-vlan-2104"
        image_name         = local.default_image_name
        ssh_user           = "cloud"
        availability_zone  = "zone2"
        labels             = {}
        control_plane_role = false
        etcd_role          = false
        worker_role        = true
        user_data          = local.default_user_data
      },
      {
        name               = "worker-zone3"
        node_count         = 1
        cpu_count          = 12
        memory_size        = 16
        disk_size          = 40
        network_name       = "harvester-public/public-vlan-2104"
        image_name         = local.default_image_name
        ssh_user           = "cloud"
        availability_zone  = "zone3"
        labels             = {}
        control_plane_role = false
        etcd_role          = false
        worker_role        = true
        user_data          = local.default_user_data
      }
    ]
  }
}