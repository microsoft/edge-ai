variable "aio_namespace" {
  type        = string
  description = "Azure IoT Operations namespace"
}

variable "scripts" {
  type = list(
    object({
      files       = list(string)
      environment = map(any)
    })
  )
  description = "List of scripts to apply, the objects will be merged together to make one scripting call"
}

variable "connected_cluster_name" {
  type        = string
  description = "The name of the connected cluster to deploy Azure IoT Operations to"
}

variable "resource_group_name" {
  type        = string
  description = "The name for the resource group."
}
