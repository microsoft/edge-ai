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
    version                        = "1.3.38"
    train                          = "stable"
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
    logsLevel                 = optional(string, "info")
  })
  default = {
    brokerListenerServiceName = "aio-broker"
    brokerListenerPort        = 18883
    serviceAccountAudience    = "aio-internal"
    frontendReplicas          = 2
    frontendWorkers           = 2
    backendRedundancyFactor   = 2
    backendWorkers            = 2
    backendPartitions         = 2
    memoryProfile             = "Medium"
    serviceType               = "ClusterIp"
    logsLevel                 = "info"
  }
}

variable "mqtt_broker_advanced_config" {
  type = object({
    encrypt_internal_traffic = optional(string)
    internal_certs = optional(object({
      duration                    = optional(string)
      renew_before                = optional(string)
      private_key_algorithm       = optional(string)
      private_key_rotation_policy = optional(string)
    }))
    clients = optional(object({
      max_session_expiry_seconds = optional(number)
      max_message_expiry_seconds = optional(number)
      max_packet_size_bytes      = optional(number)
      max_receive_maximum        = optional(number)
      max_keep_alive_seconds     = optional(number)
      subscriber_queue_limit = optional(object({
        length   = optional(number)
        strategy = optional(string)
      }))
    }))
  })
  description = "Advanced broker settings for client limits, internal traffic encryption, and internal certificate configuration"
  default     = null

  validation {
    condition = var.mqtt_broker_advanced_config == null || try(
      var.mqtt_broker_advanced_config.encrypt_internal_traffic == null ||
      contains(["Enabled", "Disabled"], var.mqtt_broker_advanced_config.encrypt_internal_traffic),
      true
    )
    error_message = "encrypt_internal_traffic must be 'Enabled' or 'Disabled'."
  }

  validation {
    condition = var.mqtt_broker_advanced_config == null || try(
      var.mqtt_broker_advanced_config.internal_certs.private_key_algorithm == null ||
      contains(["Ec256", "Ec384", "Ec521", "Ed25519", "Rsa2048", "Rsa4096", "Rsa8192"], var.mqtt_broker_advanced_config.internal_certs.private_key_algorithm),
      true
    )
    error_message = "internal_certs.private_key_algorithm must be one of: 'Ec256', 'Ec384', 'Ec521', 'Ed25519', 'Rsa2048', 'Rsa4096', 'Rsa8192'."
  }

  validation {
    condition = var.mqtt_broker_advanced_config == null || try(
      var.mqtt_broker_advanced_config.internal_certs.private_key_rotation_policy == null ||
      contains(["Always", "Never"], var.mqtt_broker_advanced_config.internal_certs.private_key_rotation_policy),
      true
    )
    error_message = "internal_certs.private_key_rotation_policy must be 'Always' or 'Never'."
  }

  validation {
    condition = var.mqtt_broker_advanced_config == null || try(
      var.mqtt_broker_advanced_config.clients.subscriber_queue_limit.strategy == null ||
      contains(["None", "DropOldest"], var.mqtt_broker_advanced_config.clients.subscriber_queue_limit.strategy),
      true
    )
    error_message = "clients.subscriber_queue_limit.strategy must be 'None' or 'DropOldest'."
  }

  validation {
    condition = var.mqtt_broker_advanced_config == null || try(
      var.mqtt_broker_advanced_config.clients.max_session_expiry_seconds == null ||
      var.mqtt_broker_advanced_config.clients.max_session_expiry_seconds >= 1,
      true
    )
    error_message = "clients.max_session_expiry_seconds must be at least 1."
  }

  validation {
    condition = var.mqtt_broker_advanced_config == null || try(
      var.mqtt_broker_advanced_config.clients.max_message_expiry_seconds == null ||
      var.mqtt_broker_advanced_config.clients.max_message_expiry_seconds >= 1,
      true
    )
    error_message = "clients.max_message_expiry_seconds must be at least 1."
  }

  validation {
    condition = var.mqtt_broker_advanced_config == null || try(
      var.mqtt_broker_advanced_config.clients.max_packet_size_bytes == null || (
        var.mqtt_broker_advanced_config.clients.max_packet_size_bytes >= 1 &&
        var.mqtt_broker_advanced_config.clients.max_packet_size_bytes <= 268435456
      ),
      true
    )
    error_message = "clients.max_packet_size_bytes must be between 1 and 268435456."
  }

  validation {
    condition = var.mqtt_broker_advanced_config == null || try(
      var.mqtt_broker_advanced_config.clients.max_receive_maximum == null || (
        var.mqtt_broker_advanced_config.clients.max_receive_maximum >= 1 &&
        var.mqtt_broker_advanced_config.clients.max_receive_maximum <= 65535
      ),
      true
    )
    error_message = "clients.max_receive_maximum must be between 1 and 65535."
  }

  validation {
    condition = var.mqtt_broker_advanced_config == null || try(
      var.mqtt_broker_advanced_config.clients.max_keep_alive_seconds == null || (
        var.mqtt_broker_advanced_config.clients.max_keep_alive_seconds >= 0 &&
        var.mqtt_broker_advanced_config.clients.max_keep_alive_seconds <= 65535
      ),
      true
    )
    error_message = "clients.max_keep_alive_seconds must be between 0 and 65535."
  }

  validation {
    condition = var.mqtt_broker_advanced_config == null || try(
      var.mqtt_broker_advanced_config.clients.subscriber_queue_limit.length == null ||
      var.mqtt_broker_advanced_config.clients.subscriber_queue_limit.length >= 1,
      true
    )
    error_message = "clients.subscriber_queue_limit.length must be at least 1."
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
    max_size           = string
    encryption_enabled = optional(bool)

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
      data_source_ref = optional(object({
        api_group = optional(string)
        kind      = string
        name      = string
        namespace = optional(string)
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
        contains(["ReadWriteOncePod"], mode)
      ]),
      true
    )
    error_message = "persistent_volume_claim_spec.access_modes must be 'ReadWriteOncePod' for broker persistence."
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

variable "mqtt_broker_disk_buffer_config" {
  type = object({
    max_size = string
    ephemeral_volume_claim_spec = optional(object({
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
      data_source_ref = optional(object({
        api_group = optional(string)
        kind      = string
        name      = string
        namespace = optional(string)
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
      data_source_ref = optional(object({
        api_group = optional(string)
        kind      = string
        name      = string
        namespace = optional(string)
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
  description = "Disk-backed message buffer configuration for broker in-memory overflow to disk"
  default     = null

  validation {
    condition     = var.mqtt_broker_disk_buffer_config == null || try(can(regex("^[0-9]+[KMGTPE]$", var.mqtt_broker_disk_buffer_config.max_size)), false)
    error_message = "max_size must follow the pattern '^[0-9]+[KMGTPE]$' (e.g., '100M', '1G', '500M'). Valid suffixes are K, M, G, T, P, E (binary suffixes like 'Gi', 'Mi' are not supported)."
  }

  validation {
    condition = var.mqtt_broker_disk_buffer_config == null || try(
      alltrue([
        for mode in coalesce(var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.access_modes, []) :
        contains(["ReadWriteOnce", "ReadOnlyMany", "ReadWriteMany", "ReadWriteOncePod"], mode)
      ]),
      true
    )
    error_message = "ephemeral_volume_claim_spec.access_modes must contain valid Kubernetes access modes: 'ReadWriteOnce', 'ReadOnlyMany', 'ReadWriteMany', or 'ReadWriteOncePod'."
  }

  validation {
    condition = var.mqtt_broker_disk_buffer_config == null || try(
      contains(["Filesystem", "Block"], coalesce(var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.volume_mode, "Filesystem")),
      true
    )
    error_message = "ephemeral_volume_claim_spec.volume_mode must be either 'Filesystem' or 'Block'."
  }

  validation {
    condition = var.mqtt_broker_disk_buffer_config == null || try(
      alltrue([
        for expr in coalesce(var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.selector.match_expressions, []) :
        contains(["In", "NotIn", "Exists", "DoesNotExist"], expr.operator)
      ]),
      true
    )
    error_message = "ephemeral_volume_claim_spec.selector.match_expressions[].operator must be one of: 'In', 'NotIn', 'Exists', or 'DoesNotExist'."
  }

  validation {
    condition = var.mqtt_broker_disk_buffer_config == null || try(
      alltrue([
        for mode in coalesce(var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.access_modes, []) :
        contains(["ReadWriteOnce", "ReadOnlyMany", "ReadWriteMany", "ReadWriteOncePod"], mode)
      ]),
      true
    )
    error_message = "persistent_volume_claim_spec.access_modes must contain valid Kubernetes access modes: 'ReadWriteOnce', 'ReadOnlyMany', 'ReadWriteMany', or 'ReadWriteOncePod'."
  }

  validation {
    condition = var.mqtt_broker_disk_buffer_config == null || try(
      contains(["Filesystem", "Block"], coalesce(var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.volume_mode, "Filesystem")),
      true
    )
    error_message = "persistent_volume_claim_spec.volume_mode must be either 'Filesystem' or 'Block'."
  }

  validation {
    condition = var.mqtt_broker_disk_buffer_config == null || try(
      alltrue([
        for expr in coalesce(var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.selector.match_expressions, []) :
        contains(["In", "NotIn", "Exists", "DoesNotExist"], expr.operator)
      ]),
      true
    )
    error_message = "persistent_volume_claim_spec.selector.match_expressions[].operator must be one of: 'In', 'NotIn', 'Exists', or 'DoesNotExist'."
  }
}

variable "mqtt_broker_diagnostics_config" {
  type = object({
    metrics = optional(object({
      prometheus_port = optional(number)
    }))
    self_check = optional(object({
      mode             = optional(string)
      interval_seconds = optional(number)
      timeout_seconds  = optional(number)
    }))
    traces = optional(object({
      mode                  = optional(string)
      cache_size_megabytes  = optional(number)
      span_channel_capacity = optional(number)
      self_tracing = optional(object({
        mode             = optional(string)
        interval_seconds = optional(number)
      }))
    }))
  })
  description = "Extended broker diagnostics configuration for metrics, self-check, and distributed tracing"
  default     = null

  validation {
    condition = var.mqtt_broker_diagnostics_config == null || try(
      contains(["Enabled", "Disabled"], var.mqtt_broker_diagnostics_config.self_check.mode),
      true
    )
    error_message = "self_check.mode must be one of: 'Enabled' or 'Disabled'."
  }

  validation {
    condition = var.mqtt_broker_diagnostics_config == null || try(
      contains(["Enabled", "Disabled"], var.mqtt_broker_diagnostics_config.traces.mode),
      true
    )
    error_message = "traces.mode must be one of: 'Enabled' or 'Disabled'."
  }

  validation {
    condition = var.mqtt_broker_diagnostics_config == null || try(
      contains(["Enabled", "Disabled"], var.mqtt_broker_diagnostics_config.traces.self_tracing.mode),
      true
    )
    error_message = "traces.self_tracing.mode must be one of: 'Enabled' or 'Disabled'."
  }

  validation {
    condition = var.mqtt_broker_diagnostics_config == null || try(
      var.mqtt_broker_diagnostics_config.metrics.prometheus_port >= 0 && var.mqtt_broker_diagnostics_config.metrics.prometheus_port <= 65535,
      true
    )
    error_message = "metrics.prometheus_port must be between 0 and 65535."
  }

  validation {
    condition = var.mqtt_broker_diagnostics_config == null || try(
      var.mqtt_broker_diagnostics_config.self_check.interval_seconds >= 30 && var.mqtt_broker_diagnostics_config.self_check.interval_seconds <= 300,
      true
    )
    error_message = "self_check.interval_seconds must be between 30 and 300."
  }

  validation {
    condition = var.mqtt_broker_diagnostics_config == null || try(
      var.mqtt_broker_diagnostics_config.self_check.timeout_seconds >= 5 && var.mqtt_broker_diagnostics_config.self_check.timeout_seconds <= 120,
      true
    )
    error_message = "self_check.timeout_seconds must be between 5 and 120."
  }

  validation {
    condition = var.mqtt_broker_diagnostics_config == null || try(
      var.mqtt_broker_diagnostics_config.traces.cache_size_megabytes >= 1 && var.mqtt_broker_diagnostics_config.traces.cache_size_megabytes <= 128,
      true
    )
    error_message = "traces.cache_size_megabytes must be between 1 and 128."
  }

  validation {
    condition = var.mqtt_broker_diagnostics_config == null || try(
      var.mqtt_broker_diagnostics_config.traces.span_channel_capacity >= 1000 && var.mqtt_broker_diagnostics_config.traces.span_channel_capacity <= 100000,
      true
    )
    error_message = "traces.span_channel_capacity must be between 1000 and 100000."
  }

  validation {
    condition = var.mqtt_broker_diagnostics_config == null || try(
      var.mqtt_broker_diagnostics_config.traces.self_tracing.interval_seconds >= 1 && var.mqtt_broker_diagnostics_config.traces.self_tracing.interval_seconds <= 300,
      true
    )
    error_message = "traces.self_tracing.interval_seconds must be between 1 and 300."
  }
}

variable "configuration_settings_override" {
  type        = map(string)
  description = "Optional configuration settings to override default IoT Operations extension configuration. Use the same key names as the az iot ops --ops-config parameter."
  default     = {}
}

variable "additional_cluster_extension_ids" {
  type        = list(string)
  description = "Additional cluster extension IDs to include in the custom location. Appended to the default Secret Store and IoT Operations extension IDs"
  default     = []
}
