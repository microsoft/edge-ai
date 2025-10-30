/**
 * # Virtual Machine Module
 *
 * Deploys a Linux VM with Azure AD RBAC authentication and optional Arc connectivity.
 * SSH keys are optional for emergency fallback; Azure AD authentication is primary.
 */

// Optional public IP for VMs that need internet accessibility
resource "azurerm_public_ip" "aio_edge" {
  count               = var.should_create_public_ip ? 1 : 0
  name                = "pip-${var.label_prefix}-${var.vm_index}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "dns-${var.label_prefix}-${var.vm_index}"
}

resource "azurerm_network_interface" "aio_edge" {
  name                = "nic-${var.label_prefix}-${var.vm_index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig-${var.label_prefix}-${var.vm_index}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = try(azurerm_public_ip.aio_edge[0].id, null)
    subnet_id                     = var.subnet_id
  }
}

resource "azurerm_linux_virtual_machine" "aio_edge" {
  name                            = "vm-${var.label_prefix}-${var.vm_index}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  admin_username                  = var.vm_username
  admin_password                  = var.admin_password
  disable_password_authentication = var.admin_password == null

  // Optional SSH key for emergency fallback (Azure AD authentication is primary)
  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != null ? [1] : []
    content {
      username   = var.vm_username
      public_key = var.ssh_public_key
    }
  }

  provision_vm_agent         = true
  allow_extension_operations = true
  size                       = var.vm_sku_size

  // Spot pricing support
  priority        = var.vm_priority
  eviction_policy = var.vm_priority == "Spot" ? var.vm_eviction_policy : null
  max_bid_price   = var.vm_priority == "Spot" ? var.vm_max_bid_price : null

  network_interface_ids = [
    azurerm_network_interface.aio_edge.id
  ]

  source_image_reference {
    offer     = "0001-com-ubuntu-server-jammy"
    publisher = "Canonical"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  // Always enable system-assigned identity for Azure AD SSH
  // Optionally include user-assigned identity for Arc onboarding
  identity {
    type         = var.arc_onboarding_identity_id != null ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.arc_onboarding_identity_id != null ? [var.arc_onboarding_identity_id] : null
  }

  bypass_platform_safety_checks_on_user_schedule_enabled = true
  patch_assessment_mode                                  = "AutomaticByPlatform"
  patch_mode                                             = "AutomaticByPlatform"
}
