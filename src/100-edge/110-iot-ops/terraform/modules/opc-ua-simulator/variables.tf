variable "resource_group" {
  type = object({
    id   = string
    name = string
  })
  description = "Name and ID of the pre-existing resource group in which to create resources"
}

variable "connected_cluster_name" {
  type        = string
  description = "The name of the connected cluster to deploy Azure IoT Operations to"
}
