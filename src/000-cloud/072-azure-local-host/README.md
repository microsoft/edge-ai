# Azure Local Host (053)

Deploys an Arc-enabled Kubernetes cluster on Azure Stack HCI using Azure Arc `Microsoft.Kubernetes/connectedClusters` and `Microsoft.HybridContainerService/provisionedClusterInstances` resources.

This component creates a Kubernetes cluster hosted on Azure Stack HCI (Azure Local) infrastructure through a Custom Location. It provisions:

- **Arc Connected Cluster** - Arc-enabled Kubernetes cluster with Azure RBAC, OIDC issuer, and workload identity
- **Provisioned Cluster Instance** - Kubernetes cluster with configurable control plane and node pools
- **Additional Node Pools** - Support for multiple worker node pools with different VM sizes
- **SSH Key Management** - Auto-generated or user-provided SSH keys for Linux nodes
- **Network Configuration** - Configurable pod CIDR, load balancers, and integration with logical networks
- **Storage Drivers** - Optional SMB and NFS CSI drivers for persistent storage

The cluster is deployed using  and  resource types via the AzAPI provider.

> NOTE: Framework-specific README in `terraform/README.md` is generated and must not be edited manually.
