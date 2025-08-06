variable "enterprise_vm_private_ip" {
  type        = string
  description = "The private IP address of the enterprise VM (cluster A)."
}

variable "enterprise_broker_port" {
  type        = number
  description = "The port number for the enterprise MQTT broker listener"
}

variable "enterprise_broker_tls_cert_secret_name" {
  type        = string
  description = "The name of the Kubernetes secret containing the broker tls certificate"
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

variable "site_aio_instance" {
  type        = any
  description = "Site Azure IoT Operations instance object from the IoT Operations module"
}

variable "site_aio_dataflow_profile" {
  type        = any
  description = "Site Azure IoT Operations dataflow profile object from the IoT Operations module"
}

variable "site_custom_locations" {
  type = object({
    id   = string
    name = string
  })
  description = "Custom locations object for the site cluster"
}

variable "enterprise_aio_instance" {
  type        = any
  description = "Enterprise Azure IoT Operations instance object from the IoT Operations module"
}

variable "enterprise_custom_locations" {
  type = object({
    id   = string
    name = string
  })
  description = "Custom locations object for the enterprise cluster"
}
