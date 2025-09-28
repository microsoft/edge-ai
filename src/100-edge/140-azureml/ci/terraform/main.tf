/**
 * # Azure Machine Learning Arc Extension CI
 *
 * CI deployment configuration for Azure Machine Learning Arc extension
 * with minimal required parameters for component testing.
 */

// Defer computation to prevent `data` objects from querying for state on `terraform plan`.
// Needed for testing and build system compatibility.
resource "terraform_data" "defer" {
  input = {
    resource_group_name    = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    connected_cluster_name = "arck-${var.resource_prefix}-${var.environment}-${var.instance}"
    workspace_name         = "mlw-${var.resource_prefix}-${var.environment}-${var.instance}"
  }
}

data "azurerm_resource_group" "aio" {
  name = terraform_data.defer.output.resource_group_name
}

data "azapi_resource" "arc_connected_cluster" {
  type      = "Microsoft.Kubernetes/connectedClusters@2024-01-01"
  parent_id = data.azurerm_resource_group.aio.id
  name      = terraform_data.defer.output.connected_cluster_name

  response_export_values = ["name", "id", "location"]
}

data "azurerm_machine_learning_workspace" "azureml_workspace" {
  name                = terraform_data.defer.output.workspace_name
  resource_group_name = data.azurerm_resource_group.aio.name
}

module "ci" {
  source = "../../terraform"

  environment     = var.environment
  instance        = var.instance
  resource_prefix = var.resource_prefix
  location        = var.location

  connected_cluster               = data.azapi_resource.arc_connected_cluster.output
  resource_group                  = data.azurerm_resource_group.aio
  machine_learning_workspace      = data.azurerm_machine_learning_workspace.azureml_workspace
  workspace_identity_principal_id = try(data.azurerm_machine_learning_workspace.azureml_workspace.identity[0].principal_id, null)
}
