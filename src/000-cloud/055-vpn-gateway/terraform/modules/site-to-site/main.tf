/**
 * # Site-to-Site VPN Connections
 *
 * Creates Azure Local Network Gateways and VPN Gateway Connections for
 * on-premises sites defined by the parent component.
 */

locals {
  sites_by_name = { for site in var.sites : site.name => site }
  site_name_slugs = {
    for name in keys(local.sites_by_name) :
    name => trim(substr(replace(lower(name), "[^0-9a-z]", "-"), 0, 30), "-")
  }
}

resource "azurerm_local_network_gateway" "this" {
  for_each            = local.sites_by_name
  name                = format("lng-%s-%s-%s-%s", var.resource_prefix, local.site_name_slugs[each.key], var.environment, var.instance)
  resource_group_name = var.resource_group.name
  location            = var.location
  address_space       = each.value.address_spaces
  gateway_address     = try(each.value.gateway_ip_address, null)
  gateway_fqdn        = try(each.value.gateway_fqdn, null)

  dynamic "bgp_settings" {
    for_each = try(each.value.bgp_settings, null) == null ? [] : [each.value.bgp_settings]
    content {
      asn                 = bgp_settings.value.asn
      bgp_peering_address = bgp_settings.value.peer_address
      peer_weight         = coalesce(try(bgp_settings.value.peer_weight, null), 0)
    }
  }
}

resource "azurerm_virtual_network_gateway_connection" "this" {
  for_each                           = local.sites_by_name
  name                               = format("conn-%s-%s-%s-%s", local.site_name_slugs[each.key], var.resource_prefix, var.environment, var.instance)
  location                           = var.location
  resource_group_name                = var.resource_group.name
  type                               = "IPsec"
  virtual_network_gateway_id         = var.vpn_gateway_id
  local_network_gateway_id           = azurerm_local_network_gateway.this[each.key].id
  shared_key                         = var.shared_keys[each.value.shared_key_reference]
  connection_protocol                = try(each.value.ike_protocol, "IKEv2")
  connection_mode                    = try(each.value.connection_mode, "Default")
  dpd_timeout_seconds                = try(each.value.dpd_timeout_seconds, null)
  use_policy_based_traffic_selectors = try(each.value.use_policy_based_selectors, false)

  dynamic "ipsec_policy" {
    for_each = try(each.value.ipsec_policy, null) == null ? [] : [each.value.ipsec_policy]
    content {
      ike_encryption   = ipsec_policy.value.ike_encryption
      ike_integrity    = ipsec_policy.value.ike_integrity
      dh_group         = ipsec_policy.value.dh_group
      ipsec_encryption = ipsec_policy.value.ipsec_encryption
      ipsec_integrity  = ipsec_policy.value.ipsec_integrity
      pfs_group        = ipsec_policy.value.pfs_group
      sa_lifetime      = try(ipsec_policy.value.sa_lifetime_seconds, null)
      sa_datasize      = try(ipsec_policy.value.sa_datasize_kb, null)
    }
  }

  lifecycle {
    precondition {
      condition     = contains(keys(var.shared_keys), each.value.shared_key_reference)
      error_message = "Missing shared key for VPN site. Provide the value in vpn_site_shared_keys using the shared_key_reference field."
    }
  }
}
