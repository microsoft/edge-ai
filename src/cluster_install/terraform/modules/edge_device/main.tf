/**
 * # Edge Device Module
 *
 * Deploys a Linux VM with an Arc-connected K3s cluster
 *
 */

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}
data "azuread_service_principal" "custom_locations" {
  # ref: https://learn.microsoft.com/en-us/azure/iot-operations/deploy-iot-ops/howto-prepare-cluster?tabs=ubuntu#arc-enable-your-cluster
  client_id = "bc313c14-388c-4e7d-a58e-70017303ee3b" #gitleaks:allow
  count     = var.custom_locations_oid != "" ? 0 : 1
}

resource "random_string" "vm_username" {
  length  = 10
  special = false
}

locals {
  label_prefix         = "${var.resource_prefix}-aio-edge"
  vm_username          = var.vm_username != "" ? var.vm_username : random_string.vm_username.result
  arc_resource_name    = "${var.resource_prefix}-arc"
  custom_locations_oid = var.custom_locations_oid != "" ? var.custom_locations_oid : data.azuread_service_principal.custom_locations[0].object_id
}

### Create Virtual Edge Device ###

resource "azurerm_public_ip" "aio_edge" {
  name                = "${local.label_prefix}-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Basic"
  domain_name_label   = "a-${local.label_prefix}-dns"
}

resource "azurerm_network_security_group" "aio_edge" {
  name                = "${local.label_prefix}-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_virtual_network" "aio_edge" {
  name                = "${local.label_prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "aio_edge" {
  resource_group_name  = var.resource_group_name
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
  resource_group_name = var.resource_group_name

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

resource "local_file" "ssh" {
  content         = tls_private_key.vm_ssh.private_key_pem
  filename        = "../.ssh/id_rsa"
  file_permission = "600"
}

resource "azurerm_linux_virtual_machine" "aio_edge" {
  name                            = "${local.label_prefix}-vm"
  location                        = var.location
  resource_group_name             = var.resource_group_name
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
  custom_data = base64encode(templatefile("${path.module}/cloud-init.template.yaml", {
    "ARC_SP_CLIENT_ID"               = var.arc_sp_client_id
    "ARC_SP_SECRET"                  = var.arc_sp_secret
    "VM_USERNAME"                    = local.vm_username
    "TENANT_ID"                      = data.azurerm_subscription.current.tenant_id
    "VM_RESOURCE_GROUP"              = var.resource_group_name
    "ARC_RESOURCE_NAME"              = local.arc_resource_name
    "ARC_AUTO_UPGRADE"               = var.arc_auto_upgrade
    "ENVIRONMENT"                    = var.environment
    "ADD_CURRENT_USER_CLUSTER_ADMIN" = var.add_current_entra_user_cluster_admin
    "AAD_CURRENT_USER_ID"            = data.azurerm_client_config.current.object_id
    "CUSTOM_LOCATIONS_OID"           = local.custom_locations_oid
  }))

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
}

resource "terraform_data" "wait_connected_cluster_exists" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "while [[ -z $(az connectedk8s show -n ${local.arc_resource_name} -g ${var.resource_group_name} 2>/dev/null) ]]; do sleep 5; done; sleep 3;"
  }
  depends_on = [azurerm_linux_virtual_machine.aio_edge]
}
