/**
 * # Outputs for Kubernetes Assets
 *
 * This file defines outputs from the Kubernetes assets component using
 * both the namespaced Device Registry model and legacy asset models.
 */

//
// Asset Endpoint Profile Outputs
//

output "asset_endpoint_profiles" {
  description = "Map of legacy asset endpoint profiles created by this component."
  value = {
    for name, profile in azapi_resource.asset_endpoint_profile : name => {
      id   = profile.id
      name = profile.name
    }
  }
}

//
// Asset Outputs
//

output "assets" {
  description = "Map of legacy assets created by this component."
  value = {
    for name, asset in azapi_resource.asset : name => {
      id   = asset.id
      name = asset.name
    }
  }
}

//
// Namespaced Device Outputs
# //

output "namespaced_devices" {
  description = "Map of namespaced devices created by this component."
  value = {
    for name, device in azapi_resource.namespaced_device : name => {
      id   = device.id
      name = device.name
    }
  }
}

//
// Namespaced Asset Outputs
//

output "namespaced_assets" {
  description = "Map of namespaced assets created by this component."
  value = {
    for name, asset in azapi_resource.namespaced_asset : name => {
      id   = asset.id
      name = asset.name
    }
  }
}

//
// Feature Flags
//

output "should_enable_opc_asset_discovery" {
  description = "Whether OPC simulation asset discovery is enabled for any endpoint profile."
  value       = local.should_enable_opc_asset_discovery
}
