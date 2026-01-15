# Edge Infrastructure (100-edge)

Welcome to the Edge Infrastructure components section. This grouping contains all edge computing and IoT operations components that run on-premises or at the edge locations.

## Overview

The 100-edge components provide the edge computing infrastructure including CNCF cluster setup, Azure IoT Operations deployment, asset management, and edge-specific observability. These components are typically deployed by physical plant engineers and edge computing teams.

## Components

### Core Edge Platform

| Component                                        | Description                                                                    | Terraform | Bicep |
|--------------------------------------------------|--------------------------------------------------------------------------------|-----------|-------|
| [100-cncf-cluster](./100-cncf-cluster/README.md) | CNCF cluster setup with K3s, Azure Arc enablement, and workload identity       | ✅         | ✅     |
| [110-iot-ops](./110-iot-ops/README.md)           | Azure IoT Operations deployment with MQTT broker, trust management, and OPC UA | ✅         | ✅     |
| [111-assets](./111-assets/README.md)             | Asset management with asset types, instances, and custom Kubernetes manifests  | ✅         | ✅     |

### Edge Services

| Component                                          | Description                                                                  | Terraform | Bicep |
|----------------------------------------------------|------------------------------------------------------------------------------|-----------|-------|
| [120-observability](./120-observability/README.md) | Edge monitoring with Container Insights, Prometheus, and Grafana integration | ✅         | ✅     |
| [130-messaging](./130-messaging/README.md)         | Edge dataflows for Event Hub, Event Grid, and Fabric RTI destinations        | ✅         | ✅     |

### AI & Machine Learning

| Component                              | Description                                                                      | Terraform | Bicep |
|----------------------------------------|----------------------------------------------------------------------------------|-----------|-------|
| [140-azureml](./140-azureml/README.md) | Azure ML Arc extension for distributed training and secure inference at the edge | ✅         | ❌     |

## Architecture

The edge infrastructure follows a layered approach with integrated services:

```mermaid
flowchart TD
    %% Foundation
    K3s[100-cncf-cluster<br/>K3s Cluster<br/>Arc Enablement<br/>Workload Identity]

    %% Core Platform
    IoTOps[110-iot-ops<br/>Azure IoT Operations<br/>MQTT Broker<br/>OPC UA Simulator]

    %% Edge Services
    Assets[111-assets<br/>Asset Types<br/>Asset Instances<br/>Device Configuration]

    Observability[120-observability<br/>Container Insights<br/>Prometheus<br/>Grafana Integration]

    Messaging[130-messaging<br/>Edge Dataflows<br/>Event Hub & Grid<br/>Fabric RTI]

    %% AI & ML
    AzureML[140-azureml<br/>ML Arc Extension<br/>Distributed Training<br/>Secure Inference]

    %% Applications
    EdgeApps[Edge Applications<br/>AI Workloads<br/>Industrial Apps]

    CloudSync[Cloud Integration<br/>Telemetry & Analytics<br/>Hybrid Management]

    %% Main deployment flow
    K3s --> IoTOps
    IoTOps --> Assets
    IoTOps --> Observability
    IoTOps --> Messaging
    K3s --> AzureML

    %% Service to application flow
    Assets --> EdgeApps
    Observability --> EdgeApps
    Messaging --> EdgeApps
    AzureML --> EdgeApps

    %% Cloud integration
    EdgeApps --> CloudSync
    Observability --> CloudSync
    Messaging --> CloudSync
    AzureML --> CloudSync

    %% Cross-service relationships
    Assets -.-> Messaging
    Messaging -.-> Observability

    %% Clean styling matching docs/README.md
    style K3s fill:#e1f5fe,stroke:#01579b,stroke-width:3px
    style IoTOps fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    style Assets fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style Observability fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    style Messaging fill:#dbeafe,stroke:#1e40af,stroke-width:2px
    style AzureML fill:#fef3c7,stroke:#d97706,stroke-width:2px
    style EdgeApps fill:#e0f2fe,stroke:#0369a1,stroke-width:2px
    style CloudSync fill:#cffafe,stroke:#059669,stroke-width:2px
```

## Deployment Order

Components are numbered to indicate their deployment order and dependencies:

### Core Platform (100-119)

1. **100-cncf-cluster** - Deploy first to establish the Kubernetes foundation (skip if using existing Arc-enabled cluster)
2. **110-iot-ops** - Install Azure IoT Operations on any Arc-enabled cluster
3. **111-assets** - Configure asset management and device connectivity

### Edge Services (120-139)

1. **120-observability** - Set up edge-specific monitoring and logging
2. **130-messaging** - Configure edge dataflows for cloud destinations

### AI & Machine Learning (140-199)

1. **140-azureml** - Install Azure ML Arc extension for edge ML workloads (optional)

## Framework Support

Each component supports multiple Infrastructure as Code frameworks:

- **Terraform** - Complete Terraform modules with comprehensive configuration
- **Bicep** - Azure-native Bicep templates for streamlined deployment

## Key Features

### 🔄 **CNCF Compliance**

- Standards-compliant Kubernetes distribution (K3s)
- Arc-enabled cluster management
- Workload identity integration

### 🏭 **Industrial IoT**

- OPC UA server simulation and connectivity
- Asset discovery and management
- Real-time data processing

### 📊 **Edge Observability**

- Local monitoring and alerting
- Cloud synchronization
- Performance optimization

### 🔐 **Security**

- Certificate management
- Role-based access control
- Secure communication channels

## Prerequisites

- **Kubernetes Infrastructure**: Either:
  - Physical or virtual machines for new K3s deployment via 100-cncf-cluster
  - Existing Arc-enabled Kubernetes cluster (any CNCF-compliant distribution)
- Network connectivity to Azure (for Arc enablement)
- Appropriate hardware specifications for workloads
- Valid Azure subscription and permissions

## Getting Started

1. **Review Architecture**: Start with [blueprint examples](../../blueprints/README.md) to see complete deployment scenarios
2. **Choose Blueprint**: Select from [single-node](../../blueprints/full-single-node-cluster/README.md) or [multi-node](../../blueprints/full-multi-node-cluster/README.md) blueprints
3. **Prepare Infrastructure**: Either prepare hardware for new K3s deployment or ensure existing physical cluster is Arc-enabled
4. **Plan Network**: Configure network connectivity and security
5. **Deploy/Verify Foundation**: Deploy 100-cncf-cluster for new installations, or verify Arc enablement on existing clusters
6. **Add IoT Operations**: Deploy 110-iot-ops for industrial connectivity
7. **Configure Assets**: Set up 111-assets for device management
8. **Enable Monitoring**: Deploy 120-observability for edge monitoring

## Edge-Specific Considerations

- **Disconnected Scenarios**: Components designed to handle intermittent connectivity
- **Resource Constraints**: Optimized for edge hardware limitations
- **Local Processing**: Emphasis on local data processing and decision-making
- **Security**: Enhanced security for edge deployment environments

For more information about the overall source code structure, see the [main source documentation](../README.md).

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
