/*
 * Optional Variables
 *
 * IMPORTANT: The 'operations_config' variable in this file is explicitly referenced by the
 * aio-version-checker.py script to check IoT Operations instance versions. If you rename this
 * variable or change its structure, you must also update the script and the
 * aio-version-checker-template.yml pipeline.
 */

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
    version                        = "1.1.59"
    train                          = "integration"
    agentOperationTimeoutInMinutes = 120
  }
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

variable "dataflow_instance_count" {
  type        = number
  default     = 1
  description = "Number of dataflow instances. Defaults to 1."
}

variable "should_deploy_resource_sync_rules" {
  type        = bool
  default     = false
  description = "Deploys resource sync rules if set to true"
}

variable "enable_instance_secret_sync" {
  type        = bool
  default     = true
  description = "Whether to enable secret sync on the Azure IoT Operations instance"
}

variable "should_create_anonymous_broker_listener" {
  type        = bool
  description = "Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)"
  default     = false
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
  default = {
    serviceName = "aio-broker-anon"
    port        = 18884
    nodePort    = 31884
  }
}
