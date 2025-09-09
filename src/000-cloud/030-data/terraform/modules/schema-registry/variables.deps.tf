variable "resource_group" {
  type = object({
    id   = string
    name = string
  })
  description = "Resource group object containing name and id where resources will be deployed"
}

variable "storage_account" {
  type = object({
    id                    = string
    name                  = string
    primary_blob_endpoint = string
  })
}
