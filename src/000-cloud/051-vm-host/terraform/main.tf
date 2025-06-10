/**
 * # VM Host
 *
 * Deploys one or more Linux VMs for Arc-connected K3s cluster
 */

locals {
  label_prefix = "${var.resource_prefix}-aio-${var.environment}-${var.instance}"
  vm_username  = coalesce(var.vm_username, var.resource_prefix)
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "../.ssh/vm-${local.label_prefix}-id_rsa"
  file_permission = "600"
}

module "virtual_machine" {
  count  = var.host_machine_count
  source = "./modules/virtual-machine"

  label_prefix               = local.label_prefix
  location                   = var.location
  resource_group_name        = var.resource_group.name
  subnet_id                  = var.subnet_id
  vm_index                   = count.index
  vm_username                = local.vm_username
  vm_sku_size                = var.vm_sku_size
  ssh_public_key             = tls_private_key.ssh.public_key_openssh
  arc_onboarding_identity_id = try(var.arc_onboarding_identity.id, null)
}
