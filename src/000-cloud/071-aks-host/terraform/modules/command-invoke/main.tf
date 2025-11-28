/**
 * # Command Invoke Module
 *
 * Internal module for executing AKS Run Command actions with optional file attachments.
 */

locals {
  has_attachments = try(coalesce(var.file_path, var.folder_path), null) != null
}

resource "archive_file" "attachments" {
  count       = local.has_attachments ? 1 : 0
  type        = "zip"
  output_path = "${path.root}/out/context-${basename(coalesce(var.file_path, var.folder_path))}.zip"

  source_dir = try(coalesce(var.folder_path), null)

  dynamic "source" {
    for_each = var.file_path != null ? [1] : []
    content {
      filename = basename(var.file_path)
      content  = file(var.file_path)
    }
  }
}

resource "azapi_resource_action" "command_invoke" {
  depends_on = [archive_file.attachments]

  type        = "Microsoft.ContainerService/managedClusters@2023-10-01"
  resource_id = var.cluster_id
  action      = "runCommand"
  method      = "POST"
  body = merge(
    {
      command = var.command
    },
    local.has_attachments ?
    {
      // filebase64 requires the value to be built on an attribute to avoid null path during plan
      context = filebase64(archive_file.attachments[0].id != null ? archive_file.attachments[0].output_path : null)
    } : {}
  )
  response_export_values = ["*"]

  lifecycle {
    ignore_changes = [
      body["context"]
    ]
  }

  timeouts {
    create = "${var.timeout_minutes}m"
  }
}
