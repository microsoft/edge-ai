variable "resource_group_id" {
  type        = string
  description = "ID of the resource group to create resources in"
}

variable "connected_cluster_name" {
  type        = string
  description = "The name of the connected cluster to deploy Azure IoT Operations to"
}

variable "arc_connected_cluster_id" {
  type        = string
  description = "The resource ID of the connected cluster to deploy Azure IoT Operations Platform to"
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

variable "metrics" {
  type = object({
    enabled               = bool
    otelCollectorAddress  = string
    exportIntervalSeconds = number
  })
}

variable "operations_config" {
  type = object({
    namespace                      = string
    kubernetesDistro               = string
    version                        = string
    train                          = string
    agentOperationTimeoutInMinutes = number
  })
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
}

variable "deploy_resource_sync_rules" {
  type        = bool
  description = "Deploys resource sync rules if set to true"
}

variable "dataflow_instance_count" {
  type        = number
  description = "Number of dataflow instances. Defaults to 1."
}

variable "customer_managed_trust_settings" {
  type = object({
    issuer_name    = string
    issuer_kind    = string
    configmap_name = string
    configmap_key  = string
  })
  description = "Settings for CustomerManaged trust resources"
}

variable "secret_store_cluster_extension_id" {
  type        = string
  description = "The resource ID of the Secret Store cluster extension"
}

variable "platform_cluster_extension_id" {
  type        = string
  description = "The resource ID of the AIO Platform cluster extension"
}
