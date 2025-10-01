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
    version                        = "1.2.36"
    train                          = "preview"
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
  description = "Deploys resource sync rules if set to true"
  default     = false
}

variable "enable_instance_secret_sync" {
  type        = bool
  default     = true
  description = "Whether to enable secret sync on the Azure IoT Operations instance"
}

variable "should_create_anonymous_broker_listener" {
  type        = bool
  description = "Whether to enable an insecure anonymous AIO MQ Broker Listener. Should only be used for dev or test environments"
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

variable "mqtt_broker_persistence_config" {
  type = object({
    enabled            = bool
    max_size           = string
    encryption_enabled = optional(bool)

    # Dynamic Settings
    dynamic_settings = optional(object({
      user_property_key   = string
      user_property_value = string
    }))

    # Retention Policy
    retain_policy = optional(object({
      mode = string # "All", "None", "Custom"
      custom_settings = optional(object({
        topics          = optional(list(string))
        dynamic_enabled = optional(bool)
      }))
    }))

    # State Store Policy
    state_store_policy = optional(object({
      mode = string # "All", "None", "Custom"
      custom_settings = optional(object({
        state_store_resources = optional(list(object({
          key_type = string # "Pattern", "String", "Binary"
          keys     = list(string)
        })))
        dynamic_enabled = optional(bool)
      }))
    }))

    # Subscriber Queue Policy
    subscriber_queue_policy = optional(object({
      mode = string # "All", "None", "Custom"
      custom_settings = optional(object({
        subscriber_client_ids = optional(list(string))
        topics                = optional(list(string))
        dynamic_enabled       = optional(bool)
      }))
    }))

    # Persistent Volume Claim Specification
    persistent_volume_claim_spec = optional(object({
      storage_class_name = optional(string)
      access_modes       = optional(list(string))
      volume_mode        = optional(string)
      volume_name        = optional(string)
      resources = optional(object({
        requests = optional(map(string))
        limits   = optional(map(string))
      }))
      data_source = optional(object({
        api_group = optional(string)
        kind      = string
        name      = string
      }))
      selector = optional(object({
        match_labels = optional(map(string))
        match_expressions = optional(list(object({
          key      = string
          operator = string
          values   = list(string)
        })))
      }))
    }))
  })
  description = "Broker persistence configuration for disk-backed message storage"
  default     = null

  validation {
    condition     = var.mqtt_broker_persistence_config == null || try(can(regex("^[0-9]+[KMGTPE]$", var.mqtt_broker_persistence_config.max_size)), false)
    error_message = "max_size must follow the pattern '^[0-9]+[KMGTPE]$' (e.g., '100M', '1G', '500M'). Valid suffixes are K, M, G, T, P, E (binary suffixes like 'Gi', 'Mi' are not supported)."
  }

  validation {
    condition = var.mqtt_broker_persistence_config == null || try(
      contains(["All", "None", "Custom"], coalesce(var.mqtt_broker_persistence_config.retain_policy.mode, "All")),
      true
    )
    error_message = "retain_policy.mode must be one of: 'All', 'None', or 'Custom'."
  }

  validation {
    condition = var.mqtt_broker_persistence_config == null || try(
      contains(["All", "None", "Custom"], coalesce(var.mqtt_broker_persistence_config.state_store_policy.mode, "All")),
      true
    )
    error_message = "state_store_policy.mode must be one of: 'All', 'None', or 'Custom'."
  }

  validation {
    condition = var.mqtt_broker_persistence_config == null || try(
      contains(["All", "None", "Custom"], coalesce(var.mqtt_broker_persistence_config.subscriber_queue_policy.mode, "All")),
      true
    )
    error_message = "subscriber_queue_policy.mode must be one of: 'All', 'None', or 'Custom'."
  }

  validation {
    condition = var.mqtt_broker_persistence_config == null || try(
      alltrue([
        for resource in coalesce(var.mqtt_broker_persistence_config.state_store_policy.custom_settings.state_store_resources, []) :
        contains(["Pattern", "String", "Binary"], resource.key_type)
      ]),
      true
    )
    error_message = "state_store_policy.custom_settings.state_store_resources[].key_type must be one of: 'Pattern', 'String', or 'Binary'."
  }

  validation {
    condition = var.mqtt_broker_persistence_config == null || try(
      alltrue([
        for mode in coalesce(var.mqtt_broker_persistence_config.persistent_volume_claim_spec.access_modes, []) :
        contains(["ReadWriteOnce", "ReadOnlyMany", "ReadWriteMany", "ReadWriteOncePod"], mode)
      ]),
      true
    )
    error_message = "persistent_volume_claim_spec.access_modes must contain valid Kubernetes access modes: 'ReadWriteOnce', 'ReadOnlyMany', 'ReadWriteMany', or 'ReadWriteOncePod'."
  }

  validation {
    condition = var.mqtt_broker_persistence_config == null || try(
      contains(["Filesystem", "Block"], coalesce(var.mqtt_broker_persistence_config.persistent_volume_claim_spec.volume_mode, "Filesystem")),
      true
    )
    error_message = "persistent_volume_claim_spec.volume_mode must be either 'Filesystem' or 'Block'."
  }

  validation {
    condition = var.mqtt_broker_persistence_config == null || try(
      alltrue([
        for expr in coalesce(var.mqtt_broker_persistence_config.persistent_volume_claim_spec.selector.match_expressions, []) :
        contains(["In", "NotIn", "Exists", "DoesNotExist"], expr.operator)
      ]),
      true
    )
    error_message = "persistent_volume_claim_spec.selector.match_expressions[].operator must be one of: 'In', 'NotIn', 'Exists', or 'DoesNotExist'."
  }
}
