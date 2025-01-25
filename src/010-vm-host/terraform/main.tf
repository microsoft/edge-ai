/**
 * # VM Host
 *
 * Deploys a Linux VM with an Arc-connected K3s cluster
 */

locals {
  label_prefix = "${var.resource_prefix}-aio-edge"
  vm_username  = coalesce(var.vm_username, var.resource_prefix)
}

# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name = coalesce(
      var.resource_group_name,
      "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    )
  }
}

data "azurerm_resource_group" "this" {
  name = terraform_data.defer.output.resource_group_name
}

data "azurerm_user_assigned_identity" "arc_onboarding" {
  count = var.enable_arc_onboarding_user_managed_identity ? 1 : 0

  name = coalesce(
    var.arc_onboarding_user_managed_identity_name,
    "${var.resource_prefix}-arc-aio-mi"
  )
  resource_group_name = data.azurerm_resource_group.this.name
}

### Create Virtual Edge Device ###

resource "azurerm_public_ip" "aio_edge" {
  name                = "${local.label_prefix}-ip"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Basic"
  domain_name_label   = "a-${local.label_prefix}-dns"
}

resource "azurerm_network_security_group" "aio_edge" {
  name                = "${local.label_prefix}-nsg"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = var.location
}

resource "azurerm_virtual_network" "aio_edge" {
  name                = "${local.label_prefix}-vnet"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "aio_edge" {
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.aio_edge.name
  name                 = "${local.label_prefix}-subnet"
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "aio_edge" {
  subnet_id                 = azurerm_subnet.aio_edge.id
  network_security_group_id = azurerm_network_security_group.aio_edge.id
}

resource "azurerm_network_interface" "aio_edge" {
  name                = "${local.label_prefix}-nic"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name

  ip_configuration {
    name                          = "${local.label_prefix}-ipconfig"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.aio_edge.id
    subnet_id                     = azurerm_subnet.aio_edge.id
  }
}
resource "tls_private_key" "vm_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "ssh" {
  content         = tls_private_key.vm_ssh.private_key_pem
  filename        = "../.ssh/id_rsa"
  file_permission = "600"
}

resource "azurerm_linux_virtual_machine" "aio_edge" {
  name                            = "${local.label_prefix}-vm"
  location                        = var.location
  resource_group_name             = data.azurerm_resource_group.this.name
  admin_username                  = local.vm_username
  disable_password_authentication = true
  admin_ssh_key {
    username   = local.vm_username
    public_key = tls_private_key.vm_ssh.public_key_openssh
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
    for_each = data.azurerm_user_assigned_identity.arc_onboarding

    content {
      type = "UserAssigned"
      identity_ids = [
        identity.value.id
      ]
    }
  }

  bypass_platform_safety_checks_on_user_schedule_enabled = true
  patch_assessment_mode                                  = "AutomaticByPlatform"
  patch_mode                                             = "AutomaticByPlatform"
}
