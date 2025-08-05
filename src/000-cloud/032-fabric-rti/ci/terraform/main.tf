# Defer computation to prevent `data` objects from querying for state on `terraform plan`.
# Needed for testing and build system.
resource "terraform_data" "defer" {
  input = {
    resource_group_name    = "rg-${var.resource_prefix}-${var.environment}-${var.instance}"
    fabric_workspace_name  = coalesce(var.fabric_workspace_name, "ws-${var.resource_prefix}-${var.environment}-${var.instance}")
    fabric_eventhouse_name = coalesce(var.fabric_eventhouse_name, "evh-${var.resource_prefix}-${var.environment}-${var.instance}")
  }
}

data "fabric_workspace" "workspace" {
  display_name = terraform_data.defer.output.fabric_workspace_name
}

data "fabric_eventhouse" "eventhouse" {
  workspace_id = data.fabric_workspace.workspace.id
  display_name = terraform_data.defer.output.fabric_eventhouse_name
}

module "ci" {
  source = "../../terraform"

  resource_prefix = var.resource_prefix
  environment     = var.environment
  instance        = var.instance

  fabric_workspace = data.fabric_workspace.workspace

  // Simple DAG configuration for CI testing
  sources_custom_endpoints = [{
    name = "aio-telemetry"
  }]

  streams_default = [{
    name       = "aio-telemetry-stream"
    inputNodes = ["aio-telemetry"]
  }]

  destinations_eventhouse = [{
    name       = "real-time-analytics"
    inputNodes = ["aio-telemetry-stream"]
    properties = {
      workspaceId  = data.fabric_workspace.workspace.id
      itemId       = tolist(data.fabric_eventhouse.eventhouse.properties.database_ids)[0]
      databaseName = data.fabric_eventhouse.eventhouse.display_name
      inputSerialization = {
        type = "Json"
        properties = {
          encoding = "UTF8"
        }
      }
    }
  }]
}
