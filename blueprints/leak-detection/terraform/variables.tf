/*
 * Core Parameters - Required
 */

variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
}

/*
 * Core Parameters - Optional
 */

variable "instance" {
  type        = string
  description = "Instance identifier for naming resources: 001, 002, etc"
  default     = "001"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create or use. Otherwise, 'rg-{resource_prefix}-{environment}-{instance}'"
  default     = null
}

variable "use_existing_resource_group" {
  type        = bool
  description = "Whether to use an existing resource group with the provided or computed name instead of creating a new one"
  default     = false
}

/*
 * Azure Arc Parameters
 */

variable "custom_locations_oid" {
  type        = string
  description = <<-EOT
  The object id of the Custom Locations Entra ID application for your tenant
  If none is provided, the script attempts to retrieve this value which requires 'Application.Read.All' or 'Directory.Read.All' permissions

  ```sh
  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
  ```
  EOT
  default     = null
}

variable "should_add_current_user_cluster_admin" {
  type        = bool
  description = "Whether to give the current signed-in user cluster-admin permissions on the new cluster"
  default     = true
}

variable "should_get_custom_locations_oid" {
  type        = bool
  description = <<-EOT
  Whether to get the Custom Locations object ID using Terraform's azuread provider
  Otherwise, provide 'custom_locations_oid' or rely on `az connectedk8s enable-features` during cluster setup
  EOT
  default     = true
}

/*
 * Azure IoT Operations Parameters
 */

variable "aio_features" {
  description = "AIO instance features with mode ('Stable', 'Preview', 'Disabled') and settings ('Enabled', 'Disabled')"
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

variable "should_create_anonymous_broker_listener" {
  type        = bool
  description = "Whether to enable an insecure anonymous AIO MQ broker listener; use only for dev or test environments"
  default     = false
}

variable "should_deploy_resource_sync_rules" {
  type        = bool
  description = "Whether to deploy resource sync rules"
  default     = true
}

variable "should_enable_opc_ua_simulator" {
  type        = bool
  description = "Whether to deploy the OPC UA simulator to the cluster"
  default     = false
}

/*
 * Asset Parameters
 */

variable "namespaced_devices" {
  type = list(object({
    name    = string
    enabled = optional(bool, true)
    endpoints = object({
      outbound = optional(object({
        assigned = object({})
      }), { assigned = {} })
      inbound = map(object({
        endpoint_type           = string
        address                 = string
        version                 = optional(string, null)
        additionalConfiguration = optional(string)
        authentication = object({
          method = string
          usernamePasswordCredentials = optional(object({
            usernameSecretName = string
            passwordSecretName = string
          }))
          x509Credentials = optional(object({
            certificateSecretName = string
          }))
        })
        trustSettings = optional(object({
          trustList = string
        }))
      }))
    })
  }))
  description = "List of namespaced devices to create; otherwise, an empty list"
  default     = []
}

variable "namespaced_assets" {
  type = list(object({
    name         = string
    display_name = optional(string)
    device_ref = optional(object({
      device_name   = string
      endpoint_name = string
    }))
    asset_endpoint_profile_ref     = optional(string)
    default_datasets_configuration = optional(string)
    default_streams_configuration  = optional(string)
    default_events_configuration   = optional(string)
    description                    = optional(string)
    documentation_uri              = optional(string)
    enabled                        = optional(bool, true)
    hardware_revision              = optional(string)
    manufacturer                   = optional(string)
    manufacturer_uri               = optional(string)
    model                          = optional(string)
    product_code                   = optional(string)
    serial_number                  = optional(string)
    software_revision              = optional(string)
    attributes                     = optional(map(string), {})
    datasets = optional(list(object({
      name = string
      data_points = list(object({
        data_point_configuration  = optional(string)
        data_source               = string
        name                      = string
        observability_mode        = optional(string)
        rest_sampling_interval_ms = optional(number)
        rest_mqtt_topic           = optional(string)
        rest_include_state_store  = optional(bool)
        rest_state_store_key      = optional(string)
      }))
      dataset_configuration = optional(string)
      data_source           = optional(string)
      destinations = optional(list(object({
        target = string
        configuration = object({
          topic  = optional(string)
          retain = optional(string)
          qos    = optional(string)
        })
      })), [])
      type_ref = optional(string)
    })), [])
    streams = optional(list(object({
      name                 = string
      stream_configuration = optional(string)
      type_ref             = optional(string)
      destinations = optional(list(object({
        target = string
        configuration = object({
          topic  = optional(string)
          retain = optional(string)
          qos    = optional(string)
        })
      })), [])
    })), [])
    event_groups = optional(list(object({
      name                      = string
      data_source               = optional(string)
      event_group_configuration = optional(string)
      type_ref                  = optional(string)
      default_destinations = optional(list(object({
        target = string
        configuration = object({
          topic  = optional(string)
          retain = optional(string)
          qos    = optional(string)
        })
      })), [])
      events = list(object({
        name                = string
        data_source         = string
        event_configuration = optional(string)
        type_ref            = optional(string)
        destinations = optional(list(object({
          target = string
          configuration = object({
            topic  = optional(string)
            retain = optional(string)
            qos    = optional(string)
          })
        })), [])
      }))
    })), [])
    management_groups = optional(list(object({
      name                           = string
      data_source                    = optional(string)
      management_group_configuration = optional(string)
      type_ref                       = optional(string)
      default_topic                  = optional(string)
      default_timeout_in_seconds     = optional(number, 100)
      actions = list(object({
        name                 = string
        action_type          = string
        target_uri           = string
        topic                = optional(string)
        timeout_in_seconds   = optional(number)
        action_configuration = optional(string)
        type_ref             = optional(string)
      }))
    })), [])
  }))
  description = "List of namespaced assets with enhanced configuration support"
  default     = []

  validation {
    condition = alltrue([
      for asset in var.namespaced_assets : alltrue([
        for group in coalesce(asset.management_groups, []) : alltrue([
          for action in group.actions : contains(["Call", "Read", "Write"], action.action_type)
        ])
      ])
    ])
    error_message = "All management action types must be one of: Call, Read, or Write."
  }
}

/*
 * Alert Dataflow Parameters
 */

variable "alert_eventhub_name" {
  type        = string
  description = "Name of the Event Hub for inference alerts. Otherwise, 'evh-{resource_prefix}-alerts-{environment}-{instance}'"
  default     = null
}

variable "eventhubs" {
  description = <<-EOF
    Per-Event Hub configuration. Keys are Event Hub names.

    - **Message retention**: Specifies the number of days to retain events for this Event Hub, from 1 to 7.
    - **Partition count**: Specifies the number of partitions for the Event Hub. Valid values are from 1 to 32.
    - **Consumer group user metadata**: A placeholder to store user-defined string data with maximum length 1024.
      It can be used to store descriptive data, such as list of teams and their contact information,
      or user-defined configuration settings.
  EOF
  type = map(object({
    message_retention = optional(number, 1)
    partition_count   = optional(number, 1)
    consumer_groups = optional(map(object({
      user_metadata = optional(string, null)
    })), {})
  }))
  default = {}
}

/*
 * Azure Functions Parameters
 */

variable "should_create_azure_functions" {
  type        = bool
  description = "Whether to create the Azure Functions resources including the App Service plan"
  default     = true
}

variable "function_app_settings" {
  type        = map(string)
  description = "Application settings for the Function App deployed by the messaging component"
  default     = {}
  sensitive   = true
}

/*
 * Notification Parameters (045-notification)
 */

variable "should_deploy_notification" {
  type        = bool
  description = "Whether to deploy the 045-notification Logic App for alert deduplication and Teams posting"
  default     = true
}

variable "closure_message_template" {
  type        = string
  description = "HTML message body for session-closure Teams notifications. Supports Logic App expression syntax for dynamic fields"
  default     = "<p>Session closed for event.</p>"
}

variable "notification_event_schema" {
  type        = any
  description = "JSON schema object for parsing Event Hub events in the Logic App Parse_Event action"
  default     = {}
}

variable "notification_message_template" {
  type        = string
  description = "HTML template for new-event Teams notifications. Supports Terraform template variable: close_session_url. Supports Logic App expression syntax for dynamic event fields"
  default     = "<p>New alert event detected.</p>"
}

variable "notification_partition_key_field" {
  type        = string
  description = "Event schema field name used as the Table Storage partition key for session state deduplication lookups"
  default     = "camera_id"
}

variable "teams_recipient_id" {
  type        = string
  description = "Teams chat or channel thread ID for posting event notifications"
  sensitive   = true
  default     = ""
}

/*
 * Azure Private Endpoint and DNS Parameters
 */

variable "resolver_subnet_address_prefix" {
  type        = string
  description = "Address prefix for the private resolver subnet; must be /28 or larger and not overlap with other subnets"
  default     = "10.0.9.0/28"
}

variable "should_enable_private_endpoints" {
  type        = bool
  description = "Whether to enable private endpoints across Key Vault, storage, and observability resources to route monitoring ingestion through private link"
  default     = false
}

variable "should_enable_private_resolver" {
  type        = bool
  description = "Whether to enable Azure Private Resolver for VPN client DNS resolution of private endpoints"
  default     = false
}

/*
 * Azure Container Registry Parameters
 */

variable "acr_sku" {
  type        = string
  description = "SKU name for the Azure Container Registry"
  default     = "Premium"
}

variable "acr_allow_trusted_services" {
  type        = bool
  description = "Whether trusted Azure services can bypass ACR network rules"
  default     = true
}

variable "acr_allowed_public_ip_ranges" {
  type        = list(string)
  description = "CIDR ranges permitted to reach the ACR public endpoint"
  default     = []
}

variable "acr_data_endpoint_enabled" {
  type        = bool
  description = "Whether to enable the dedicated ACR data endpoint"
  default     = true
}

variable "acr_export_policy_enabled" {
  type        = bool
  description = "Whether to allow container image export from the ACR. Requires acr_public_network_access_enabled to be true when enabled"
  default     = false
}

variable "acr_public_network_access_enabled" {
  type        = bool
  description = "Whether to enable the ACR public endpoint alongside private connectivity"
  default     = false
}

/*
 * Identity and Key Vault Parameters
 */

variable "should_enable_key_vault_public_network_access" {
  type        = bool
  description = "Whether to enable public network access for the Key Vault"
  default     = true
}

variable "should_enable_key_vault_purge_protection" {
  type        = bool
  description = "Whether to enable purge protection for the Key Vault. Enable for production to prevent accidental or malicious secret deletion"
  default     = false
}

/*
 * Networking and Outbound Access Parameters
 */

variable "nat_gateway_idle_timeout_minutes" {
  type        = number
  description = "Idle timeout in minutes for NAT gateway connections"
  default     = 4
  validation {
    condition     = var.nat_gateway_idle_timeout_minutes >= 4 && var.nat_gateway_idle_timeout_minutes <= 240
    error_message = "Idle timeout must be between 4 and 240 minutes"
  }
}

variable "nat_gateway_public_ip_count" {
  type        = number
  description = "Number of public IP addresses to associate with the NAT gateway (example: 2)"
  default     = 1
  validation {
    condition     = var.nat_gateway_public_ip_count >= 1 && var.nat_gateway_public_ip_count <= 16
    error_message = "Public IP count must be between 1 and 16"
  }
}

variable "nat_gateway_zones" {
  type        = list(string)
  description = "Availability zones for NAT gateway resources when zone redundancy is required (example: ['1','2'])"
  default     = []
}

variable "should_enable_managed_outbound_access" {
  type        = bool
  description = "Whether to enable managed outbound egress via NAT gateway instead of platform default internet access"
  default     = true
}

/*
 * Storage Parameters
 */

variable "should_enable_storage_public_network_access" {
  type        = bool
  description = "Whether to enable public network access for the storage account"
  default     = true
}

variable "storage_account_is_hns_enabled" {
  type        = bool
  description = "Whether to enable hierarchical namespace on the storage account for media capture blob storage"
  default     = true
}

/*
 * Akri Connector Configuration - Optional
 */

variable "should_enable_akri_rest_connector" {
  type        = bool
  description = "Whether to deploy the Akri REST HTTP Connector template to the IoT Operations instance"
  default     = false
}

variable "should_enable_akri_media_connector" {
  type        = bool
  description = "Whether to deploy the Akri Media Connector template to the IoT Operations instance"
  default     = true
}

variable "should_enable_akri_onvif_connector" {
  type        = bool
  description = "Whether to deploy the Akri ONVIF Connector template to the IoT Operations instance"
  default     = true
}

variable "should_enable_akri_sse_connector" {
  type        = bool
  description = "Whether to deploy the Akri SSE Connector template to the IoT Operations instance"
  default     = false
}

variable "custom_akri_connectors" {
  type = list(object({
    name = string
    type = string

    custom_endpoint_type    = optional(string)
    custom_image_name       = optional(string)
    custom_endpoint_version = optional(string, "1.0")

    registry          = optional(string)
    image_tag         = optional(string)
    replicas          = optional(number, 1)
    image_pull_policy = optional(string)

    log_level = optional(string)

    mqtt_config = optional(object({
      host                   = string
      audience               = string
      ca_configmap           = string
      keep_alive_seconds     = optional(number, 60)
      max_inflight_messages  = optional(number, 100)
      session_expiry_seconds = optional(number, 600)
    }))

    aio_min_version = optional(string)
    aio_max_version = optional(string)
    allocation = optional(object({
      policy      = string
      bucket_size = number
    }))
    additional_configuration = optional(map(string))
    secrets = optional(list(object({
      secret_alias = string
      secret_key   = string
      secret_ref   = string
    })))
    trust_settings = optional(object({
      trust_list_secret_ref = string
    }))
  }))

  default     = []
  description = <<-EOT
    List of custom Akri connector templates with user-defined endpoint types and container images.
    Supports built-in types (rest, media, onvif, sse) or custom types with custom_endpoint_type and custom_image_name.
    Built-in connectors default to mcr.microsoft.com/azureiotoperations/akri-connectors/connector_type:0.5.1.
  EOT

  validation {
    condition = alltrue([
      for conn in var.custom_akri_connectors :
      contains(["rest", "media", "onvif", "sse", "custom"], conn.type)
    ])
    error_message = "Connector type must be one of: rest, media, onvif, sse, custom."
  }

  validation {
    condition = alltrue([
      for conn in var.custom_akri_connectors :
      conn.type != "custom" || (conn.custom_endpoint_type != null && conn.custom_image_name != null)
    ])
    error_message = "Custom connector types must provide custom_endpoint_type and custom_image_name."
  }

  validation {
    condition = alltrue([
      for conn in var.custom_akri_connectors :
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", conn.name))
    ])
    error_message = "Connector name must contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }

  validation {
    condition = alltrue([
      for conn in var.custom_akri_connectors :
      contains(["trace", "debug", "info", "warning", "error", "critical"], lower(coalesce(conn.log_level, "info")))
    ])
    error_message = "Log level must be one of: trace, debug, info, warning, error, critical (case insensitive)."
  }

  validation {
    condition = alltrue([
      for conn in var.custom_akri_connectors :
      coalesce(conn.replicas, 1) >= 1 && coalesce(conn.replicas, 1) <= 10
    ])
    error_message = "Connector replicas must be between 1 and 10."
  }
}

variable "registry_endpoints" {
  type = list(object({
    name                           = string
    host                           = string
    acr_resource_id                = optional(string)
    should_assign_acr_pull_for_aio = optional(bool, false)

    authentication = object({
      method = string
      system_assigned_managed_identity_settings = optional(object({
        audience = optional(string)
      }))
      user_assigned_managed_identity_settings = optional(object({
        client_id = string
        tenant_id = string
        scope     = optional(string)
      }))
      artifact_pull_secret_settings = optional(object({
        secret_ref = string
      }))
    })
  }))

  default     = []
  description = <<-EOT
    List of additional container registry endpoints for pulling custom artifacts (WASM modules, graph definitions, connector templates).
    MCR (mcr.microsoft.com) is always added automatically with anonymous authentication.

    The `acr_resource_id` field enables automatic AcrPull role assignment for ACR endpoints
    using SystemAssignedManagedIdentity authentication. When `should_assign_acr_pull_for_aio` is true
    and `acr_resource_id` is provided, the AIO extension's identity will be granted AcrPull access to the specified ACR.
  EOT

  validation {
    condition = alltrue([
      for ep in var.registry_endpoints :
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", ep.name)) && length(ep.name) >= 3 && length(ep.name) <= 63
    ])
    error_message = "Registry endpoint name must be 3-63 characters, contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen"
  }

  validation {
    condition = alltrue([
      for ep in var.registry_endpoints :
      contains(["SystemAssignedManagedIdentity", "UserAssignedManagedIdentity", "ArtifactPullSecret", "Anonymous"], ep.authentication.method)
    ])
    error_message = "Authentication method must be one of: SystemAssignedManagedIdentity, UserAssignedManagedIdentity, ArtifactPullSecret, Anonymous"
  }

  validation {
    condition = alltrue([
      for ep in var.registry_endpoints :
      ep.authentication.method != "UserAssignedManagedIdentity" || (
        ep.authentication.user_assigned_managed_identity_settings != null &&
        ep.authentication.user_assigned_managed_identity_settings.client_id != null &&
        ep.authentication.user_assigned_managed_identity_settings.tenant_id != null
      )
    ])
    error_message = "UserAssignedManagedIdentity authentication requires client_id and tenant_id in user_assigned_managed_identity_settings"
  }

  validation {
    condition = alltrue([
      for ep in var.registry_endpoints :
      ep.authentication.method != "ArtifactPullSecret" || (
        ep.authentication.artifact_pull_secret_settings != null &&
        ep.authentication.artifact_pull_secret_settings.secret_ref != null
      )
    ])
    error_message = "ArtifactPullSecret authentication requires secret_ref in artifact_pull_secret_settings"
  }

  validation {
    condition = alltrue([
      for ep in var.registry_endpoints :
      ep.name != "mcr" && ep.name != "default"
    ])
    error_message = "Registry endpoint names 'mcr' and 'default' are reserved"
  }

  validation {
    condition = alltrue([
      for ep in var.registry_endpoints :
      ep.acr_resource_id == null || ep.authentication.method == "SystemAssignedManagedIdentity"
    ])
    error_message = "acr_resource_id can only be specified with SystemAssignedManagedIdentity authentication method"
  }
}

variable "should_include_acr_registry_endpoint" {
  type        = bool
  default     = false
  description = "Whether to include the deployed ACR as a registry endpoint with System Assigned Managed Identity authentication"
}

/*
 * Schema Parameters
 */

variable "schemas" {
  type = list(object({
    name         = string
    display_name = optional(string)
    description  = optional(string)
    format       = optional(string, "JsonSchema/draft-07")
    type         = optional(string, "MessageSchema")
    versions = map(object({
      description = string
      content     = string
    }))
  }))
  description = "List of schemas to create in the schema registry with their versions"
  default = [
    {
      name         = "temperature-schema"
      display_name = "Temperature Schema"
      description  = "Schema for temperature sensor data"
      format       = "JsonSchema/draft-07"
      type         = "MessageSchema"
      versions = {
        "1" = {
          description = "Initial version"
          content     = "{\"$schema\":\"http://json-schema.org/draft-07/schema#\",\"name\":\"temperature-schema\",\"type\":\"object\",\"properties\":{\"temperature\":{\"type\":\"object\",\"properties\":{\"value\":{\"type\":\"number\"},\"unit\":{\"type\":\"string\"}},\"required\":[\"value\",\"unit\"]}},\"required\":[\"temperature\"]}"
        }
      }
    }
  ]

  validation {
    condition = alltrue([
      for schema in var.schemas :
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", schema.name)) && length(schema.name) >= 3 && length(schema.name) <= 63
    ])
    error_message = "Schema name must be 3-63 characters, contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }

  validation {
    condition = alltrue([
      for schema in var.schemas :
      length(schema.versions) > 0
    ])
    error_message = "Each schema must have at least one version defined."
  }
}

/*
 * Dataflow Graph Parameters
 */

variable "dataflow_graphs" {
  type = list(object({
    name                     = string
    mode                     = optional(string, "Enabled")
    request_disk_persistence = optional(string, "Disabled")
    nodes = list(object({
      nodeType = string
      name     = string
      sourceSettings = optional(object({
        endpointRef = string
        assetRef    = optional(string)
        dataSources = list(string)
      }))
      graphSettings = optional(object({
        registryEndpointRef = string
        artifact            = string
        configuration = optional(list(object({
          key   = string
          value = string
        })))
      }))
      destinationSettings = optional(object({
        endpointRef     = string
        dataDestination = string
        headers = optional(list(object({
          actionType = string
          key        = string
          value      = optional(string)
        })))
      }))
    }))
    node_connections = list(object({
      from = object({
        name = string
        schema = optional(object({
          schemaRef           = string
          serializationFormat = optional(string, "Json")
        }))
      })
      to = object({
        name = string
      })
    }))
  }))
  description = "List of dataflow graphs to create with their node configurations"
  default     = []

  validation {
    condition = alltrue([
      for graph in var.dataflow_graphs :
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", graph.name)) && length(graph.name) >= 3 && length(graph.name) <= 63
    ])
    error_message = "Dataflow graph name must be 3-63 characters, contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }

  validation {
    condition = alltrue([
      for graph in var.dataflow_graphs :
      contains(["Enabled", "Disabled"], graph.mode)
    ])
    error_message = "Dataflow graph mode must be either 'Enabled' or 'Disabled'."
  }

  validation {
    condition = alltrue([
      for graph in var.dataflow_graphs :
      contains(["Enabled", "Disabled"], graph.request_disk_persistence)
    ])
    error_message = "Dataflow graph request_disk_persistence must be either 'Enabled' or 'Disabled'."
  }

  validation {
    condition = alltrue([
      for graph in var.dataflow_graphs : alltrue([
        for node in graph.nodes :
        contains(["Source", "Graph", "Destination"], node.nodeType)
      ])
    ])
    error_message = "Node type must be one of: 'Source', 'Graph', or 'Destination'."
  }

  validation {
    condition = alltrue([
      for graph in var.dataflow_graphs : alltrue([
        for node in graph.nodes :
        node.destinationSettings == null || node.destinationSettings.headers == null || alltrue([
          for header in coalesce(node.destinationSettings.headers, []) :
          contains(["AddIfNotPresent", "AddOrReplace", "Remove"], header.actionType)
        ])
      ])
    ])
    error_message = "Header action type must be one of: 'AddIfNotPresent', 'AddOrReplace', or 'Remove'."
  }
}

/*
 * Dataflow Parameters
 */

variable "dataflows" {
  type = list(object({
    name                     = string
    mode                     = optional(string, "Enabled")
    request_disk_persistence = optional(string, "Disabled")
    operations = list(object({
      operationType = string
      name          = optional(string)
      sourceSettings = optional(object({
        endpointRef         = string
        assetRef            = optional(string)
        serializationFormat = optional(string, "Json")
        schemaRef           = optional(string)
        dataSources         = list(string)
      }))
      builtInTransformationSettings = optional(object({
        serializationFormat = optional(string, "Json")
        schemaRef           = optional(string)
        datasets = optional(list(object({
          key         = string
          description = optional(string)
          schemaRef   = optional(string)
          inputs      = list(string)
          expression  = string
        })))
        filter = optional(list(object({
          type        = optional(string, "Filter")
          description = optional(string)
          inputs      = list(string)
          expression  = string
        })))
        map = optional(list(object({
          type        = optional(string, "NewProperties")
          description = optional(string)
          inputs      = list(string)
          expression  = optional(string)
          output      = string
        })))
      }))
      destinationSettings = optional(object({
        endpointRef     = string
        dataDestination = string
      }))
    }))
  }))
  description = "List of dataflows to create with their operation configurations"
  default     = []

  validation {
    condition = alltrue([
      for df in var.dataflows :
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", df.name)) && length(df.name) >= 3 && length(df.name) <= 63
    ])
    error_message = "Dataflow name must be 3-63 characters, contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }

  validation {
    condition = alltrue([
      for df in var.dataflows :
      contains(["Enabled", "Disabled"], df.mode)
    ])
    error_message = "Dataflow mode must be either 'Enabled' or 'Disabled'."
  }

  validation {
    condition = alltrue([
      for df in var.dataflows :
      contains(["Enabled", "Disabled"], df.request_disk_persistence)
    ])
    error_message = "Dataflow request_disk_persistence must be either 'Enabled' or 'Disabled'."
  }

  validation {
    condition = alltrue([
      for df in var.dataflows : alltrue([
        for op in df.operations :
        contains(["Source", "Destination", "BuiltInTransformation"], op.operationType)
      ])
    ])
    error_message = "Operation type must be one of: 'Source', 'Destination', or 'BuiltInTransformation'."
  }

  validation {
    condition = alltrue([
      for df in var.dataflows : alltrue([
        for op in df.operations :
        op.operationType != "Source" || op.sourceSettings != null
      ])
    ])
    error_message = "Source operations must include sourceSettings."
  }

  validation {
    condition = alltrue([
      for df in var.dataflows : alltrue([
        for op in df.operations :
        op.operationType != "Destination" || op.destinationSettings != null
      ])
    ])
    error_message = "Destination operations must include destinationSettings."
  }
}

/*
 * Dataflow Endpoint Parameters
 */

variable "dataflow_endpoints" {
  type = list(object({
    name         = string
    endpointType = string
    hostType     = optional(string)
    dataExplorerSettings = optional(object({
      authentication = object({
        method = string
        systemAssignedManagedIdentitySettings = optional(object({
          audience = optional(string)
        }))
        userAssignedManagedIdentitySettings = optional(object({
          clientId = string
          scope    = optional(string)
          tenantId = string
        }))
      })
      batching = optional(object({
        latencySeconds = optional(number)
        maxMessages    = optional(number)
      }))
      database = string
      host     = string
    }))
    dataLakeStorageSettings = optional(object({
      authentication = object({
        accessTokenSettings = optional(object({
          secretRef = string
        }))
        method = string
        systemAssignedManagedIdentitySettings = optional(object({
          audience = optional(string)
        }))
        userAssignedManagedIdentitySettings = optional(object({
          clientId = string
          scope    = optional(string)
          tenantId = string
        }))
      })
      batching = optional(object({
        latencySeconds = optional(number)
        maxMessages    = optional(number)
      }))
      host = string
    }))
    fabricOneLakeSettings = optional(object({
      authentication = object({
        method = string
        systemAssignedManagedIdentitySettings = optional(object({
          audience = optional(string)
        }))
        userAssignedManagedIdentitySettings = optional(object({
          clientId = string
          scope    = optional(string)
          tenantId = string
        }))
      })
      batching = optional(object({
        latencySeconds = optional(number)
        maxMessages    = optional(number)
      }))
      host = string
      names = object({
        lakehouseName = string
        workspaceName = string
      })
      oneLakePathType = string
    }))
    kafkaSettings = optional(object({
      authentication = object({
        method = string
        saslSettings = optional(object({
          saslType  = string
          secretRef = string
        }))
        systemAssignedManagedIdentitySettings = optional(object({
          audience = optional(string)
        }))
        userAssignedManagedIdentitySettings = optional(object({
          clientId = string
          scope    = optional(string)
          tenantId = string
        }))
        x509CertificateSettings = optional(object({
          secretRef = string
        }))
      })
      batching = optional(object({
        latencyMs   = optional(number)
        maxBytes    = optional(number)
        maxMessages = optional(number)
        mode        = optional(string)
      }))
      cloudEventAttributes = optional(string)
      compression          = optional(string)
      consumerGroupId      = optional(string)
      copyMqttProperties   = optional(string)
      host                 = string
      kafkaAcks            = optional(string)
      partitionStrategy    = optional(string)
      tls = optional(object({
        mode                             = optional(string)
        trustedCaCertificateConfigMapRef = optional(string)
      }))
    }))
    localStorageSettings = optional(object({
      persistentVolumeClaimRef = string
    }))
    mqttSettings = optional(object({
      authentication = optional(object({
        method = string
        serviceAccountTokenSettings = optional(object({
          audience = string
        }))
        systemAssignedManagedIdentitySettings = optional(object({
          audience = optional(string)
        }))
        userAssignedManagedIdentitySettings = optional(object({
          clientId = string
          scope    = optional(string)
          tenantId = string
        }))
        x509CertificateSettings = optional(object({
          secretRef = string
        }))
      }))
      clientIdPrefix       = optional(string)
      cloudEventAttributes = optional(string)
      host                 = optional(string)
      keepAliveSeconds     = optional(number)
      maxInflightMessages  = optional(number)
      protocol             = optional(string)
      qos                  = optional(number)
      retain               = optional(string)
      sessionExpirySeconds = optional(number)
      tls = optional(object({
        mode                             = optional(string)
        trustedCaCertificateConfigMapRef = optional(string)
      }))
    }))
  }))
  description = "List of custom dataflow endpoints to create"
  default     = []
}
