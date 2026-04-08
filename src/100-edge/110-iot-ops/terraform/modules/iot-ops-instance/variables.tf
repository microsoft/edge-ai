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

variable "adr_namespace_id" {
  type        = string
  description = "The resource ID of the Azure Device Registry namespace for the Azure IoT Operations instance. Otherwise, not configured."
  default     = null
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
}

variable "resource_group" {
  type = object({
    id   = string
    name = string
  })
  description = "Resource group object containing name and id where resources will be deployed"
}

variable "key_vault" {
  type = object({
    name = string
    id   = string
  })
  description = "The Key Vault object containing id and name properties"
}

variable "secret_sync_identity" {
  type = object({
    id        = string
    client_id = string
  })
  description = "Secret Sync Extension user managed identity id and client id"
}

variable "enable_instance_secret_sync" {
  type        = bool
  description = "Whether to enable secret sync on the Azure IoT Operations instance"
}

variable "configuration_settings_override" {
  type        = map(string)
  description = "Optional configuration settings to override default IoT Operations extension configuration. Use the same key names as the az iot ops --ops-config parameter."
}

variable "additional_cluster_extension_ids" {
  type        = list(string)
  description = "Additional cluster extension IDs to include in the custom location. Appended to the default Secret Store and IoT Operations extension IDs"
}
