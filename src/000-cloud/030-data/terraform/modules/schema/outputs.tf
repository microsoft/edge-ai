/*
 * Schema Outputs
 */

output "schemas" {
  description = "Map of schema resources by name with their versions."
  value = {
    for name, schema in azapi_resource.schema : name => {
      id   = schema.id
      name = schema.output.name
      versions = {
        for key, version in azapi_resource.schema_version :
        version.output.name => {
          id   = version.id
          name = version.output.name
        }
        if startswith(key, "${name}/")
      }
    }
  }
}
