---
title: Prerequisites for Operational Performance Monitoring Scenario
description: Complete hardware, software, permissions, and configuration requirements needed to successfully implement the Operational Performance Monitoring scenario using the Edge AI Accelerator.
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: hub-page
estimated_reading_time: 8
keywords:
  - operational-performance-monitoring
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

This document outlines all prerequisites needed to successfully implement the Operational Performance Monitoring scenario using the Edge AI Accelerator. These requirements ensure you have the necessary hardware, software, permissions, and configurations in place before deployment.

## Platform Capabilities Required

This scenario requires the following platform capabilities from the [Edge AI Platform capability groups][edge-ai-platform-capability-groups]:

### Core Monitoring Capabilities (Mandatory)

- **[Cloud Observability Foundation][cloud-observability-foundation]** - Essential for centralized monitoring and alerting
- **[Edge Data Stream Processing][edge-data-stream-processing]** - For real-time operational data processing
- **[OPC UA Data Ingestion][opc-ua-data-ingestion]** - For collecting equipment performance data

### Edge Platform Capabilities (Mandatory)

- **[Edge Compute Orchestration Platform][edge-compute-orchestration-platform]** - For managing edge workloads
- **[Device Twin Management][device-twin-management]** - For equipment representation and state management
- **[Edge Dashboard Visualization][edge-dashboard-visualization]** - For local operational dashboards

### Cloud Data Platform Capabilities (Mandatory)

- **[Cloud Data Platform Services][cloud-data-platform-services]** - For storing and analyzing operational metrics
- **[Specialized Time Series Data Services][specialized-time-series-data-services]** - For time-series operational data storage

### Integration Capabilities (Recommended)

- **[Broad Industrial Protocol Support][broad-industrial-protocol-support]** - For connecting diverse equipment types
- **[Cloud Messaging Event Infrastructure][cloud-messaging-event-infrastructure]** - For event-driven monitoring workflows

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
  - [User-assigned Managed Identities][user-assigned-managed-identities]
  - [Azure Key Vault][azure-key-vault] with access policies
  - [Role assignments][role-assignments] to resources
- Identity options for [Azure Arc onboarding][azure-arc-onboarding]:
  - User-assigned Managed Identity (recommended)
  - Service Principal with appropriate roles

For identity requirements implementation, see [security-identity module][security-identity-module].

### Resource Group Requirements

- Ability to create new resource groups or use existing ones
- If using existing resource groups, Contributor permissions to those groups

## Hardware Requirements

### Edge Compute Requirements

- VM-based deployment: [Azure VM Size Standard_D8s_v3][azure-vm-size-standard_d8s_v3] (recommended)
- Physical deployment: Hardware meeting these minimum requirements:
  - CPU: 4 cores (minimum), 8+ cores (recommended)
  - RAM: 8GB (minimum), 16GB+ (recommended)
  - Disk: 100GB SSD storage (minimum)
  - Network: 1Gbps Ethernet adapter
- For enterprise-wide monitoring, consider multiple edge devices distributed across facilities

For VM configuration details, see the [VM-Host module][vm-host-module] and [CNCF Cluster module][cncf-cluster-module].

### Performance Monitoring Equipment

- Operational equipment with monitoring interfaces:
  - OEE monitoring systems
  - Production rate sensors
  - Downtime tracking systems
  - Energy consumption meters
  - Quality inspection stations
- [OPC UA][opc-ua] compatibility or other supported industrial protocols
- Physical connectivity between equipment and edge devices

For OPC UA integration, see the [IoT Operations module][iot-operations-module].

### Networking Requirements

- Outbound internet connectivity from edge device to Azure
  - Minimum 2Mbps bandwidth for basic telemetry
  - Higher bandwidth recommended for multi-equipment monitoring
  - Firewall rules allowing outbound connections on ports 443 (HTTPS)
- For OPC UA:
  - TCP port 4840 (OPC UA Discovery)
  - TCP port range 49152-65535 for OPC UA server endpoints
- Local network considerations:
  - Stable connectivity across all monitored equipment
  - Factory network isolation/segmentation (recommended)
  - Redundant connectivity for critical systems

## Software Requirements

### Development Environment

- [Azure CLI][azure-cli] (latest version)
- [Terraform][terraform] ≥ 1.9.8
- [Kubernetes CLI (kubectl)][kubernetes-cli-kubectl]
- [Git][git]
- [Visual Studio Code][visual-studio-code] (recommended)
  - [DevContainers extension][devcontainers-extension] if using the provided dev container

For development environment setup, see the [Getting Started Guide][getting-started-guide].

### Operating System Requirements

- For VMs: Ubuntu 22.04 LTS
- For development: Any OS supporting the development tools listed above

## Cloud Resource Requirements

### Required Azure Services

- [Azure Key Vault][azure-key-vault] (for secrets management) - deployed via [security-identity module][security-identity-module-1]
- [Azure Storage Account][azure-storage-account] (for data persistence) - deployed via [data module][data-module]
- [Event Grid][event-grid] or [Event Hub Namespace][event-hub-namespace] (for messaging) - deployed via [messaging module][messaging-module]
- [Log Analytics Workspace][log-analytics-workspace] (for monitoring) - deployed via [observability module][observability-module]
- [Azure Monitor][azure-monitor] (for metrics and dashboards) - deployed via [observability module][observability-module]

### Observability Infrastructure

- [Observability module][observability-module-2] components for:
  - Centralized logging and monitoring
  - Custom operational dashboards
  - Alert configuration
  - KPI visualization

### Data Platform Requirements

- [Time-series data storage][time-series-data-storage] for operational metrics - deployed via [data module][data-module]
- Data integration with existing production systems
- [Dashboard services][dashboard-services] for visualization across multiple stakeholders - deployed via [observability module][observability-module]

## Integration Requirements

### Enterprise System Integration

- Access to ERP, MES, or other enterprise systems
- Integration method (API, database, file-based)
- Authentication credentials for systems
- Data mapping for operational metrics

### Production Equipment Integration

- [OPC UA][opc-ua] server/client configuration
- Equipment tag mapping documentation
- [Device twin][device-twin] configuration for equipment representation

For device integration details, see the [IoT Operations module][iot-operations-module].

## Blueprint Selection

For Operational Performance Monitoring, we recommend using one of these blueprints:

1. **[Full Single-Node Cluster][full-single-node-cluster]** - For single-site operations
   - All components on single VM/device
   - Complete monitoring and messaging infrastructure

2. **[Full Multi-Node Cluster][full-multi-node-cluster]** - For enterprise-wide implementations
   - Distributed components across multiple nodes
   - Fault tolerance and higher performance
   - Appropriate for mission-critical operational monitoring

3. **[Only-Cloud Single-Node Cluster][only-cloud-single-node-cluster]** - For cloud-centric monitoring
   - Focus on cloud analytics with minimal edge components
   - Suitable when most processing happens in the cloud

For blueprint details, see the [Blueprints README][blueprints-readme].

## Deployment Validation Checklist

Before proceeding with deployment, verify that:

- [ ] Azure subscription has been provisioned with required permissions
- [ ] Resource providers are registered
- [ ] Edge hardware meets minimum specifications
- [ ] Operational equipment is accessible via supported protocols
- [ ] Network connectivity requirements are met (both cloud and local)
- [ ] Development environment is properly configured
- [ ] Integration endpoints for enterprise systems are accessible
- [ ] Key operational metrics and KPIs have been identified

## Common Troubleshooting

- **Azure resource provider registration failures**: Verify your account has sufficient permissions
- **Edge device connectivity issues**: Check network configuration and firewall settings
- **Equipment connectivity issues**: Verify protocol configuration and network access
- **Enterprise system integration issues**: Check credentials and API accessibility
- **Dashboard rendering problems**: Verify data sources are correctly configured
- **Terraform deployment errors**: Ensure Azure CLI is logged in with correct subscription selected

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
[azure-arc-onboarding]: https://learn.microsoft.com/azure/azure-arc/kubernetes/connect-cluster
[azure-cli]: https://docs.microsoft.com/cli/azure/install-azure-cli
[azure-key-vault]: https://learn.microsoft.com/azure/key-vault/general/overview
[azure-monitor]: https://learn.microsoft.com/azure/azure-monitor/overview
[azure-storage-account]: https://learn.microsoft.com/azure/storage/common/storage-account-overview
[azure-subscription]: https://learn.microsoft.com/azure/cost-management-billing/manage/create-subscription
[azure-vm-size-standard_d8s_v3]: https://learn.microsoft.com/azure/virtual-machines/dv3-dsv3-series#dsv3-series
[blueprints-readme]: /blueprints/README.md
[broad-industrial-protocol-support]: /docs/project-planning/capabilities/protocol-translation-device-management/broad-industrial-protocol-support.md
[cloud-data-platform-services]: /docs/project-planning/capabilities/cloud-data-platform/cloud-data-platform-services.md
[cloud-messaging-event-infrastructure]: /docs/project-planning/capabilities/cloud-communications-platform/cloud-messaging-event-infrastructure.md
[cloud-observability-foundation]: /docs/project-planning/capabilities/cloud-insights-platform/cloud-observability-foundation.md
[cncf-cluster-module]: /src/100-edge/100-cncf-cluster/terraform/README.md
[dashboard-services]: https://learn.microsoft.com/azure/azure-portal/azure-portal-dashboards
[data-module]: /src/000-cloud/030-data/terraform
[devcontainers-extension]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers
[device-twin]: https://learn.microsoft.com/azure/iot-operations/manage-devices/device-twin-concepts
[device-twin-management]: /docs/project-planning/capabilities/protocol-translation-device-management/device-twin-management.md
[edge-ai-platform-capability-groups]: /docs/project-planning/capabilities/
[edge-compute-orchestration-platform]: /docs/project-planning/capabilities/edge-cluster-platform/edge-compute-orchestration-platform.md
[edge-dashboard-visualization]: /docs/project-planning/capabilities/edge-industrial-application-platform/edge-dashboard-visualization.md
[edge-data-stream-processing]: /docs/project-planning/capabilities/edge-industrial-application-platform/edge-data-stream-processing.md
[event-grid]: https://learn.microsoft.com/azure/event-grid/overview
[event-hub-namespace]: https://learn.microsoft.com/azure/event-hubs/event-hubs-about
[full-multi-node-cluster]: /blueprints/full-multi-node-cluster
[full-single-node-cluster]: /blueprints/full-single-node-cluster
[getting-started-guide]: /docs/getting-started-simple.md
[git]: https://git-scm.com/downloads
[iot-operations-module]: /src/100-edge/110-iot-ops/terraform/README.md
[kubernetes-cli-kubectl]: https://kubernetes.io/docs/tasks/tools/
[log-analytics-workspace]: https://learn.microsoft.com/azure/azure-monitor/logs/log-analytics-workspace-overview
[messaging-module]: /src/000-cloud/040-messaging/terraform
[observability-module]: /src/000-cloud/020-observability/terraform
[observability-module-2]: /src/000-cloud/020-observability/terraform/README.md
[only-cloud-single-node-cluster]: /blueprints/only-cloud-single-node-cluster
[opc-ua]: https://learn.microsoft.com/azure/industrial-iot/overview-what-is-opc-ua
[opc-ua-data-ingestion]: /docs/project-planning/capabilities/protocol-translation-device-management/opc-ua-data-ingestion.md
[provider-registration-script]: /src/azure-resource-providers/register-azure-providers.sh
[resource-groups]: https://learn.microsoft.com/azure/azure-resource-manager/management/manage-resource-groups-portal
[resource-providers]: https://learn.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types
[role-assignments]: https://learn.microsoft.com/azure/role-based-access-control/overview
[security-identity-module]: /src/000-cloud/010-security-identity/terraform/README.md
[security-identity-module-1]: /src/000-cloud/010-security-identity/terraform/modules/key-vault
[specialized-time-series-data-services]: /docs/project-planning/capabilities/cloud-data-platform/specialized-time-series-data-services.md
[terraform]: https://www.terraform.io/downloads.html
[time-series-data-storage]: https://learn.microsoft.com/azure/time-series-insights/overview-what-is-tsi
[user-assigned-managed-identities]: https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview
[visual-studio-code]: https://code.visualstudio.com/
[vm-host-module]: /src/000-cloud/050-vm-host/terraform/README.md
