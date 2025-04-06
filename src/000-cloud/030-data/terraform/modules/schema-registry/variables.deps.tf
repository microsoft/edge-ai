variable "resource_group" {
  type = object({
    id   = string
    name = string
  })
}

variable "storage_account" {
  type = object({
    id                    = string
    name                  = string
    primary_blob_endpoint = string
  })
}
