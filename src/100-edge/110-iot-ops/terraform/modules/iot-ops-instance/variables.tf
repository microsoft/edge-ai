variable "resource_group_id" {
  type        = string
  description = "The ID for the Resource Group for the resources."
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

variable "trust_source" {
  type    = string
  default = "SelfSigned"
  validation {
    condition     = var.trust_source == "SelfSigned" || var.trust_source == "CustomerManaged"
    error_message = "Trust source must be one of 'SelfSigned' or 'CustomerManaged'"
  }
  description = "Trust source must be one of 'SelfSigned' or 'CustomerManaged'. Defaults to SelfSigned."
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

variable "aio_features" {
  description = "AIO Instance features with mode ('Stable', 'Preview', 'Disabled') and settings ('Enabled', 'Disabled')."
  type = map(object({
    mode     = optional(string)
    settings = optional(map(string))
  }))
  default = null

  validation {
    condition = var.aio_features == null ? true : alltrue([
      for feature_name, feature in coalesce(var.aio_features, {}) :
      try(
        feature.mode == null ? true : contains(["Stable", "Preview", "Disabled"], feature.mode),
        true
      )
    ])
    error_message = "Feature mode must be one of: 'Stable', 'Preview', or 'Disabled'."
  }

  validation {
    condition = var.aio_features == null ? true : alltrue([
      for feature_name, feature in coalesce(var.aio_features, {}) :
      try(
        feature.settings == null ? true : alltrue([
          for setting_name, setting_value in feature.settings :
          contains(["Enabled", "Disabled"], setting_value)
        ]),
        true
      )
    ])
    error_message = "Feature settings values must be either 'Enabled' or 'Disabled'."
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
}

variable "should_deploy_resource_sync_rules" {
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
  description = "Values for AIO CustomerManaged trust resources"
}

variable "secret_store_cluster_extension_id" {
  type        = string
  description = "The resource ID of the Secret Store cluster extension"
}

variable "platform_cluster_extension_id" {
  type        = string
  description = "The resource ID of the AIO Platform cluster extension"
}

variable "should_enable_otel_collector" {
  type        = bool
  description = "Whether to deploy the OpenTelemetry Collector and Azure Monitor ConfigMap"
}

variable "aio_uami_id" {
  type        = string
  description = "The principal ID of the User Assigned Managed Identity for the Azure IoT Operations instance"
}

variable "should_create_anonymous_broker_listener" {
  type        = bool
  description = "Whether to enable an insecure anonymous AIO MQ Broker Listener. Should only be used for dev or test environments"
}

variable "broker_listener_anonymous_config" {
  type = object({
    serviceName = string
    port        = number
    nodePort    = number
  })
  description = <<-EOF
  Configuration for the insecure anonymous AIO MQ Broker Listener.

  For additional information, refer to: <https://learn.microsoft.com/azure/iot-operations/manage-mqtt-broker/howto-test-connection?tabs=bicep#node-port>
EOF
}
