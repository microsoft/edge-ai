/**
 * # VM Host
 *
 * Deploys one or more Linux VMs for Arc-connected K3s cluster
 */

locals {
  label_prefix = "${var.resource_prefix}-aio-${var.environment}-${var.instance}"
  vm_username  = coalesce(var.vm_username, var.resource_prefix)

  // Combine current user (if enabled) with explicit admin principals
  vm_admin_principals = merge(
    var.vm_admin_principals,
    var.should_assign_current_user_vm_admin ? {
      "admin" = msgraph_resource_action.current_user[0].output.oid
    } : {}
  )
}

/*
 * Current User Data (Microsoft Graph)
 */

resource "msgraph_resource_action" "current_user" {
  count = var.should_assign_current_user_vm_admin ? 1 : 0

  method       = "GET"
  resource_url = "me"

  response_export_values = {
    oid = "id"
  }
}

// Generate random password for VM authentication when password auth is enabled
resource "random_password" "vm_admin" {
  count   = var.should_use_password_auth ? var.host_machine_count : 0
  length  = 20
  special = true
}

resource "tls_private_key" "ssh" {
  count     = var.should_create_ssh_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "private_key" {
  count           = var.should_create_ssh_key ? 1 : 0
  content         = tls_private_key.ssh[0].private_key_pem
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
  should_create_public_ip    = var.should_create_public_ip
  ssh_public_key             = var.should_create_ssh_key ? tls_private_key.ssh[0].public_key_openssh : null
  admin_password             = var.should_use_password_auth ? random_password.vm_admin[count.index].result : null
  arc_onboarding_identity_id = try(var.arc_onboarding_identity.id, null)

  // Spot pricing configuration
  vm_priority        = var.vm_priority
  vm_eviction_policy = var.vm_eviction_policy
  vm_max_bid_price   = var.vm_max_bid_price
}

// Install Azure AD SSH extension for RBAC-based authentication
resource "azurerm_virtual_machine_extension" "aad_ssh_login" {
  count = var.host_machine_count

  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = module.virtual_machine[count.index].vm_id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  depends_on = [module.virtual_machine]
}

// RBAC role assignments for Azure AD principals (includes current user if enabled)
resource "azurerm_role_assignment" "vm_admin_login" {
  for_each = local.vm_admin_principals

  principal_id         = each.value
  role_definition_name = "Virtual Machine Administrator Login"
  scope                = var.resource_group.id
}

resource "azurerm_role_assignment" "vm_user_login" {
  for_each = var.vm_user_principals

  principal_id         = each.value
  role_definition_name = "Virtual Machine User Login"
  scope                = var.resource_group.id
}
