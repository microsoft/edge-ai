resource "terraform_data" "defer" {
  input = {
    resource_group_name        = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    arc_connected_cluster_name = "arck-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "arc_extensions" {
  name = terraform_data.defer.input.resource_group_name
}

data "azapi_resource" "arc_connected_cluster" {
  type      = "Microsoft.Kubernetes/connectedClusters@2024-01-01"
  parent_id = data.azurerm_resource_group.arc_extensions.id
  name      = terraform_data.defer.input.arc_connected_cluster_name

  response_export_values = ["name", "id", "location"]
}

module "ci" {
  source = "../../terraform"

  arc_connected_cluster = data.azapi_resource.arc_connected_cluster.output
}
