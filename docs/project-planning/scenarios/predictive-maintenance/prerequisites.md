---
title: Prerequisites for Predictive Maintenance Scenario
description: Complete hardware, software, permissions, and configuration requirements needed to successfully implement the Predictive Maintenance scenario using the Edge AI Accelerator.
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: hub-page
estimated_reading_time: 8
keywords:
  - predictive-maintenance
  - prerequisites
  - requirements
  - azure-subscription
  - hardware-requirements
  - permissions
  - overview
  - index
  - navigation
  - workspaces
  - edge
  - project
  - planning
  - scenarios
---

## Prerequisites Overview

This document outlines all prerequisites needed to successfully implement the Predictive Maintenance scenario using the Edge AI Accelerator. These requirements ensure you have the necessary hardware, software, permissions, and configurations in place before deployment.

## Platform Capabilities Required

This scenario requires the following platform capabilities from the [Edge AI Platform capability groups][edge-ai-platform-capability-groups]:

### Core Predictive Capabilities (Mandatory)

- **[Predictive Maintenance Intelligence][predictive-maintenance-intelligence]** - Essential for equipment failure prediction and maintenance optimization
- **[AI-Enhanced Digital Twin Engine][ai-enhanced-digital-twin-engine]** - For creating digital representations of equipment
- **[Cloud AI/ML Model Training Management][cloud-aiml-model-training-management]** - For training predictive models

### Edge Platform Capabilities (Mandatory)

- **[Edge Data Stream Processing][edge-data-stream-processing]** - For real-time sensor data processing
- **[Edge Inferencing Application Framework][edge-inferencing-application-framework]** - For running predictive models at the edge
- **[OPC UA Data Ingestion][opc-ua-data-ingestion]** - For collecting equipment sensor data

### Cloud Analytics Capabilities (Mandatory)

- **[Cloud Observability Foundation][cloud-observability-foundation]** - For monitoring system and equipment health
- **[Specialized Time Series Data Services][specialized-time-series-data-services]** - For storing historical equipment data

### Integration Capabilities (Recommended)

- **[Business Process Automation Engine][business-process-automation-engine]** - For automating maintenance workflows
- **[Enterprise Application Integration Hub][enterprise-application-integration-hub]** - For integration with CMMS/ERP systems

## Azure Requirements

### Subscription and Permissions

- [Azure subscription][azure-subscription] with Contributor or Owner access
- Permissions to register the following [resource providers][resource-providers]:
  - Microsoft.ExtendedLocation
  - Microsoft.Kubernetes
  - Microsoft.KubernetesConfiguration
  - Microsoft.IoTOperations
  - Microsoft.DeviceRegistry
  - Microsoft.SecretSyncController
  - Microsoft.AlertsManagement
  - Microsoft.Monitor
  - Microsoft.Dashboard
  - Microsoft.Insights
  - Microsoft.OperationalInsights
  - Microsoft.OperationsManagement

For detailed provider registration instructions, see the [provider registration script][provider-registration-script].

### Identity and Access Requirements

- Azure account with permissions to create:
  - [Resource Groups][resource-groups]
  - [User-assigned Managed Identities][managed-identities]
  - [Azure Key Vault][azure-key-vault] with access policies
  - [Role assignments][role-assignments] to resources

For identity requirements implementation, see [security-identity module][security-identity-module].

### Resource Group Requirements

- Ability to create new resource groups or use existing ones
- If using existing resource groups, Contributor permissions to those groups

## Hardware Requirements

### Edge Compute Requirements

- VM-based deployment: [Azure VM Size Standard_D8s_v3][azure-vm-standard-d8s-v3] (recommended)
- Physical deployment: Hardware meeting these minimum requirements:
  - CPU: 4 cores (minimum), 8+ cores (recommended)
  - RAM: 8GB (minimum), 16GB+ (recommended)
  - Disk: 100GB SSD storage (minimum)
  - Network: 1Gbps Ethernet adapter

For VM configuration details, see the [VM-Host module][vm-host-module].

### Sensor Requirements

- [OPC UA][opc-ua] compatible industrial sensors for equipment monitoring
- Connectivity between sensors and edge device
- For testing: [OPC UA Simulator][opc-ua-simulator] can be used in place of physical sensors

### Networking Requirements

- Outbound internet connectivity from edge device to Azure
  - Minimum 2Mbps bandwidth for basic telemetry
  - Firewall rules allowing outbound connections on ports 443 (HTTPS)
- For OPC UA:
  - TCP port 4840 (OPC UA Discovery)
  - TCP port range 49152-65535 for OPC UA server endpoints

## Software Requirements

### Development Environment

- [Azure CLI][azure-cli] (latest version)
- [Terraform][terraform] ≥ 1.9.8
- [Kubernetes CLI (kubectl)][kubectl]
- [Git][git]
- [Visual Studio Code][visual-studio-code] (recommended)
  - [DevContainers extension][devcontainers-extension] if using the provided dev container

For development environment setup, see the [Getting Started Guide][getting-started-guide].

### Operating System Requirements

- For VMs: Ubuntu 22.04 LTS
- For development: Any OS supporting the development tools listed above

## Cloud Resource Requirements

### Required Azure Services

- [Azure Key Vault][azure-key-vault] (for secrets management) - deployed via [security-identity module][security-identity-module]
- [Azure Storage Account][azure-storage-account] (for data persistence) - deployed via [data module][data-module]
- [Event Grid][event-grid] or [Event Hub Namespace][event-hub-namespace] (for messaging) - deployed via [messaging module][messaging-module]
- [Log Analytics Workspace][log-analytics-workspace] (for monitoring) - deployed via [observability module][observability-module]

### Optional Azure Services

- [Azure Data Explorer][azure-data-explorer] (for time series analytics)
- [Azure Machine Learning][azure-machine-learning] (for model training/retraining)
- [Azure Container Registry][azure-container-registry] (for custom container images) - deployed via [aks-acr module][aks-acr-module]

## Integration Requirements

### OPC UA Server Requirements

- [OPC UA][opc-ua] server software or compatible PLC/equipment
- Alternative: [OPC UA Simulator][opc-ua-simulator] deployed via the [IoT Operations module][iot-operations-module]
- Required OPC UA node/tag configuration for predictive maintenance data

For more information on OPC UA setup, see the [Azure IoT Operations OPC UA documentation][azure-iot-operations-opc-ua-documentation].

### External System Integration (Optional)

- REST API endpoints for CMMS/EAM systems
- Authentication credentials for these systems
- Data mapping documentation between systems

## Blueprint Selection

For Predictive Maintenance, we recommend using one of these blueprints:

1. **[Full Single-Node Cluster][full-single-node-cluster]** - For production environments with a single edge device
   - All components on single VM/device
   - Complete monitoring and messaging infrastructure

2. **[Full Multi-Node Cluster][full-multi-node-cluster]** - For high-availability production environments
   - Distributed components across multiple nodes
   - Fault tolerance and higher performance

3. **[Minimum Single-Node Cluster][minimum-single-node-cluster]** - For development/testing environments
   - Reduced resource requirements
   - Limited to core functionality

For blueprint details, see the [Blueprints README][blueprints-readme].

## Deployment Validation Checklist

Before proceeding with deployment, verify that:

- [ ] Azure subscription has been provisioned with required permissions
- [ ] Resource providers are registered
- [ ] Edge hardware meets minimum specifications
- [ ] Network connectivity requirements are met
- [ ] Development environment is properly configured
- [ ] OPC UA data sources are available (physical or simulated)
- [ ] Integration endpoints are accessible (if applicable)

## Common Troubleshooting

- **Azure resource provider registration failures**: Verify your account has sufficient permissions
- **Edge device connectivity issues**: Check network configuration and firewall settings
- **OPC UA connection failures**: Verify OPC UA server is running and ports are open
- **Terraform deployment errors**: Ensure Azure CLI is logged in with correct subscription selected

<!-- Reference Links -->
[ai-enhanced-digital-twin-engine]: /docs/project-planning/capabilities/advanced-simulation-digital-twin-platform/ai-enhanced-digital-twin-engine.md
[aks-acr-module]: /src/000-cloud/060-aks-acr/terraform
[azure-container-registry]: https://learn.microsoft.com/azure/container-registry/container-registry-intro
[azure-data-explorer]: https://learn.microsoft.com/azure/data-explorer/data-explorer-overview
[azure-iot-operations-opc-ua-documentation]: https://learn.microsoft.com/azure/iot-operations/connect-to-devices/howto-deploy-opc-ua-server
[azure-machine-learning]: https://learn.microsoft.com/azure/machine-learning/overview-what-is-azure-machine-learning
[business-process-automation-engine]: /docs/project-planning/capabilities/business-enablement-integration-platform/business-process-automation-engine.md
[cloud-aiml-model-training-management]: /docs/project-planning/capabilities/cloud-ai-platform/cloud-ai-ml-model-training-management.md
[cloud-observability-foundation]: /docs/project-planning/capabilities/cloud-insights-platform/cloud-observability-foundation.md
[edge-ai-platform-capability-groups]: /docs/project-planning/capabilities/
[edge-data-stream-processing]: /docs/project-planning/capabilities/edge-industrial-application-platform/edge-data-stream-processing.md
[edge-inferencing-application-framework]: /docs/project-planning/capabilities/edge-industrial-application-platform/edge-inferencing-application-framework.md
[enterprise-application-integration-hub]: /docs/project-planning/capabilities/business-enablement-integration-platform/enterprise-application-integration-hub.md
[event-grid]: https://learn.microsoft.com/azure/event-grid/overview
[event-hub-namespace]: https://learn.microsoft.com/azure/event-hubs/event-hubs-about
[full-multi-node-cluster]: /blueprints/full-multi-node-cluster
[full-single-node-cluster]: /blueprints/full-single-node-cluster
[iot-operations-module]: /src/100-edge/110-iot-ops
[log-analytics-workspace]: https://learn.microsoft.com/azure/azure-monitor/logs/log-analytics-workspace-overview
[messaging-module]: /src/000-cloud/040-messaging/terraform
[observability-module]: /src/000-cloud/020-observability/terraform
[opc-ua-data-ingestion]: /docs/project-planning/capabilities/protocol-translation-device-management/opc-ua-data-ingestion.md
[predictive-maintenance-intelligence]: /docs/project-planning/capabilities/advanced-simulation-digital-twin-platform/predictive-maintenance-intelligence.md
[specialized-time-series-data-services]: /docs/project-planning/capabilities/cloud-data-platform/specialized-time-series-data-services.md
[azure-subscription]: https://learn.microsoft.com/azure/cost-management-billing/manage/create-subscription
[resource-providers]: https://learn.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types
[provider-registration-script]: /src/azure-resource-providers/register-azure-providers.sh
[resource-groups]: https://learn.microsoft.com/azure/azure-resource-manager/management/manage-resource-groups-portal
[managed-identities]: https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview
[azure-key-vault]: https://learn.microsoft.com/azure/key-vault/general/overview
[role-assignments]: https://learn.microsoft.com/azure/role-based-access-control/overview
[security-identity-module]: /src/000-cloud/010-security-identity/terraform/README.md
[azure-vm-standard-d8s-v3]: https://learn.microsoft.com/azure/virtual-machines/dv3-dsv3-series#dsv3-series
[vm-host-module]: /src/000-cloud/050-vm-host/terraform/README.md
[opc-ua]: https://learn.microsoft.com/azure/industrial-iot/overview-what-is-opc-ua
[opc-ua-simulator]: /src/100-edge/110-iot-ops/terraform/modules/opc-ua-simulator
[azure-cli]: https://docs.microsoft.com/cli/azure/install-azure-cli
[terraform]: https://www.terraform.io/downloads.html
[kubectl]: https://kubernetes.io/docs/tasks/tools/
[git]: https://git-scm.com/downloads
[visual-studio-code]: https://code.visualstudio.com/
[devcontainers-extension]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers
[getting-started-guide]: /docs/getting-started-simple.md
[azure-storage-account]: https://learn.microsoft.com/azure/storage/common/storage-account-overview
[data-module]: /src/000-cloud/030-data/terraform
[minimum-single-node-cluster]: /blueprints/minimum-single-node-cluster
[blueprints-readme]: /blueprints/README.md

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
