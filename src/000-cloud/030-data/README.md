---
title: Cloud Data Persistence
description: Central data management foundation of the Edge AI Accelerator architecture, bridging edge computing with cloud-based analytics capabilities through Azure Storage and Microsoft Fabric integration
author: Edge AI Team
ms.date: 2025-06-07
ms.topic: reference
keywords:
  - cloud data persistence
  - azure storage
  - microsoft fabric
  - lakehouse
  - eventstream
  - data lake
  - edge ai accelerator
  - analytics
  - terraform
  - bicep
estimated_reading_time: 6
---

## Cloud Data Persistence

## Introduction

The Cloud Data Persistence component serves as the central data management foundation of the Edge AI Accelerator architecture, bridging edge computing with cloud-based analytics capabilities. This component implements a modern data architecture that collects, stores, and processes data generated from edge devices to enable advanced analytics and AI model training.

### Role in the Edge AI Accelerator

Within the accelerator, this component:

1. **Provides centralized data storage** for edge device telemetry, AI inference results, and operational data
2. **Creates a data pipeline** from edge to cloud by consuming events from the messaging system
3. **Enables advanced analytics** through Microsoft Fabric's analytics platform integration
4. **Supports the AI lifecycle** by storing data that can be used for model training and validation

### Integration Points

The Cloud Data Persistence component is a critical integration hub:

- **Edge devices**: Data generated at the edge flows through messaging to this component
- **050-Messaging component**: Consumes events from Event Grid topics for real-time data processing
- **AI model training**: Provides datasets for retraining models deployed to edge devices
- **Analytics and reporting**: Enables insights from combined edge and cloud data

### Data Flow Architecture

1. Edge devices generate data and AI inference results
2. Data is published to Event Grid topics by the messaging component
3. Fabric EventStream ingests events from Event Grid in real-time
4. Data is stored in:
   - Azure Storage (operational data, configurations, and raw telemetry)
   - Fabric Lakehouse (processed data ready for analytics)
5. Stored data is available for applications, analytics, and AI model retraining

## Component Resources

This component creates:

- **Azure Storage Accounts**: For general-purpose persistence of application data
- **Azure Storage Containers**: For organizing and storing blob data
- **Azure Storage File Shares**: For file-based sharing and access
- **Data Lake Gen2 Storage**: For hierarchical namespaces and big data workloads
- **Fabric Workspace**: A logical container for Fabric analytics assets
- **Fabric Lakehouse**: A modern data lake with data warehouse capabilities
- **Fabric EventStream**: A real-time data ingestion service connecting Event Grid to the Lakehouse

## Deployment

### Prerequisites

- Azure CLI installed and logged in
- Terraform installed
- jq installed (for script processing)

### Microsoft Fabric Integration Options

The component provides two options for Microsoft Fabric workspace integration:

#### Option 1: Create a New Workspace (Default)

Set `should_create_fabric_workspace = true` in your Terraform configuration to create a new Fabric workspace.

If you want to use a premium capacity with your new workspace, run the provided script:

```bash
cd scripts
chmod +x select-fabric-capacity.sh
./select-fabric-capacity.sh
```

#### Option 2: Use an Existing Workspace

To use an existing Microsoft Fabric workspace:

1. Set `should_create_fabric_workspace = false` in your Terraform configuration
2. Provide the existing workspace ID via `existing_fabric_workspace_id` variable

In both cases, the component will create:

- A Lakehouse in the specified workspace
- An EventStream connecting Event Grid to the Lakehouse (if an Event Grid endpoint is provided)

### Selecting a Microsoft Fabric Capacity (Optional)

If you want to use a premium capacity with Microsoft Fabric, run the provided script:

```bash
cd scripts
chmod +x select-fabric-capacity.sh
./select-fabric-capacity.sh
```

The script will:

1. List all available Fabric capacities for your account
2. Prompt you to select one
3. Save the selection for use by Terraform

If you don't have any capacities or choose not to use one, the deployment will use the Fabric free tier.

### Network Security Perimeter (Optional)

Set `should_use_network_security_perimeter = true` to place the Storage Account behind an `Enforced` Network Security Perimeter. Perimeter association is only available on the control-plane resource, so enabling this switches the Storage Account from the `azurerm_storage_account` resource to the `azapi_resource.storage_account` resource.

> **Warning — destructive migration on existing deployments.** Toggling `should_use_network_security_perimeter` from `false` to `true` (or back) on a Storage Account that already exists moves it between two different Terraform resource addresses (`azurerm_storage_account.storage_account` → `azapi_resource.storage_account`). Terraform plans this as **destroy-then-create**, which means data loss and a likely name collision. A `moved` block cannot bridge two different resource types.

To migrate an existing, populated Storage Account without data loss, re-point the Terraform state instead of applying the flag flip directly:

1. Review the plan and confirm the only intended change is the perimeter association — never approve a plan that destroys a populated account.
2. Remove the old address from state (does not touch the live resource):

   ```bash
   terraform state rm 'module.<data_module>.module.storage_account.azurerm_storage_account.storage_account[0]'
   ```

3. Import the same account under the new `azapi` address:

   ```bash
   terraform import 'module.<data_module>.module.storage_account.azapi_resource.storage_account[0]' \
     '/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<account-name>'
   ```

4. Run `terraform plan` again and confirm no destroy/create remains before applying.

For greenfield deployments (no existing account), enable the flag from the start and no migration is needed.

## Terraform

The terraform code can be found in the [terraform](terraform) folder.

### Modules

- **storage-account**: Creates Azure Storage Account with appropriate configuration
- **data-lake**: Provisions Data Lake Gen2 storage for big data workloads
- **fabric_workspace**: Creates a Microsoft Fabric workspace environment
- **fabric_lakehouse**: Creates a Fabric Lakehouse linked to the workspace
- **fabric_eventstream**: Creates a Fabric EventStream that connects Event Grid to the Lakehouse

## Additional Resources

### Microsoft Fabric

- [Microsoft Fabric Overview](https://learn.microsoft.com/fabric/get-started/microsoft-fabric-overview)
- [Fabric Documentation](https://learn.microsoft.com/fabric/)

### Event-Driven Architecture

- [Event-Driven Architecture in Azure](https://learn.microsoft.com/azure/architecture/guide/architecture-styles/event-driven)
- [Real-time Analytics with EventStream](https://learn.microsoft.com/fabric/real-time-analytics/event-streams/overview)

### Data Lake Solutions

- [Azure Data Lake Storage](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-introduction)
- [Introduction to Lakehouse in Microsoft Fabric](https://learn.microsoft.com/fabric/data-engineering/lakehouse-overview)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
