---
title: Microsoft Fabric RTI Component
description: Real-Time Intelligence EventStream with Go template-based DAG architecture supporting CustomEndpoint sources, all EventStream operators, and Eventhouse destinations for AIO data flow integration
author: Edge AI Team
ms.date: 2025-07-27
ms.topic: reference
keywords:
  - microsoft fabric
  - real-time intelligence
  - eventstream
  - dag configuration
  - customendpoint
  - eventhouse
  - azure iot operations
  - operators
  - terraform
estimated_reading_time: 8
---

## Microsoft Fabric RTI Component

This component creates a Microsoft Fabric Real-Time Intelligence (RTI) EventStream with a Go template-based DAG (Directed Acyclic Graph) architecture. It supports CustomEndpoint sources, all available EventStream operators, and Eventhouse destinations for comprehensive AIO data flow integration.

## Purpose and Role

The Fabric RTI component serves as the cloud-side real-time data processing hub for the Edge AI Accelerator:

- **Data Flow Orchestration**: Creates complex data processing pipelines using DAG-based configuration
- **Edge Integration**: Provides CustomEndpoint sources for seamless AIO dataflow integration
- **Real-Time Processing**: Supports all 7 EventStream operators for advanced data transformation
- **Analytics Integration**: Routes processed data to Eventhouse for real-time analytics

## DAG Architecture

### Node Types

The component supports four categories of DAG nodes:

#### Sources

- **CustomEndpoint**: Data input points for edge device connectivity

#### Operators

- **Filter**: Apply conditional data filtering based on field values
- **GroupBy**: Aggregate data with grouping and windowing functions
- **Join**: Combine data streams with temporal join conditions
- **ManageFields**: Add, remove, rename, or cast data fields
- **Aggregate**: Perform aggregation functions with partitioning
- **Union**: Merge multiple data streams
- **Expand**: Extract nested JSON data into separate fields

#### Streams

- **DerivedStream**: Intermediate data flow representations for complex routing

#### Destinations

- **Eventhouse**: Data output points for real-time analytics storage

### Node Connection System

Each node has a unique `name` (user-defined) and nodes specify `input_nodes` as a list of names they receive data from. Node names must be unique across all DAG elements to ensure proper deployment.

## Usage Examples

### Basic Data Flow

```hcl
module "fabric_rti" {
  source = "./src/000-cloud/032-fabric-rti/terraform"

  resource_prefix = "myproject"
  environment     = "dev"
  instance        = "001"
  location        = "East US"

  resource_group     = local.resource_group
  fabric_workspace   = local.fabric_workspace
  fabric_eventhouse  = local.fabric_eventhouse
  fabric_kql_databases = local.fabric_kql_databases
  aio_identity       = local.aio_identity

  # Simple source to destination flow
  sources_custom_endpoints = [{
    name = "mqtt-telemetry"
    properties = {
      input_serialization = {
        type     = "Json"
        encoding = "UTF8"
      }
    }
  }]

  destinations_eventhouse = [{
    name        = "analytics-sink"
    input_nodes = ["mqtt-telemetry"]
    properties = {
      data_ingestion_mode = "DirectIngestion"
      table_name         = "device_telemetry"
    }
  }]
}
```

### Advanced Processing Pipeline

```hcl
module "fabric_rti" {
  source = "./src/000-cloud/032-fabric-rti/terraform"

  # ... basic configuration ...

  sources_custom_endpoints = [{
    name = "sensor-data"
    properties = {
      input_serialization = {
        type     = "Json"
        encoding = "UTF8"
      }
    }
  }]

  # Filter out invalid readings
  operators_filter = [{
    name        = "valid-readings"
    input_nodes = ["sensor-data"]
    properties = {
      conditions = [{
        field     = "temperature"
        operator  = "GreaterThan"
        value     = "-50"
        data_type = "Double"
      }, {
        field     = "temperature"
        operator  = "LessThan"
        value     = "100"
        data_type = "Double"
      }]
    }
  }]

  # Add computed fields
  operators_manage_fields = [{
    name        = "enriched-data"
    input_nodes = ["valid-readings"]
    properties = {
      columns = [{
        operation    = "add"
        target_field = "celsius_to_fahrenheit"
        data_type    = "Double"
        value        = "(temperature * 9/5) + 32"
      }, {
        operation    = "add"
        target_field = "processing_timestamp"
        data_type    = "DateTime"
        value        = "utcnow()"
      }]
    }
  }]

  # Aggregate by time windows
  operators_group_by = [{
    name        = "hourly-averages"
    input_nodes = ["enriched-data"]
    properties = {
      aggregations = [{
        field      = "temperature"
        function   = "Average"
        alias_name = "avg_temperature"
      }, {
        field      = "humidity"
        function   = "Average"
        alias_name = "avg_humidity"
      }]
      group_by = ["device_id", "location"]
      window = {
        type     = "tumbling"
        duration = "1h"
      }
    }
  }]

  destinations_eventhouse = [{
    name        = "processed-analytics"
    input_nodes = ["hourly-averages"]
    properties = {
      data_ingestion_mode = "DirectIngestion"
      table_name         = "sensor_analytics"
    }
  }]
}
```

## Template Override System

For advanced scenarios, you can provide custom template files:

```hcl
module "fabric_rti" {
  source = "./src/000-cloud/032-fabric-rti/terraform"

  # ... basic configuration ...

  eventstream_template_file_path = "./custom-templates/my-eventstream.json.tmpl"
  template_tokens = {
    CustomValue1 = "production-config"
    CustomValue2 = "advanced-settings"
  }
}
```

Custom template example (`my-eventstream.json.tmpl`):

```json
{
  "compatibilityLevel": "1.0",
  "sources": [
    {
      "id": "{{ .CustomValue1 }}-source",
      "name": "custom-source",
      "type": "CustomEndpoint",
      "properties": {
        "customSetting": "{{ .CustomValue2 }}"
      }
    }
  ]
}
```

## Component Resources

This component creates the following resources:

### EventStream Infrastructure

- **Fabric EventStream**: Main data processing pipeline with DAG configuration
- **Role Assignment**: AIO managed identity access to Fabric workspace

### Integration Outputs

- **CustomEndpoint Connection**: Kafka-compatible connection details for edge integration
- **DAG Configuration Statistics**: Node counts and names for debugging

## Dependencies

This component requires the following dependencies:

- **000-resource-group**: Azure resource group for all resources
- **010-security-identity**: AIO managed identity for workspace access
- **031-fabric**: Fabric workspace and eventhouse provisioning

## Outputs

The component provides the following outputs for integration:

### custom_endpoint_connection (sensitive)

```hcl
{
  bootstrap_server    = "es-myproject-dev-001.servicebus.windows.net:9093"
  topic_name         = "es_12345678_abcd_1234_5678_123456789abc"
  authentication_type = "entra_id"
  tenant_id          = "00000000-0000-0000-0000-000000000000"
  client_id          = "11111111-1111-1111-1111-111111111111"
}
```

### eventstream

```hcl
{
  id           = "12345678-abcd-1234-5678-123456789abc"
  display_name = "es-myproject-dev-001"
  workspace_id = "87654321-dcba-4321-8765-cba987654321"
}
```

### eventstream_dag_configuration

```hcl
{
  sources_count      = 1
  destinations_count = 1
  streams_count      = 0
  operators_count    = 3
  node_names         = ["mqtt-telemetry", "valid-readings", "enriched-data", "hourly-averages", "analytics-sink"]
}
```

## Deployment Options

### Terraform

Refer to [Terraform Components - Getting Started](../README.md#terraform-components---getting-started) for deployment instructions.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

## Integration with Other Components

This component integrates with other parts of the solution:

- **Edge Messaging**: Consumes CustomEndpoint connection details for AIO dataflow configuration
- **Fabric Workspace**: Uses provisioned workspace and eventhouse from 031-fabric component
- **Security Identity**: Uses AIO managed identity for secure workspace access
- **Blueprints**: Orchestrated with other components for end-to-end data flow solutions

## Security Considerations

- AIO managed identity follows principle of least privilege with Contributor role to Fabric workspace only
- CustomEndpoint connection details are marked as sensitive outputs
- Entra ID authentication ensures secure edge-to-cloud communication
- Template override system allows advanced customization while maintaining security boundaries

## External References

### Microsoft Fabric Real-Time Intelligence Documentation

- [Microsoft Fabric Real-Time Intelligence Overview](https://learn.microsoft.com/fabric/real-time-intelligence/) - Complete platform overview and real-time analytics capabilities
- [Eventhouse Overview](https://learn.microsoft.com/fabric/real-time-intelligence/eventhouse) - Real-time analytics engine for time-series data and streaming workloads
- [Create a KQL Database](https://learn.microsoft.com/fabric/real-time-intelligence/create-database) - Database creation, management, and configuration for analytics
- [Deploy an Eventhouse using Fabric APIs](https://learn.microsoft.com/fabric/real-time-intelligence/eventhouse-deploy-with-fabric-api) - Programmatic deployment patterns and automation

### EventStream Configuration and Management

- [EventStream REST API](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/eventstream-rest-api) - Complete API specification for sources, destinations, operators, and streaming configuration
- [Add and Manage EventStream Sources](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/add-manage-eventstream-sources) - All supported data sources, CustomEndpoint configuration, and connectivity options
- [Add and Manage EventStream Destinations](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/add-manage-eventstream-destinations) - Eventhouse destination configuration and data routing options

### API Templates and Implementation Examples

- [Microsoft Fabric EventStreams GitHub Repository](https://github.com/microsoft/fabric-event-streams) - Official API templates, sample implementations, and best practices
- [EventStream Definition Template](https://github.com/microsoft/fabric-event-streams/blob/main/API%20Templates/eventstream-definition.json) - Complete JSON template with all source types, destinations, operators, and configuration examples
- [EventStream GitHub Integration](https://learn.microsoft.com/fabric/real-time-intelligence/git-eventstream) - DevOps integration patterns, source control, and CI/CD pipeline configuration

### Terraform Provider and Infrastructure Automation

- [Terraform Provider for Microsoft Fabric](https://registry.terraform.io/providers/microsoft/fabric/latest/docs) - Microsoft Fabric Terraform Provider documentation and guides

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
