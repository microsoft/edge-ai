output "local_network_gateways" {
  description = "Local network gateway resources keyed by site name"
  value = {
    for name, gateway in azurerm_local_network_gateway.this :
    name => {
      id                 = gateway.id
      name               = gateway.name
      resource_group     = gateway.resource_group_name
      address_space      = gateway.address_space
      provisioning_state = try(gateway.provisioning_state, null)
    }
  }
}

output "site_connections" {
  description = "Site-to-site VPN connections keyed by site name"
  value = {
    for name, connection in azurerm_virtual_network_gateway_connection.this :
    name => {
      id                         = connection.id
      name                       = connection.name
      connection_status          = try(connection.connection_status, null)
      provisioning_state         = try(connection.provisioning_state, null)
      local_gateway_id           = connection.local_network_gateway_id
      shared_key_reference       = local.sites_by_name[name].shared_key_reference
      use_policy_based_selectors = try(local.sites_by_name[name].use_policy_based_selectors, false)
    }
  }
}
