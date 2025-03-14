/*
 * Required Variables
 */

variable "aio_resource_group" {
  type = object({
    name = string
    id   = optional(string)
  })
}

/*
 * Optional Variables
 */

variable "cluster_server_virtual_machine" {
  type = object({
    id = string
  })
}

variable "cluster_node_virtual_machines" {
  type = list(object({
    id = string
  }))
}

variable "arc_onboarding_sp_client_id" {
  type        = string
  description = "If using, the Service Principal Client ID with 'Kubernetes Cluster - Azure Arc Onboarding' permissions. (Otherwise, not used and will attempt to use identity of the host)"
}

variable "arc_onboarding_sp_client_secret" {
  type        = string
  description = "If using, the Service Principal Client Secret to use for automation. (Otherwise, not used and will attempt to use identity of the host)"
  sensitive   = true
}
