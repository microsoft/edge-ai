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
  - eventhouse
  - lakehouse
  - terraform
---

This blueprint deploys Microsoft Fabric components for data analytics scenarios.

## Overview

This blueprint creates Microsoft Fabric resources including:

- Fabric workspace (optional)
- Fabric capacity (optional)
- Fabric lakehouse for data analytics
- Fabric Eventhouse for real-time intelligence (optional)

## Architecture

This blueprint provisions the foundational Microsoft Fabric infrastructure:

- **Fabric Capacity**: Compute resources for Fabric workloads (optional, can use existing or free tier)
- **Fabric Workspace**: Container for organizing Fabric items
- **Fabric Lakehouse**: Data lake and data warehouse for analytics workloads
- **Fabric Eventhouse**: Real-time analytics engine with KQL database (optional)

**For complete Real-Time Intelligence integration with Azure IoT Operations**, including EventStream with CustomEndpoint and dataflow configuration, use the **`fabric-rti` blueprint** instead.

## Prerequisites

- Azure subscription with appropriate permissions
- Microsoft Fabric capacity (optional - can use free tier)
- Terraform >= 1.9.8
- Azure CLI authenticated
- Existing resource group (default naming: `rg-{resource_prefix}-{environment}-{instance}`)

## Usage

### Basic Fabric Workspace with Lakehouse

```hcl
module "fabric_blueprint" {
  source = "./blueprints/fabric/terraform"

  environment     = "dev"
  location        = "eastus2"
  resource_prefix = "mycompany"
  instance        = "001"

  should_create_fabric_workspace = true
  should_create_fabric_lakehouse = true
}
```

### With Fabric Capacity

```hcl
module "fabric_blueprint" {
  source = "./blueprints/fabric/terraform"

  environment     = "dev"
  location        = "eastus2"
  resource_prefix = "mycompany"
  instance        = "001"

  should_create_fabric_capacity  = true
  should_create_fabric_workspace = true
  should_create_fabric_lakehouse = true

  fabric_capacity_admins_list = ["user-object-id-1", "user-object-id-2"]
}
```

### With Eventhouse for Real-Time Analytics (RTI)

```hcl
module "fabric_blueprint" {
  source = "./blueprints/fabric/terraform"

  environment     = "dev"
  location        = "eastus2"
  resource_prefix = "mycompany"
  instance        = "001"

  should_create_fabric_workspace   = true
  should_create_fabric_eventhouse  = true
}
```

**For Azure IoT Operations integration with EventStream and dataflow endpoints**, use the **`fabric-rti`** blueprint which provides complete Real-Time Intelligence integration.

## Variables

### Required Variables

| Name              | Description                                       | Type     |
|-------------------|---------------------------------------------------|----------|
| `environment`     | Environment for all resources: dev, test, or prod | `string` |
| `location`        | Azure region for all resources                    | `string` |
| `resource_prefix` | Prefix for all resource names                     | `string` |

### Optional Variables

| Name                               | Description                                                                                      | Type           | Default |
|------------------------------------|--------------------------------------------------------------------------------------------------|----------------|---------|------|
| `instance`                         | Instance identifier for naming resources                                                         | `string`       | `"001"` |
| `resource_group_name`              | Name of the resource group                                                                       | `string`       | `null`  |
| `fabric_workspace_name`            | The name of the Microsoft Fabric workspace                                                       | `string`       | `null`  |
| `fabric_capacity_admins_list`      | List of AAD object IDs for Fabric capacity administrators (if left empty, current user is used) | `list(string)` | `[]`    |
| `should_create_fabric_capacity`    | Whether to create a new Fabric capacity                                                          | `bool`         | `false` |
| `should_create_fabric_workspace`   | Whether to create a new Microsoft Fabric workspace                                               | `bool`         | `false` |
| `should_create_fabric_lakehouse`   | Whether to create a Microsoft Fabric lakehouse                                                   | `bool`         | `false` |
| `should_create_fabric_eventhouse`  | Whether to create a Microsoft Fabric Eventhouse for real-time intelligence scenarios             | `bool`         | `false` |

## Outputs

| Name                | Description                                 |
|---------------------|---------------------------------------------|
| `fabric_capacity`   | The Microsoft Fabric capacity details       |
| `fabric_eventhouse` | The Microsoft Fabric eventhouse details     |
| `fabric_lakehouse`  | The Microsoft Fabric lakehouse details      |
| `fabric_workspace`  | The Microsoft Fabric workspace details      |
| `resource_group`    | The resource group for the fabric resources |

## Real-Time Intelligence Integration

For Azure IoT Operations integration with EventStream, CustomEndpoint, and dataflow configuration:

**Use the `fabric-rti` blueprint**: `blueprints/fabric-rti/terraform`

The RTI blueprint provides:

- EventStream with CustomEndpoint source for AIO integration
- Dataflow endpoint configuration for secure data transmission
- Eventhouse with KQL database for real-time analytics
- Complete end-to-end solution on top of existing AIO infrastructure

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

- **fabric-rti**: Real-Time Intelligence integration with Azure IoT Operations (EventStream + dataflow)
- **full-single-node-cluster**: Complete AIO deployment with cloud and edge infrastructure
- **only-cloud-single-node-cluster**: Cloud-only AIO resources without edge components

## External References

### Capacity Planning and Performance Optimization

- [Microsoft Fabric Capacity SKUs](https://learn.microsoft.com/fabric/enterprise/licenses#capacity) - Complete F2-F2048 SKU specifications with capacity units and performance characteristics
- [Plan Your Capacity Size](https://learn.microsoft.com/fabric/enterprise/plan-capacity) - Capacity sizing guidelines, consumption calculations, and throughput planning
- [Scale Your Capacity](https://learn.microsoft.com/fabric/enterprise/scale-capacity) - Dynamic scaling operations, considerations, and best practices

### Terraform Provider and Infrastructure Automation

- [Terraform Provider for Microsoft Fabric](https://registry.terraform.io/providers/microsoft/fabric/latest/docs) - Microsoft Fabric Terraform Provider documentation and guides
