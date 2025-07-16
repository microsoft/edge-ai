variable "should_deploy_server_central_script" {
  type        = bool
  description = "Whether to deploy the server-central.sh script to the server VM."
}

variable "should_deploy_client_technology_script" {
  type        = bool
  description = "Whether to deploy the client-technology.sh script to the client VM."
}

variable "server_vm_id" {
  type        = string
  description = "The resource ID of the server VM (Cluster A)."
}

variable "client_vm_id" {
  type        = string
  description = "The resource ID of the client VM (Cluster B)."
}
