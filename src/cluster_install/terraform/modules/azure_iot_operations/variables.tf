variable "resource_group_name" {
  type        = string
  description = "Name of the pre-existing resource group in which to create resources"
}

variable "connected_cluster_name" {
  type        = string
  description = "The name of the connected cluster to deploy Azure IoT Operations to"
}

variable "connected_cluster_location" {
  type        = string
  description = "The location of the connected cluster resource"
}

variable "trust_config" {
  type = object({
    source = string
  })
  description = "TrustConfig must be one of 'SelfSigned' or 'CustomerManaged'. Defaults to SelfSigned."
}

variable "platform" {
  type = object({
    version = string
    train   = string
  })
  default = {
    version = "0.7.6"
    train   = "preview"
  }
}

variable "metrics" {
  type = object({
    enabled               = bool
    otelCollectorAddress  = string
    exportIntervalSeconds = number
  })
  default = {
    enabled               = false
    otelCollectorAddress  = ""
    exportIntervalSeconds = 60
  }
}

variable "operations_config" {
  type = object({
    namespace                      = string
    kubernetesDistro               = string
    version                        = string
    train                          = string
    agentOperationTimeoutInMinutes = number
  })
  default = {
    namespace                      = "azure-iot-operations"
    kubernetesDistro               = "K3s"
    version                        = "1.0.9"
    train                          = "stable"
    agentOperationTimeoutInMinutes = 120
  }
}

variable "schema_registry_id" {
  type        = string
  description = "The resource ID of the schema registry for Azure IoT Operations instance"
}

variable "mqtt_broker_config" {
  type = object({
    brokerListenerServiceName = string
    brokerListenerPort        = number
    serviceAccountAudience    = string
    frontendReplicas          = number
    frontendWorkers           = number
    backendRedundancyFactor   = number
    backendWorkers            = number
    backendPartitions         = number
    memoryProfile             = string
    serviceType               = string
  })
  default = {
    brokerListenerServiceName = "aio-broker"
    brokerListenerPort        = 18883
    serviceAccountAudience    = "aio-internal"
    frontendReplicas          = 1
    frontendWorkers           = 1
    backendRedundancyFactor   = 2
    backendWorkers            = 1
    backendPartitions         = 1
    memoryProfile             = "Low"
    serviceType               = "ClusterIp"
  }
}

variable "deploy_resource_sync_rules" {
  type        = bool
  default     = false
  description = "Deploys resource sync rules if set to true"
}

variable "dataflow_instance_count" {
  type        = number
  default     = 1
  description = "Number of dataflow instances. Defaults to 1."
}

variable "key_vault_name" {
  type        = string
  description = "The name of the existing key vault for Azure IoT Operations instance"
}

variable "sse_user_managed_identity_name" {
  type        = string
  description = "Secret Sync Extension user managed identity name"
}

variable "aio_root_ca" {
  type = object({
    cert_pem        = string
    private_key_pem = string
  })
  sensitive   = true
  description = "Root CA for the MQTT broker"
}

variable "enable_instance_secret_sync" {
  type        = bool
  default     = true
  description = "Enable secret sync at the AIO instance level"
}

variable "aio_platform_config" {
  type = object({
    install_cert_manager  = bool
    install_trust_manager = bool
  })
  default = {
    install_cert_manager  = true
    install_trust_manager = true
  }
  description = "Install cert-manager and trust-manager extensions"
}

variable "secret_sync_controller" {
  type = object({
    version = string
    train   = string
  })
  default = {
    version = "0.6.7"
    train   = "preview"
  }
}

variable "edge_storage_accelerator" {
  type = object({
    version               = string
    train                 = string
    diskStorageClass      = string
    faultToleranceEnabled = bool
  })
  default = {
    version               = "2.2.2"
    train                 = "stable"
    diskStorageClass      = ""
    faultToleranceEnabled = false
  }
}

variable "open_service_mesh" {
  type = object({
    version = string
    train   = string
  })
  default = {
    version = "1.2.10"
    train   = "stable"
  }
}
