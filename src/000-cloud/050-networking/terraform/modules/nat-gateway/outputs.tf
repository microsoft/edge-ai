/*
 * NAT Gateway Outputs
 */

output "nat_gateway" {
  description = "The NAT gateway resource"
  value = {
    id   = azurerm_nat_gateway.main.id
    name = azurerm_nat_gateway.main.name
  }
}

output "public_ips" {
  description = "Public IP resources associated with the NAT gateway keyed by name"
  value = {
    for pip in azurerm_public_ip.nat : pip.name => {
      id         = pip.id
      ip_address = pip.ip_address
    }
  }
}
