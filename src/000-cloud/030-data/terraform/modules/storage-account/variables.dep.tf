/*
 * Dependency Variables - Resources from other components
 */

variable "blob_dns_zone" {
  description = "Blob private DNS zone object from observability component with id and name properties. If not provided, a new zone will be created when should_create_blob_dns_zone is true."
  type = object({
    id   = string
    name = string
  })
  default = null
}
