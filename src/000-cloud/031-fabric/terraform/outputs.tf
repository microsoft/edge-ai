output "fabric_capacity" {
  description = "Fabric capacity details"
  value = {
    id   = module.fabric_capacity.capacity_id
    name = module.fabric_capacity.capacity_name
    sku  = module.fabric_capacity.capacity_sku
  }
}
