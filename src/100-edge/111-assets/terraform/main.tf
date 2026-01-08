/**
 * # Kubernetes Assets
 *
 * Deploys Kubernetes asset definitions to a connected cluster using the namespaced
 * Device Registry model. This component facilitates the management of devices and
 * assets within ADR namespaces.
 */

locals {
  /* Default configurations for legacy asset endpoint profile and asset */
  default_asset_endpoint_profile = {
    endpoint_profile_type = "Microsoft.OpcUa"
    method                = "Anonymous"
    name                  = "opc-ua-connector-0"
    target_address        = "opc.tcp://opcplc-000000:50000"
  }

  default_asset = {
    asset_endpoint_profile_ref     = local.default_asset_endpoint_profile.name
    default_datasets_configuration = "{\"samplingInterval\":500,\"queueSize\":1,\"publishingInterval\":1000}"
    description                    = "An oven is essential for baking a wide variety of products."
    display_name                   = "oven"
    documentation_uri              = "http://docs.contoso.com/ovens"
    enabled                        = true
    hardware_revision              = "2.3"
    manufacturer                   = "Contoso"
    manufacturer_uri               = "http://www.contoso.com/ovens"
    model                          = "Oven-003"
    name                           = "oven"
    product_code                   = "12345C"
    serial_number                  = "12345"
    software_revision              = "14.1"
    datasets = [
      {
        name = "default-dataset"
        data_points = [
          {
            data_point_configuration = "{\"samplingInterval\":500,\"queueSize\":1}"
            data_source              = "ns=3;s=FastUInt10"
            name                     = "Temperature"
            observability_mode       = "None"
          },
          {
            data_point_configuration = "{\"samplingInterval\":500,\"queueSize\":1}"
            data_source              = "ns=3;s=FastUInt4"
            name                     = "FillWeight"
            observability_mode       = "None"
          },
          {
            data_point_configuration = "{\"samplingInterval\":500,\"queueSize\":1}"
            data_source              = "ns=3;s=FastUInt5"
            name                     = "EnergyUse"
            observability_mode       = "None"
          }
        ]
      }
    ]
  }

  /* Default configurations for namespaced device and asset */
  default_namespaced_device = {
    name    = "namespaced-opc-ua-connector"
    enabled = true
    endpoints = {
      enabled = true
      outbound = {
        assigned = {}
      }
      inbound = {
        "namespaced-opc-ua-connector-0" = {
          endpoint_type           = "Microsoft.OpcUa"
          address                 = "opc.tcp://opcplc-000000:50000"
          version                 = null
          additionalConfiguration = null
          authentication = {
            method = "Anonymous"
          }
          trustSettings = null
        }
      }
    }
  }

  default_namespaced_asset = {
    name         = "namespace-oven"
    display_name = "oven namespaced"
    device_ref = {
      device_name   = local.default_namespaced_device.name
      endpoint_name = "namespaced-opc-ua-connector-0"
    }
    description       = "Multi-function large oven for baked goods."
    documentation_uri = "http://docs.contoso.com/ovens"
    enabled           = true
    hardware_revision = "2.3"
    manufacturer      = "Contoso"
    manufacturer_uri  = "http://www.contoso.com/ovens"
    model             = "Oven-003"
    product_code      = "12345C"
    serial_number     = "12345"
    software_revision = "14.1"
    attributes        = {}
    datasets = [
      {
        name = "Oven namespaced telemetry"
        data_points = [
          {
            name                     = "Temp"
            data_source              = "ns=3;s=FastUInt10"
            data_point_configuration = "{\"publishingInterval\":1000,\"samplingInterval\":500,\"queueSize\":1}"
          },
          {
            name                     = "FillWeight"
            data_source              = "ns=3;s=FastUInt4"
            data_point_configuration = "{\"publishingInterval\":1000,\"samplingInterval\":500,\"queueSize\":1}"
          },
          {
            name                     = "EnergyUse"
            data_source              = "ns=3;s=FastUInt5"
            data_point_configuration = "{\"publishingInterval\":1000,\"samplingInterval\":500,\"queueSize\":1}"
          }
        ]
        destinations = [
          {
            target = "Mqtt"
            configuration = {
              topic  = "azure-iot-operations/data/namespace-oven"
              retain = "Never"
              qos    = "Qos1"
            }
          }
        ]
      }
    ]
    default_datasets_configuration = "{\"publishingInterval\":1000,\"samplingInterval\":500,\"queueSize\":1}"
  }

  processed_asset_endpoint_profiles = {
    for profile in concat(
      var.should_create_default_asset ? [local.default_asset_endpoint_profile] : [],
      var.asset_endpoint_profiles
      ) : profile.name => {
      endpoint_profile_type = coalesce(profile.endpoint_profile_type, "Microsoft.OpcUa")
      method                = coalesce(profile.method, "Anonymous")
      name                  = profile.name
      opc_additional_config_string = try(
        coalesce(
          profile.opc_additional_config_string,
          coalesce(profile.should_enable_opc_asset_discovery, false) ? jsonencode({ runAssetDiscovery = true }) : null
        ),
        null
      )
      target_address = profile.target_address
    }
  }

  processed_assets = {
    for asset in concat(
      var.should_create_default_asset ? [local.default_asset] : [],
      var.assets
      ) : asset.name => {
      asset_endpoint_profile_ref     = asset.asset_endpoint_profile_ref
      default_datasets_configuration = coalesce(asset.default_datasets_configuration, "{\"samplingInterval\":500,\"queueSize\":1,\"publishingInterval\":1000}")
      description                    = try(asset.description, null)
      display_name                   = coalesce(asset.display_name, asset.name)
      documentation_uri              = try(asset.documentation_uri, null)
      enabled                        = coalesce(asset.enabled, true)
      hardware_revision              = try(asset.hardware_revision, null)
      manufacturer                   = try(asset.manufacturer, null)
      manufacturer_uri               = try(asset.manufacturer_uri, null)
      model                          = try(asset.model, null)
      name                           = asset.name
      product_code                   = try(asset.product_code, null)
      serial_number                  = try(asset.serial_number, null)
      software_revision              = try(asset.software_revision, null)
      datasets = [
        for dataset in try(coalesce(asset.datasets), []) : {
          name = dataset.name
          data_points = [
            for data_point in dataset.data_points : {
              data_point_configuration = coalesce(data_point.data_point_configuration, "{\"samplingInterval\":500,\"queueSize\":1}")
              data_source              = data_point.data_source
              name                     = data_point.name
              observability_mode       = coalesce(data_point.observability_mode, "None")
            }
          ]
        }
      ]
    }
  }

  /* Processed collections for namespaced assets with enhanced logic */
  processed_namespaced_devices = {
    for device in concat(
      var.should_create_default_namespaced_asset ? [local.default_namespaced_device] : [],
      var.namespaced_devices
      ) : device.name => {
      name    = device.name
      enabled = coalesce(device.enabled, true)
      endpoints = {
        for endpoint_block, value in {
          inbound = {
            for endpoint_name, endpoint in device.endpoints.inbound : endpoint_name => {
              for property_name, property_value in {
                endpointType            = endpoint.endpoint_type
                address                 = endpoint.address
                version                 = endpoint.version
                authentication          = endpoint.authentication
                trustSettings           = endpoint.trustSettings
                additionalConfiguration = endpoint.additionalConfiguration
              } : property_name => property_value if property_value != null
            }
          }
          outbound = try(device.endpoints.outbound, null)
        } : endpoint_block => value if value != null && (endpoint_block != "outbound" || length(value) > 0)
      }
    }
  }

  processed_namespaced_assets = {
    for asset in concat(
      var.should_create_default_namespaced_asset ? [local.default_namespaced_asset] : [],
      var.namespaced_assets
      ) : asset.name => {
      name              = asset.name
      display_name      = coalesce(asset.display_name, asset.name)
      device_ref        = asset.device_ref
      description       = try(asset.description, null)
      documentation_uri = try(asset.documentation_uri, null)
      enabled           = coalesce(asset.enabled, true)
      hardware_revision = try(asset.hardware_revision, null)
      manufacturer      = try(asset.manufacturer, null)
      manufacturer_uri  = try(asset.manufacturer_uri, null)
      model             = try(asset.model, null)
      product_code      = try(asset.product_code, null)
      serial_number     = try(asset.serial_number, null)
      software_revision = try(asset.software_revision, null)
      attributes        = try(asset.attributes, {})
      datasets = [
        for dataset in try(asset.datasets, []) : {
          name                  = dataset.name
          dataset_configuration = try(dataset.dataset_configuration, null)
          data_source           = try(dataset.data_source, null)
          type_ref              = try(dataset.type_ref, null)
          data_points = [
            for data_point in dataset.data_points : {
              name                      = data_point.name
              data_source               = data_point.data_source
              data_point_configuration  = data_point.data_point_configuration
              rest_sampling_interval_ms = try(data_point.rest_sampling_interval_ms, null)
              rest_mqtt_topic           = try(data_point.rest_mqtt_topic, null)
              rest_include_state_store  = try(data_point.rest_include_state_store, null)
              rest_state_store_key      = try(data_point.rest_state_store_key, null)
            }
          ]
          destinations = try(dataset.destinations, [])
        }
      ]
      streams           = try(asset.streams, [])
      event_groups      = try(asset.event_groups, [])
      management_groups = try(asset.management_groups, [])
      default_datasets_configuration = coalesce(
        try(asset.default_datasets_configuration, null),
        "{\"publishingInterval\":1000,\"samplingInterval\":500,\"queueSize\":1}"
      )
      default_streams_configuration = coalesce(
        try(asset.default_streams_configuration, null),
        "{\"bufferSize\":1024,\"compressionEnabled\":false}"
      )
      default_events_configuration = coalesce(
        try(asset.default_events_configuration, null),
        "{\"publishingInterval\":1000,\"samplingInterval\":500,\"queueSize\":1}"
      )
    }
  }

  /* Check if any asset endpoint profile has asset discovery enabled */
  should_enable_opc_asset_discovery = anytrue([
    for profile in concat(
      var.should_create_default_asset ? [local.default_asset_endpoint_profile] : [],
      var.asset_endpoint_profiles
    ) : try(profile.should_enable_opc_asset_discovery, false)
  ])
}

/*
 * Namespaced Devices (replaces Asset Endpoint Profiles)
 */
resource "azapi_resource" "namespaced_device" {
  for_each = local.processed_namespaced_devices

  type                      = "Microsoft.DeviceRegistry/namespaces/devices@2025-10-01"
  name                      = each.value.name
  parent_id                 = var.adr_namespace.id
  schema_validation_enabled = false # Disable schema validation until azapi provider schema support is available

  body = {
    location = var.location
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = {
      enabled   = each.value.enabled
      endpoints = each.value.endpoints
    }
  }
}

/*
 * Namespaced Asset Instances
 */
resource "azapi_resource" "namespaced_asset" {
  for_each = local.processed_namespaced_assets

  type                      = "Microsoft.DeviceRegistry/namespaces/assets@2025-10-01"
  name                      = each.value.name
  parent_id                 = var.adr_namespace.id
  schema_validation_enabled = false # Disable schema validation until azapi provider schema support is available

  body = {
    location = var.location
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = merge(
      {
        attributes                   = each.value.attributes
        defaultDatasetsConfiguration = each.value.default_datasets_configuration
        defaultEventsConfiguration   = each.value.default_events_configuration
        deviceRef = {
          deviceName   = each.value.device_ref.device_name
          endpointName = each.value.device_ref.endpoint_name
        }
        displayName = each.value.display_name
        enabled     = each.value.enabled
        datasets = [
          for dataset in each.value.datasets : merge(
            {
              name         = dataset.name
              destinations = try(dataset.destinations, [])
            },
            length(dataset.data_points) > 0 ? {
              dataPoints = [
                for data_point in dataset.data_points : merge(
                  {
                    name                   = data_point.name
                    dataSource             = data_point.data_source
                    dataPointConfiguration = data_point.data_point_configuration
                  },
                  data_point.rest_sampling_interval_ms != null ? { samplingIntervalMs = data_point.rest_sampling_interval_ms } : {},
                  data_point.rest_mqtt_topic != null ? { mqttTopic = data_point.rest_mqtt_topic } : {},
                  data_point.rest_include_state_store != null ? { includeStateStore = data_point.rest_include_state_store } : {},
                  data_point.rest_state_store_key != null ? { stateStoreKey = data_point.rest_state_store_key } : {}
                )
              ]
            } : {},
            dataset.dataset_configuration != null ? { datasetConfiguration = dataset.dataset_configuration } : {},
            dataset.data_source != null ? { dataSource = dataset.data_source } : {},
            dataset.type_ref != null ? { typeRef = dataset.type_ref } : {}
          )
        ]
      },
      length(each.value.streams) > 0 ? {
        streams = [
          for stream in each.value.streams : merge(
            {
              name         = stream.name
              destinations = try(stream.destinations, [])
            },
            stream.stream_configuration != null ? { streamConfiguration = stream.stream_configuration } : {},
            stream.type_ref != null ? { typeRef = stream.type_ref } : {}
          )
        ]
      } : {},
      length(each.value.event_groups) > 0 ? {
        eventGroups = [
          for event_group in each.value.event_groups : merge(
            {
              name = event_group.name
              events = [
                for event in event_group.events : merge(
                  {
                    name       = event.name
                    dataSource = event.data_source
                  },
                  event.event_configuration != null ? { eventConfiguration = event.event_configuration } : {},
                  event.type_ref != null ? { typeRef = event.type_ref } : {},
                  length(try(event.destinations, [])) > 0 ? { destinations = event.destinations } : {}
                )
              ]
            },
            event_group.data_source != null ? { dataSource = event_group.data_source } : {},
            event_group.event_group_configuration != null ? { eventGroupConfiguration = event_group.event_group_configuration } : {},
            event_group.type_ref != null ? { typeRef = event_group.type_ref } : {},
            length(try(event_group.default_destinations, [])) > 0 ? { defaultDestinations = event_group.default_destinations } : {}
          )
        ]
      } : {},
      length(each.value.management_groups) > 0 ? {
        managementGroups = [
          for management_group in each.value.management_groups : merge(
            {
              name = management_group.name
              actions = [
                for action in management_group.actions : merge(
                  {
                    name       = action.name
                    actionType = action.action_type
                    targetUri  = action.target_uri
                  },
                  action.topic != null ? { topic = action.topic } : {},
                  action.timeout_in_seconds != null ? { timeoutInSeconds = action.timeout_in_seconds } : {},
                  action.action_configuration != null ? { actionConfiguration = action.action_configuration } : {},
                  action.type_ref != null ? { typeRef = action.type_ref } : {}
                )
              ]
            },
            management_group.data_source != null ? { dataSource = management_group.data_source } : {},
            management_group.management_group_configuration != null ? { managementGroupConfiguration = management_group.management_group_configuration } : {},
            management_group.type_ref != null ? { typeRef = management_group.type_ref } : {},
            management_group.default_topic != null ? { defaultTopic = management_group.default_topic } : {},
            management_group.default_timeout_in_seconds != null ? { defaultTimeoutInSeconds = management_group.default_timeout_in_seconds } : {}
          )
        ]
      } : {},
      length(each.value.streams) > 0 ? { defaultStreamsConfiguration = each.value.default_streams_configuration } : {},
      each.value.description != null ? { description = each.value.description } : {},
      each.value.documentation_uri != null ? { documentationUri = each.value.documentation_uri } : {},
      each.value.hardware_revision != null ? { hardwareRevision = each.value.hardware_revision } : {},
      each.value.manufacturer != null ? { manufacturer = each.value.manufacturer } : {},
      each.value.manufacturer_uri != null ? { manufacturerUri = each.value.manufacturer_uri } : {},
      each.value.model != null ? { model = each.value.model } : {},
      each.value.product_code != null ? { productCode = each.value.product_code } : {},
      each.value.serial_number != null ? { serialNumber = each.value.serial_number } : {},
      each.value.software_revision != null ? { softwareRevision = each.value.software_revision } : {}
    )
  }

  depends_on = [azapi_resource.namespaced_device]
}

/*
 * Legacy Asset Endpoint Profiles
 */
resource "azapi_resource" "asset_endpoint_profile" {
  for_each = local.processed_asset_endpoint_profiles

  type      = "Microsoft.DeviceRegistry/assetEndpointProfiles@2025-10-01"
  name      = each.value.name
  parent_id = var.resource_group.id
  body = {
    location = var.location
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = merge(
      {
        authentication = {
          method = each.value.method
        }
        endpointProfileType = each.value.endpoint_profile_type
        targetAddress       = each.value.target_address
      },
      each.value.opc_additional_config_string != null ? {
        additionalConfiguration = each.value.opc_additional_config_string
      } : {}
    )
  }

  schema_validation_enabled = false # Disable schema validation until azapi provider schema support is available
}

/*
 * Legacy Asset Instances
 */
resource "azapi_resource" "asset" {
  for_each = local.processed_assets

  type      = "Microsoft.DeviceRegistry/assets@2025-10-01"
  name      = each.value.name
  parent_id = var.resource_group.id

  body = {
    location = var.location
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = {
      assetEndpointProfileRef = each.value.asset_endpoint_profile_ref
      datasets = [
        for dataset in each.value.datasets : {
          name = dataset.name
          dataPoints = [
            for data_point in dataset.data_points : {
              dataPointConfiguration = data_point.data_point_configuration
              dataSource             = data_point.data_source
              name                   = data_point.name
              observabilityMode      = data_point.observability_mode
            }
          ]
        }
      ]
      defaultDatasetsConfiguration = each.value.default_datasets_configuration
      description                  = each.value.description
      displayName                  = each.value.display_name
      documentationUri             = each.value.documentation_uri
      enabled                      = each.value.enabled
      hardwareRevision             = each.value.hardware_revision
      manufacturer                 = each.value.manufacturer
      manufacturerUri              = each.value.manufacturer_uri
      model                        = each.value.model
      productCode                  = each.value.product_code
      serialNumber                 = each.value.serial_number
      softwareRevision             = each.value.software_revision
    }
  }

  depends_on = [azapi_resource.asset_endpoint_profile]
}

/*
 * K8 Bridge Role Assignment Module
 */
module "k8_bridge_role_assignment" {
  source = "./modules/role-assignment-post"
  count  = local.should_enable_opc_asset_discovery ? 1 : 0

  custom_location_id      = var.custom_location_id
  k8s_bridge_principal_id = var.k8s_bridge_principal_id
}
