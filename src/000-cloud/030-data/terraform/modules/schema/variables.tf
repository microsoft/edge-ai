/*
 * Schema Dependency Parameters
 */

variable "adr_schema_registry" {
  type = object({
    id = string
  })
  description = "The Azure Device Registry schema registry object"
}

/*
 * Schema Parameters
 */

variable "schemas" {
  type = list(object({
    name         = string
    display_name = optional(string)
    description  = optional(string)
    format       = optional(string, "JsonSchema/draft-07")
    type         = optional(string, "MessageSchema")
    versions = map(object({
      description = string
      content     = string
    }))
  }))
  description = "List of schemas to create in the schema registry with their versions"
}
