---
title: Fabric RTI Minimal Blueprint
description: Essential Microsoft Fabric Real-Time Intelligence (RTI) components on top of existing Azure IoT Operations infrastructure with CustomEndpoint for AIO integration
author: Edge AI Team
ms.date: 07/29/2025
ms.topic: reference
estimated_reading_time: 9
keywords:
  - microsoft fabric
  - real-time intelligence
  - blueprint
  - azure iot operations
  - eventstream
  - customendpoint
  - eventhouse
  - minimal deployment
  - terraform
---

This blueprint deploys only the essential Microsoft Fabric Real-Time Intelligence (RTI) components on top of existing Azure IoT Operations infrastructure, using data sources to reference already deployed resources. It creates an EventStream with CustomEndpoint for AIO integration and configures the edge messaging dataflow endpoint.

## Architecture

This minimal blueprint creates:

- **Fabric RTI Components**:
  - Microsoft Fabric EventStream with CustomEndpoint source → Eventhouse destination
  - Data ingestion configuration for real-time analytics

- **Edge Messaging Components**:
  - AIO dataflow endpoint connecting to Fabric RTI EventStream
  - Secure data transmission using managed identity authentication

## Prerequisites

### Required Existing Infrastructure

This blueprint requires the following infrastructure to already be deployed (typically via `full-single-node-cluster` or similar blueprints):

- **Azure Resource Group** with all AIO resources
- **Azure IoT Operations (AIO) Instance** with running workloads
- **Arc-connected Kubernetes Cluster** with AIO deployed
- **Custom Location** for AIO instance
- **User-assigned Managed Identity** for AIO with appropriate permissions
- **Microsoft Fabric Workspace** with RTI capabilities enabled
- **Microsoft Fabric Eventhouse** with default KQL database

### Required Tools

- Terraform >= 1.9.8
- Azure CLI authenticated and initialized (`source ./scripts/az-sub-init.sh`)

### Required Providers

- `hashicorp/azurerm` >= 4.8.0
- `azure/azapi` >= 2.0.1
- `microsoft/fabric` >= 0.1.0

## Usage

### Basic Deployment

```hcl
module "fabric_rti_minimal" {
  source = "./blueprints/fabric-rti-minimal/terraform"

  environment     = "dev"
  location        = "eastus2"
  resource_prefix = "mycompany"
  instance        = "001"
}
```

### With Custom Resource Names

```hcl
module "fabric_rti_minimal" {
  source = "./blueprints/fabric-rti-minimal/terraform"

  environment     = "prod"
  location        = "eastus2"
  resource_prefix = "mycompany"
  instance        = "001"

  # Custom existing resource names
  resource_group_name       = "rg-mycompany-prod-custom"
  fabric_workspace_name     = "ws-fabric-analytics"
  fabric_eventhouse_name    = "evh-iot-data"
  aio_instance_name         = "aio-prod-instance"
  custom_location_name      = "cl-prod-location"
  aio_identity_name         = "id-aio-managed"

  # EventStream configuration
  eventstream_table_name = "production_telemetry"
}
```

## Variables

### Required Variables

| Name              | Description                                       | Type     |
|-------------------|---------------------------------------------------|----------|
| `environment`     | Environment for all resources: dev, test, or prod | `string` |
| `location`        | Azure region for all resources                    | `string` |
| `resource_prefix` | Prefix for all resource names                     | `string` |

### Optional Variables

| Name                                | Description                                | Type     | Default                                                          |
|-------------------------------------|--------------------------------------------|----------|------------------------------------------------------------------|
| `instance`                          | Instance identifier for naming resources   | `string` | `"001"`                                                          |
| `resource_group_name`               | Name of existing resource group            | `string` | `"rg-{resource_prefix}-{environment}-{instance}"`                |
| `fabric_workspace_name`             | Display name of existing Fabric workspace  | `string` | `"ws-{resource_prefix}-{environment}-{instance}"`                |
| `fabric_eventhouse_name`            | Display name of existing Fabric eventhouse | `string` | `"evh-{resource_prefix}-{environment}-{instance}"`               |
| `aio_identity_name`                 | Name of existing AIO managed identity      | `string` | `"id-{resource_prefix}-{environment}-aio-{instance}"`            |
| `aio_instance_name`                 | Name of existing AIO instance              | `string` | `"arck-{resource_prefix}-{environment}-{instance}-ops-instance"` |
| `custom_location_name`              | Name of existing custom location           | `string` | `"arck-{resource_prefix}-{environment}-{instance}-cl"`           |
| `eventstream_table_name`            | Eventhouse table name for data ingestion   | `string` | `"iot_telemetry"`                                                |
| `should_create_eventgrid_dataflows` | Whether to create EventGrid dataflows      | `bool`   | `false`                                                          |
| `should_create_eventhub_dataflows`  | Whether to create EventHub dataflows       | `bool`   | `false`                                                          |

## Outputs

| Name                            | Description                                        |
|---------------------------------|----------------------------------------------------|
| `fabric_eventstream`            | The Microsoft Fabric EventStream details           |
| `fabric_rti_connection`         | Custom endpoint connection details (sensitive)     |
| `eventstream_dag_configuration` | DAG configuration used for EventStream creation    |
| `fabric_rti_dataflow`           | The Fabric RTI dataflow endpoint details           |
| `resource_group`                | The existing resource group reference              |
| `fabric_workspace`              | The existing Microsoft Fabric workspace reference  |
| `fabric_eventhouse`             | The existing Microsoft Fabric Eventhouse reference |
| `aio_instance`                  | The existing Azure IoT Operations instance         |
| `aio_custom_location`           | The existing custom location reference             |

## Data Flow

1. **AIO Data Processing**: Existing AIO instance processes data through configured workloads
2. **Fabric EventStream**: New EventStream receives data via CustomEndpoint from AIO dataflow
3. **Real-Time Analytics**: EventStream ingests data directly into existing Eventhouse for real-time analytics
4. **Data Visualization**: Use Fabric Real-Time Dashboards to visualize streaming data

## Security

- Uses existing managed identity for authentication between AIO and Fabric
- Data transmission encrypted with TLS 1.2+
- Leverages existing RBAC permissions from full deployment
- No additional secrets or keys required

## Deployment Steps

1. **Initialize Azure Subscription**:

   ```bash
   source ./scripts/az-sub-init.sh
   ```

2. **Initialize Terraform**:

   ```bash
   cd blueprints/fabric-rti-minimal/terraform
   terraform init
   ```

3. **Create terraform.tfvars**:

   ```hcl
   environment     = "dev"
   location        = "eastus2"
   resource_prefix = "mycompany"
   instance        = "001"
   ```

4. **Plan Deployment**:

   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```

5. **Apply Configuration**:

   ```bash
   terraform apply -var-file="terraform.tfvars"
   ```

6. **Verify Deployment**:
   - Check EventStream in Microsoft Fabric portal
   - Verify dataflow endpoint in AIO operations
   - Test data flow from AIO to Fabric RTI

## Troubleshooting

### Common Issues

1. **Missing Prerequisites**: Ensure all required infrastructure is deployed and accessible
2. **Resource Naming**: Verify existing resource names match expected patterns or override with variables
3. **Permissions**: Ensure AIO managed identity has appropriate Fabric permissions
4. **Data Source Failures**: Check that all referenced resources exist and are accessible

### Validation Commands

```bash
# Check AIO dataflow status
az iot ops dataflow list --instance-name {aio-instance-name} -g {resource-group-name}

# Verify EventStream in Fabric
# Use Fabric portal to check EventStream health and data ingestion

# Check custom endpoint connection
az iot ops dataflow show --name fabric-rti-dataflow --instance-name {aio-instance-name} -g {resource-group-name}
```

## Cleanup

To remove only the Fabric RTI components:

```bash
terraform destroy -var-file="terraform.tfvars"
```

**Note**: This will only remove the EventStream and dataflow endpoint. Existing infrastructure remains unchanged.

## Next Steps

After deployment:

1. **Configure Data Sources**: Set up AIO assets and data sources to send data to the EventStream
2. **Build Real-Time Dashboards**: Use Fabric Real-Time Intelligence to create dashboards
3. **Set Up Alerts**: Configure KQL queries and alerts based on streaming data
4. **Scale Configuration**: Adjust EventStream throughput based on data volume requirements

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

### Capacity Planning and Performance Optimization

- [Microsoft Fabric Capacity SKUs](https://learn.microsoft.com/fabric/enterprise/licenses#capacity) - Complete F2-F2048 SKU specifications with capacity units and performance characteristics
- [Plan Your Capacity Size](https://learn.microsoft.com/fabric/enterprise/plan-capacity) - Capacity sizing guidelines, consumption calculations, and throughput planning
- [Scale Your Capacity](https://learn.microsoft.com/fabric/enterprise/scale-capacity) - Dynamic scaling operations, considerations, and best practices

### API Templates and Implementation Examples

- [Microsoft Fabric EventStreams GitHub Repository](https://github.com/microsoft/fabric-event-streams) - Official API templates, sample implementations, and best practices
- [EventStream Definition Template](https://github.com/microsoft/fabric-event-streams/blob/main/API%20Templates/eventstream-definition.json) - Complete JSON template with all source types, destinations, operators, and configuration examples
- [EventStream GitHub Integration](https://learn.microsoft.com/fabric/real-time-intelligence/git-eventstream) - DevOps integration patterns, source control, and CI/CD pipeline configuration

### Azure IoT Operations Integration

- [AIO Dataflow Configuration - Fabric RTI](https://learn.microsoft.com/azure/iot-operations/connect-to-cloud/howto-configure-fabric-real-time-intelligence) - Dataflow endpoint configuration for Microsoft Fabric Real-Time Intelligence

### Terraform Provider and Infrastructure Automation

- [Terraform Provider for Microsoft Fabric](https://registry.terraform.io/providers/microsoft/fabric/latest/docs) - Microsoft Fabric Terraform Provider documentation and guides
