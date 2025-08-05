---
title: Fabric Blueprint
description: Microsoft Fabric components for data analytics and optionally real-time intelligence (RTI) scenarios
author: Edge AI Team
ms.date: 07/29/2025
ms.topic: reference
estimated_reading_time: 7
keywords:
  - microsoft fabric
  - blueprint
  - data analytics
  - real-time intelligence
  - eventstream
  - eventhouse
  - lakehouse
  - terraform
---

This blueprint deploys Microsoft Fabric components for data analytics and optionally real-time intelligence (RTI) scenarios.

## Overview

This blueprint creates Microsoft Fabric resources including:

- Fabric workspace (optional)
- Fabric capacity (optional)
- Fabric lakehouse for data analytics
- Fabric EventStream for data ingestion
- Fabric Eventhouse for real-time intelligence (RTI scenarios)

## Architecture

### Traditional Analytics (Default)

- EventStream with Event Hub source
- Data flows to Fabric Lakehouse
- Batch analytics and data science workflows

### Real-Time Intelligence (RTI)

For RTI scenarios, the blueprint supports:

- EventStream with custom endpoint source
- Data flows to Fabric Eventhouse
- Real-time analytics and streaming scenarios
- Integration with Azure IoT Operations via custom endpoints

## Prerequisites

- Azure subscription with appropriate permissions
- Microsoft Fabric capacity (optional - can use free tier)
- Terraform >= 1.9.8
- Azure CLI authenticated

## Usage

### Basic Fabric Workspace

```hcl
module "fabric_blueprint" {
  source = "./blueprints/fabric/terraform"

  environment                    = "dev"
  location                      = "eastus2"
  resource_prefix               = "mycompany"
  instance                      = "001"

  should_create_fabric_workspace = true
  should_create_fabric_lakehouse = true
}
```

### With EventStream

```hcl
module "fabric_blueprint" {
  source = "./blueprints/fabric/terraform"

  environment                    = "dev"
  location                      = "eastus2"
  resource_prefix               = "mycompany"
  instance                      = "001"

  should_create_fabric_workspace   = true
  should_create_fabric_lakehouse   = true
  should_create_fabric_eventstream = true
  eventhub_endpoint               = "your-eventhub-endpoint"
}
```

### RTI Scenarios

For Real-Time Intelligence scenarios with custom endpoints:

```hcl
module "fabric_blueprint" {
  source = "./blueprints/fabric/terraform"

  environment                     = "dev"
  location                       = "eastus2"
  resource_prefix                = "mycompany"
  instance                       = "001"

  should_create_fabric_workspace   = true
  should_create_fabric_eventhouse  = true
  should_create_fabric_eventstream = true
  eventstream_template_type       = "custom-endpoint"
}
```

**Note**: Full RTI support requires enhanced Fabric component implementation.
For complete RTI integration with Azure IoT Operations, use the `fabric-rti` blueprint instead.

## Variables

### Required Variables

| Name              | Description                                       | Type     |
|-------------------|---------------------------------------------------|----------|
| `environment`     | Environment for all resources: dev, test, or prod | `string` |
| `location`        | Azure region for all resources                    | `string` |
| `resource_prefix` | Prefix for all resource names                     | `string` |

### Optional Variables

| Name                               | Description                                            | Type     | Default       |
|------------------------------------|--------------------------------------------------------|----------|---------------|
| `instance`                         | Instance identifier for naming resources               | `string` | `"001"`       |
| `capacity_id`                      | Fabric capacity ID (optional for free tier)            | `string` | `null`        |
| `should_create_fabric_capacity`    | Whether to create new Fabric capacity                  | `bool`   | `false`       |
| `should_create_fabric_workspace`   | Whether to create new Fabric workspace                 | `bool`   | `false`       |
| `should_create_fabric_lakehouse`   | Whether to create Fabric lakehouse                     | `bool`   | `false`       |
| `should_create_fabric_eventstream` | Whether to create Fabric EventStream                   | `bool`   | `false`       |
| `should_create_fabric_eventhouse`  | Whether to create Fabric Eventhouse for RTI            | `bool`   | `false`       |
| `eventstream_template_type`        | EventStream template: 'event-hub' or 'custom-endpoint' | `string` | `"event-hub"` |
| `eventhub_endpoint`                | Event Hub endpoint for traditional scenarios           | `string` | `null`        |

## Outputs

The blueprint outputs depend on the enabled features and may include:

- Fabric workspace details
- Fabric lakehouse information
- Fabric EventStream configuration
- Fabric Eventhouse details (RTI scenarios)
- Connection information for integration

## RTI Integration

For full Real-Time Intelligence integration with Azure IoT Operations:

1. **Use the dedicated RTI blueprint**: `blueprints/fabric-rti/terraform`
2. **Or configure this blueprint for RTI**:
   - Set `eventstream_template_type = "custom-endpoint"`
   - Enable `should_create_fabric_eventhouse = true`
   - Disable `should_create_fabric_lakehouse = false`

The RTI blueprint provides a complete end-to-end solution with Azure IoT Operations integration.

## Deployment

1. **Initialize Terraform**:

   ```bash
   terraform init
   ```

2. **Plan Deployment**:

   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```

3. **Apply Configuration**:

   ```bash
   terraform apply -var-file="terraform.tfvars"
   ```

## Cleanup

To destroy all resources:

```bash
terraform destroy -var-file="terraform.tfvars"
```

## Related Blueprints

- **fabric-rti**: Complete RTI integration with Azure IoT Operations
- **full-single-node-cluster**: Complete AIO deployment
- **only-cloud-single-node-cluster**: Cloud-only AIO resources

## External References

### Capacity Planning and Performance Optimization

- [Microsoft Fabric Capacity SKUs](https://learn.microsoft.com/fabric/enterprise/licenses#capacity) - Complete F2-F2048 SKU specifications with capacity units and performance characteristics
- [Plan Your Capacity Size](https://learn.microsoft.com/fabric/enterprise/plan-capacity) - Capacity sizing guidelines, consumption calculations, and throughput planning
- [Scale Your Capacity](https://learn.microsoft.com/fabric/enterprise/scale-capacity) - Dynamic scaling operations, considerations, and best practices

### Terraform Provider and Infrastructure Automation

- [Terraform Provider for Microsoft Fabric](https://registry.terraform.io/providers/microsoft/fabric/latest/docs) - Microsoft Fabric Terraform Provider documentation and guides
