# Network Topology Diagram

This diagram shows the detailed network architecture, including VLANs, IP addressing, security configurations, and connectivity between edge and cloud environments.

## Network Overview

The solution spans two main network environments connected via Azure Arc:

1. **Azure Virtual Network (Cloud)**
2. **Edge Factory Network (On-Premises)**

## Azure Virtual Network

### VNet Configuration

- **Name**: `vnet-media-capture`
- **Address Space**: `10.0.0.0/16`
- **Region**: East US 2
- **DNS**: Azure-provided DNS

### Subnet: Default Subnet

- **Address Range**: `10.0.0.0/24`
- **Available IPs**: 251 (Azure reserves 5)
- **Resources**:
  - Azure Functions (Video Query API)
  - Storage Account private endpoints
  - Azure Monitor endpoints

### Network Security Group (NSG)

- **Inbound Rules**:
  - Allow HTTPS (443) from Internet → Azure Functions
  - Allow Storage (443) from Functions → Storage Account
  - Deny all other inbound traffic
- **Outbound Rules**:
  - Allow HTTPS (443) to Storage Account
  - Allow HTTPS (443) to Azure Monitor
  - Allow outbound to Internet (for dependencies)

### Private Endpoints

- **Storage Account**: `mediastore123.blob.core.windows.net`
  - Private IP: `10.0.0.10`
  - Eliminates public internet exposure
  - Faster data transfer within VNet

## Edge Factory Network

### Network Configuration

- **Address Space**: `192.168.100.0/22` (1024 IPs)
- **Gateway**: `192.168.100.1`
- **DNS**: `192.168.100.2`
- **Internet Access**: Firewall with outbound rules

### VLAN 100: Management Network

- **Subnet**: `192.168.100.0/24`
- **Purpose**: Infrastructure management and administration
- **Resources**:
  - Network switches
  - Management interfaces
  - Monitoring systems

### VLAN 200: Camera Network

- **Subnet**: `192.168.101.0/24`
- **Purpose**: ONVIF camera traffic isolation
- **Resources**:
  - **Camera-01**: `192.168.101.10`
    - RTSP Port: 554
    - ONVIF Port: 80
  - **Camera-02**: `192.168.101.11`
    - RTSP Port: 554
    - ONVIF Port: 80
  - **Camera-N**: `192.168.101.x`

**Security**:

- Isolated from other VLANs
- Cameras cannot initiate outbound connections
- Only K3s cluster can access cameras

### VLAN 300: Kubernetes Cluster

- **Subnet**: `192.168.102.0/24`
- **Purpose**: K3s cluster nodes and services
- **Resources**:
  - **Control Plane Node**: `192.168.102.10`
    - Kubernetes API: 6443
    - etcd: 2379-2380
  - **Worker Node 1**: `192.168.102.11`
  - **Worker Node 2**: `192.168.102.12`
  - **LoadBalancer IP Range**: `192.168.102.100-192.168.102.200`

**Services**:

- **Azure IoT Operations MQTT Broker**: `192.168.102.100:1883`
- **Media Capture Service**: `192.168.102.101:8080`

**Security**:

- Can access VLAN 200 (cameras)
- Can access VLAN 400 (storage)
- Firewall rules for Azure Arc connectivity

### VLAN 400: Storage Network

- **Subnet**: `192.168.103.0/24`
- **Purpose**: High-performance storage access
- **Resources**:
  - **NFS Server** (optional local cache): `192.168.103.10`
  - **ACSA PersistentVolume mount path**: Maps to Azure Blob Storage

**Note**: ACSA volume appears as local storage to applications but automatically syncs to cloud

## Port Usage

### Edge to Cloud Communication

| Source      | Destination          | Port | Protocol | Purpose                   |
|-------------|----------------------|------|----------|---------------------------|
| K3s Cluster | Azure Arc            | 443  | HTTPS    | Arc agent communication   |
| K3s Cluster | Azure IoT Operations | 443  | HTTPS    | IoT Operations management |
| K3s Cluster | Blob Storage         | 443  | HTTPS    | ACSA sync                 |
| K3s Cluster | Azure Monitor        | 443  | HTTPS    | Telemetry and logs        |

### Within Edge Network

| Source        | Destination | Port    | Protocol | Purpose                 |
|---------------|-------------|---------|----------|-------------------------|
| Media Capture | Cameras     | 554     | RTSP     | Video streaming         |
| Media Capture | Cameras     | 80      | HTTP     | ONVIF device management |
| Applications  | MQTT Broker | 1883    | MQTT     | Message pub/sub         |
| Media Capture | ACSA Volume | NFS/SMB | File     | Video segment writes    |

## Firewall Configuration

### Outbound Rules (Edge → Internet)

1. **Azure Arc Services**:
   - *.servicebus.windows.net:443
   - *.guestconfiguration.azure.com:443
   - *.azure-automation.net:443

2. **Azure IoT Operations**:
   - *.azure-devices.net:443
   - *.eventgrid.azure.net:443

3. **Azure Storage**:
   - *.blob.core.windows.net:443

4. **Container Registry**:
   - mcr.microsoft.com:443
   - *.docker.io:443

### Inbound Rules (Internet → Edge)

- **Block all inbound** (edge initiates all connections)
- Management access via VPN or Azure Bastion only

## Security Architecture

### Network Segmentation

```text
Internet
    ↓ (Firewall)
Edge Factory Network
    ├── VLAN 100 (Management) - Isolated
    ├── VLAN 200 (Cameras) - Isolated, read-only for K3s
    ├── VLAN 300 (Kubernetes) - Hub, can access 200 & 400
    └── VLAN 400 (Storage) - Isolated, accessed by K3s
```

### Zero Trust Principles

1. **Least Privilege**: Each VLAN has minimal required access
2. **Micro-segmentation**: Cameras cannot communicate with each other
3. **Identity-Based Access**: Managed identities for Azure resources
4. **Encryption in Transit**: TLS 1.2+ for all cloud communication
5. **Private Connectivity**: Private endpoints eliminate public exposure

## High Availability Considerations

### Edge Network HA

- **Redundant Switches**: Active/standby configuration
- **Multiple Internet Links**: Primary fiber + backup LTE
- **K3s HA**: 3 control plane nodes with etcd quorum
- **Storage Redundancy**: Local NFS with RAID + ACSA cloud backup

### Cloud Network HA

- **Azure Functions**: Auto-scaling across availability zones
- **Storage Account**: Zone-redundant storage (ZRS)
- **Regional Failover**: Optional geo-redundant storage (GRS)

## Network Performance

### Bandwidth Requirements

| Component             | Bandwidth | Notes                  |
|-----------------------|-----------|------------------------|
| Single Camera (1080p) | 4 Mbps    | H.264 compressed       |
| 10 Cameras            | 40 Mbps   | Peak during day shift  |
| ACSA Upload           | 4-40 Mbps | Matches recording rate |
| Query Download        | 1-10 Mbps | Bursts during analysis |

### Latency Expectations

| Path                   | Typical Latency | Notes               |
|------------------------|-----------------|---------------------|
| Camera → Media Capture | < 10ms          | Local network       |
| MQTT Request/Response  | < 50ms          | Local broker        |
| ACSA → Blob Storage    | 20-100ms        | Internet latency    |
| REST API Query         | 500-2000ms      | Includes processing |

## Monitoring and Diagnostics

### Network Monitoring Tools

- **Azure Monitor Network Insights**: Cloud connectivity health
- **Prometheus/Grafana**: Kubernetes network metrics
- **SNMP**: Switch and camera monitoring
- **Azure Arc Diagnostics**: Arc connectivity status

### Key Metrics

- **ACSA Sync Lag**: Time between file creation and cloud availability
- **Camera Stream Health**: RTSP connection uptime per camera
- **MQTT Message Latency**: Pub/sub round-trip time
- **Blob Upload Success Rate**: Percentage of successful syncs
