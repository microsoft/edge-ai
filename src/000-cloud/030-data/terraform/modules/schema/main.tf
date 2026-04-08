/**
 * # Schema Module
 *
 * Creates schemas and optional schema versions in an Azure Device Registry Schema Registry.
 * This module is designed for defining message schemas used by Azure IoT Operations dataflows.
 */

locals {
  processed_schemas = { for schema in var.schemas : schema.name => schema }

  schema_versions = merge([
    for schema_name, schema in local.processed_schemas : {
      for version_key, version in schema.versions :
      "${schema_name}/${version_key}" => {
        schema_name = schema_name
        version_key = version_key
        description = version.description
        content     = version.content
      }
    }
  ]...)
}

resource "azapi_resource" "schema" {
  for_each = local.processed_schemas

  type      = "Microsoft.DeviceRegistry/schemaRegistries/schemas@2026-04-01"
  name      = each.value.name
  parent_id = var.adr_schema_registry.id

  body = {
    properties = {
      displayName = coalesce(each.value.display_name, each.value.name)
      description = each.value.description
      format      = each.value.format
      schemaType  = each.value.type
    }
  }

  response_export_values    = ["name", "id"]
  schema_validation_enabled = false
}

resource "azapi_resource" "schema_version" {
  for_each = local.schema_versions

  type      = "Microsoft.DeviceRegistry/schemaRegistries/schemas/schemaVersions@2026-04-01"
  name      = each.value.version_key
  parent_id = azapi_resource.schema[each.value.schema_name].id

  body = {
    properties = {
      description   = each.value.description
      schemaContent = each.value.content
    }
  }

  response_export_values    = ["name", "id"]
  schema_validation_enabled = false
}
