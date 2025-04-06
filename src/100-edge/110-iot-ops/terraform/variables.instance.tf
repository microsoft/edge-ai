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
    version                        = "1.0.9"
    train                          = "stable"
    agentOperationTimeoutInMinutes = 120
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

variable "deploy_resource_sync_rules" {
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
  type        = string
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
