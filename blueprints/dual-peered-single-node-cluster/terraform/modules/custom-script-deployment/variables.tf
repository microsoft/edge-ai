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

variable "enterprise_broker_server_cert_secret_name" {
  type        = string
  description = "The name of the Kubernetes secret containing the broker server certificate"
}

variable "enterprise_client_ca_configmap_name" {
  type        = string
  description = "The name of the Kubernetes configmap containing the client CA certificate"
}

variable "site_client_secret_name" {
  type        = string
  description = "The name of the Kubernetes secret containing the client certificate and key"
}

variable "site_tls_ca_configmap_name" {
  type        = string
  description = "The name of the Kubernetes configmap containing the TLS CA certificate"
}
