/*
 * Fabric Capacity Outputs
 */

output "fabric_capacity" {
  description = "Fabric capacity details."
  value = try(module.fabric_capacity[0].capacity, {
    id           = data.fabric_capacity.existing[0].id
    display_name = data.fabric_capacity.existing[0].display_name
    sku          = data.fabric_capacity.existing[0].sku
  }, null)
}

/*
 * Fabric Workspace Outputs
 */

output "fabric_workspace" {
  description = "Fabric workspace details."
  value = try(module.fabric_workspace[0].workspace, {
    id           = data.fabric_workspace.existing[0].id
    display_name = data.fabric_workspace.existing[0].display_name
  }, null)
}

/*
 * Fabric Lakehouse Outputs
 */

output "fabric_lakehouse" {
  description = "Fabric lakehouse details."
  value = try({
    id           = module.fabric_lakehouse[0].lakehouse_id
    display_name = module.fabric_lakehouse[0].lakehouse_name
  }, null)
}

/*
 * Fabric Eventhouse Outputs
 */

output "fabric_eventhouse" {
  description = "Fabric eventhouse details for real-time intelligence."
  value       = try(module.fabric_eventhouse[0].eventhouse, null)
}
