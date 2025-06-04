/**
 * # Outputs for Kubernetes Assets
 *
 * This file defines outputs from the Kubernetes assets component.
 */

//
// Asset Endpoint Profile Outputs
//

output "asset_endpoint_profiles" {
  description = "Map of asset endpoint profiles created by this component."
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
  description = "Map of assets created by this component."
  value = {
    for name, asset in azapi_resource.asset : name => {
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
