/**
 * # Virtual Machine Module
 *
 * Deploys a Linux VM with configuration for Arc-connected K3s cluster
 */

resource "azurerm_public_ip" "aio_edge" {
  name                = "pip-${var.label_prefix}-${var.vm_index}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Basic"
  domain_name_label   = "dns-${var.label_prefix}-${var.vm_index}"
}

resource "azurerm_network_interface" "aio_edge" {
  name                = "nic-${var.label_prefix}-${var.vm_index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig-${var.label_prefix}-${var.vm_index}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.aio_edge.id
    subnet_id                     = var.subnet_id
  }
}

resource "azurerm_linux_virtual_machine" "aio_edge" {
  name                            = "vm-${var.label_prefix}-${var.vm_index}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  admin_username                  = var.vm_username
  disable_password_authentication = true
  admin_ssh_key {
    username   = var.vm_username
    public_key = var.ssh_public_key
  }

  provision_vm_agent         = true
  allow_extension_operations = true
  size                       = var.vm_sku_size
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
  dynamic "identity" {
    for_each = var.arc_onboarding_identity_id != null ? [1] : []
    content {
      type = "UserAssigned"
      identity_ids = [
        var.arc_onboarding_identity_id
      ]
    }
  }

  bypass_platform_safety_checks_on_user_schedule_enabled = true
  patch_assessment_mode                                  = "AutomaticByPlatform"
  patch_mode                                             = "AutomaticByPlatform"
}
