---
title: Arc Extensions
description: Component to deploy foundational Arc-enabled Kubernetes cluster extensions including cert-manager and Azure Container Storage (ACSA) required by Azure IoT Operations and other Arc-enabled services
author: Edge AI Team
ms.date: 2025-12-30
ms.topic: reference
keywords:
  - arc extensions
  - cert-manager
  - azure container storage
  - acsa
  - edge volumes
  - kubernetes extensions
  - terraform
  - bicep
estimated_reading_time: 5
---

## Arc Extensions

Component to deploy foundational Arc-enabled Kubernetes cluster extensions including cert-manager and Azure Container Storage (ACSA). These extensions provide certificate management and persistent storage capabilities required by Azure IoT Operations and other Arc-enabled services.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

## Extensions Deployed

This component deploys two critical Arc extensions in the correct dependency order:

### cert-manager (microsoft.certmanagement)

Certificate management extension that provides automated certificate lifecycle management using cert-manager and trust-manager. This extension is a foundational dependency required by:

- Azure Container Storage (ACSA)
- Azure IoT Operations Secret Store
- Any workload requiring automated TLS certificate management

**Key Features:**

- Automated certificate issuance and renewal
- Trust bundle management via trust-manager
- Integration with various certificate issuers
- Deployed to `cert-manager` namespace

### Azure Container Storage (ACSA) (microsoft.arc.containerstorage)

Provides persistent storage capabilities for Arc-enabled Kubernetes clusters with support for:

- **Edge Volumes**: Local persistent storage on edge devices
- **Cloud Ingest**: Seamless data upload from edge to Azure Blob Storage
- **Fault-Tolerant Storage Pools**: High-availability storage configurations for multi-node clusters

**Use Cases:**

- Persistent data storage for IoT Operations workloads
- Media capture and buffering for media connector
- Local caching and data retention at the edge
- Automated cloud upload for analytics and archival

## Dependencies

**Requires:**

- Arc-connected Kubernetes cluster (from 100-cncf-cluster component)
- Sufficient disk space on cluster nodes for storage volumes

**Required by:**

- 110-iot-ops component (requires cert-manager extension for Secret Store deployment)
- Media connector and other services using ACSA for persistent storage

**Internal Dependencies:**

- Azure Container Storage extension depends on cert-manager extension (enforced via `depends_on`)

## Deployment Order

This component must be deployed:

1. **After**: 100-cncf-cluster (Arc-connected cluster must exist)
2. **Before**: 110-iot-ops (provides required cert-manager dependency)

**Internal Extension Order:**

1. cert-manager extension (foundational)
2. Azure Container Storage extension (depends on cert-manager)

## Extension Configuration

Both extensions support flexible configuration options:

### Common Configuration

- **Version and release train**: Configure specific extension versions and stability channels
- **Conditional deployment**: Enable/disable each extension independently via `enabled` flag
- **Extension-specific settings**: Customize behavior per extension requirements

### cert-manager Configuration

Configure certificate management behavior:

- **Agent operation timeout**: Timeout for extension operations (default: 20 minutes)
- **Global telemetry**: Enable/disable telemetry collection (default: enabled)
- **Release train**: Stable, preview, or custom channels (default: stable)
- **Version**: Specific extension version (default: 0.7.0)

### Container Storage Configuration

Configure storage capabilities:

- **Disk storage class**: Kubernetes storage class for persistent volumes (default: auto-detected)
- **Fault tolerance mode**: Enable fault-tolerant storage pools for multi-node clusters (default: disabled)
- **Disk mount point**: Host path for storage pool data (default: /mnt)
- **Release train**: Stable, preview, or custom channels (default: stable)
- **Version**: Specific extension version (default: 2.6.0)

**Note**: Fault tolerance requires multi-node clusters and consumes additional disk space for replication.

## Terraform

Refer to [Terraform Components - Getting Started](../README.md#terraform-components---getting-started) for deployment instructions.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

### Example Configuration

Add the following to your `terraform.tfvars` file:

```hcl
# Enable both extensions with default settings
arc_extensions = {
  cert_manager_extension = {
    enabled                            = true
    version                            = "0.7.0"
    train                              = "stable"
    agent_operation_timeout_in_minutes = 20
    global_telemetry_enabled           = true
  }

  container_storage_extension = {
    enabled                 = true
    version                 = "2.6.0"
    train                   = "stable"
    disk_storage_class      = ""  # Auto-detect
    fault_tolerance_enabled = false
    disk_mount_point        = "/mnt"
  }
}
```

### Disable Specific Extensions

To deploy only cert-manager without ACSA:

```hcl
arc_extensions = {
  cert_manager_extension = {
    enabled                            = true
    version                            = "0.7.0"
    train                              = "stable"
    agent_operation_timeout_in_minutes = 20
    global_telemetry_enabled           = true
  }

  container_storage_extension = {
    enabled                 = false
    version                 = "2.6.0"
    train                   = "stable"
    disk_storage_class      = ""
    fault_tolerance_enabled = false
    disk_mount_point        = "/mnt"
  }
}
```

## Bicep

Learn more about the required configuration by reading the [./bicep/README.md](./bicep/README.md)

## Troubleshooting

### Extension Installation Issues

Check extension status using Azure CLI:

```sh
# List all extensions on the cluster
az k8s-extension list \
  --cluster-name <cluster-name> \
  --resource-group <resource-group> \
  --cluster-type connectedClusters

# Check specific extension status
az k8s-extension show \
  --name certmanager \
  --cluster-name <cluster-name> \
  --resource-group <resource-group> \
  --cluster-type connectedClusters
```

### cert-manager Issues

Verify cert-manager pods are running:

```sh
kubectl get pods -n cert-manager
```

Check cert-manager logs:

```sh
kubectl logs -n cert-manager -l app=cert-manager
kubectl logs -n cert-manager -l app=webhook
kubectl logs -n cert-manager -l app=cainjector
```

### Azure Container Storage Issues

Verify ACSA pods are running:

```sh
kubectl get pods -n azure-arc-containerstorage
```

Check storage pool status:

```sh
kubectl get storagepools -A
```

View ACSA logs:

```sh
kubectl logs -n azure-arc-containerstorage -l app=azure-arc-containerstorage
```

### Common Issues

**Extension installation timeout**:

- Increase `agent_operation_timeout_in_minutes` for cert-manager
- Verify cluster has internet connectivity to download extension components

**ACSA fails to create storage pool**:

- Verify sufficient disk space at configured `disk_mount_point`
- Check node has required kernel modules loaded
- For fault tolerance, verify cluster has multiple nodes

**cert-manager webhook errors**:

- Verify cluster DNS is functioning correctly
- Check webhook service and endpoints are created

## References

- [Azure Arc Extensions Overview](https://learn.microsoft.com/azure/azure-arc/kubernetes/extensions)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Azure Container Storage for Arc](https://learn.microsoft.com/azure/azure-arc/container-storage/)
- [Install Edge Volumes](https://learn.microsoft.com/azure/azure-arc/container-storage/howto-install-edge-volumes?tabs=single)
- [Configure Cloud Ingest](https://learn.microsoft.com/azure/azure-arc/container-storage/howto-configure-cloud-ingest-subvolumes?tabs=portal)
- [Multi-Node Storage Configuration](https://learn.microsoft.com/azure/iot-operations/deploy-iot-ops/howto-prepare-cluster?tabs=ubuntu#configure-multi-node-clusters-for-azure-container-storage-enabled-by-azure-arc)
- [Media Connector with ACSA](https://learn.microsoft.com/azure/iot-operations/discover-manage-assets/howto-use-media-connector?tabs=portal#deploy-the-media-connector)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
