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

variable "connected_cluster_location" {
  type        = string
  description = "The location of the connected cluster resource"
}

variable "trust_config_source" {
  type = string
  validation {
    condition     = var.trust_config_source == "SelfSigned" || var.trust_config_source == "CustomerManagedByoIssuer" || var.trust_config_source == "CustomerManagedGenerateIssuer"
    error_message = "TrustConfig source must be one of 'SelfSigned', 'CustomerManagedByoIssuer' or 'CustomerManagedGenerateIssuer'"
  }
  description = "TrustConfig source must be one of 'SelfSigned', 'CustomerManagedByoIssuer' or 'CustomerManagedGenerateIssuer'. Defaults to SelfSigned. When choosing CustomerManagedGenerateIssuer, ensure connectedk8s proxy is enabled on the cluster for current user. When choosing CustomerManagedByoIssuer, ensure an Issuer and ConfigMap resources exist in the cluster."
}

variable "customer_managed_trust_settings" {
  type = object({
    issuer_name    = string
    issuer_kind    = string
    configmap_name = string
    configmap_key  = string
  })
  description = "Values for AIO CustomerManaged trust resources"
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

variable "key_vault" {
  type = object({
    name = string
    id   = string
  })
  description = "The name and id of the existing key vault for Azure IoT Operations instance"
}

variable "sse_user_managed_identity" {
  type = object({
    id        = string
    client_id = string
  })
  description = "Secret Sync Extension user managed identity id and client id"
}

variable "aio_ca" {
  type = object({
    root_ca_cert_pem  = string
    ca_cert_chain_pem = string
    ca_key_pem        = string
  })
  sensitive   = true
  description = "Intermediate CA with Root CA certificate for the MQTT broker"
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

variable "enable_otel_collector" {
  type        = bool
  description = "Deploy the OpenTelemetry Collector and Azure Monitor ConfigMap (optionally used)"
}