---
title: Azure Machine Learning Component
description: Azure Machine Learning workspace infrastructure with optional compute cluster for AI model training and deployment at the edge
author: Edge AI Team
ms.date: 2025-08-06
ms.topic: reference
keywords:
  - azure machine learning
  - ml workspace
  - compute cluster
  - ai model training
  - model deployment
  - edge ai
  - terraform
estimated_reading_time: 4
---

## Azure Machine Learning Component

This component creates Azure Machine Learning infrastructure for AI model training and deployment in edge AI scenarios. It provides a complete MLOps foundation with workspace, optional compute clusters, AKS cluster integration, and integration with existing cloud infrastructure.

## Purpose and Role

The Azure Machine Learning component enables data scientists and ML engineers to:

- **Model Development**: Create and train machine learning models in a managed workspace
- **Compute Resources**: Provision auto-scaling compute clusters for training workloads
- **AKS Integration**: Attach existing AKS clusters as compute targets for scalable ML training and inference
- **Model Registry**: Store and version trained models for deployment to edge devices
- **MLOps Integration**: Connect with existing security, storage, and networking infrastructure

## Component Resources

This component creates the following Azure resources:

### Core Infrastructure

- **Azure Machine Learning Workspace**: Central hub for ML operations with system-assigned managed identity
- **Compute Cluster** (Optional): Auto-scaling cluster for training and batch inference workloads
- **AKS Integration** (Optional): Extension deployment and cluster attachment for scalable ML workloads

### Integration Dependencies

This component integrates with existing cloud infrastructure:

- **Key Vault**: Secure storage of ML workspace secrets and configuration
- **Storage Account**: Default storage for ML artifacts, datasets, and model outputs
- **Application Insights**: Monitoring and logging for ML workspace operations
- **Container Registry** (Optional): Private container image storage for custom ML environments
- **Virtual Network** (Optional): Secure network integration for compute clusters
- **Kubernetes Cluster** (Optional): AKS cluster for scalable ML training and inference workloads

## Configuration Options

### Workspace Configuration

- **SKU Options**: Free, Basic, Standard, Premium tiers with different feature sets
- **Network Access**: Public or private endpoint configuration
- **Identity**: System-assigned managed identity for secure resource access

### Compute Cluster Configuration

- **Optional Deployment**: Compute cluster creation can be disabled for workspace-only scenarios
- **VM Configuration**: Configurable VM size (default: Standard_DS3_v2) and priority (default: Dedicated)
- **Auto-scaling**: Minimum/maximum node count with idle timeout (default: 0-1 nodes, 15-minute timeout)
- **Network Integration**: Optional subnet placement for secure network isolation

### AKS Integration Configuration

- **Optional Integration**: AKS cluster attachment can be enabled independently from compute clusters
- **Extension Deployment**: Azure ML extension deployment on AKS cluster for training and inference workloads
- **SSL Configuration**: Automatic certificate generation using Azure-managed domain labels
- **Cluster Purpose**: Configurable purpose (DevTest, DenseProd, FastProd) for performance optimization

## Deployment Scenarios

### Workspace-Only Deployment

Suitable for scenarios where compute resources are managed externally:

```hcl
should_create_compute_cluster = false
```

### Full ML Infrastructure

Complete setup with managed compute resources:

```hcl
should_create_compute_cluster    = true
compute_cluster_vm_size         = "Standard_DS3_v2"
compute_cluster_min_nodes       = 0
compute_cluster_max_nodes       = 4
compute_cluster_idle_duration   = "PT15M"
```

### AKS Integration Deployment

Integrate with existing AKS cluster for scalable ML workloads:

```hcl
should_integrate_aks_cluster          = true
should_enable_azureml_aks_training    = true
should_enable_azureml_aks_inference   = true
aks_cluster_purpose                   = "FastProd"
ssl_cname                             = "my-ml-service.example.com"
ssl_cert_pem                          = file("path/to/certificate.pem")
ssl_key_pem                           = file("path/to/private-key.pem")
```

#### SSL/TLS Configuration for Inference Endpoints

For production inference endpoints, provide your own SSL/TLS certificate and private key:

```hcl
ssl_cname    = "ml-inference.yourdomain.com"
ssl_cert_pem = file("path/to/certificate.pem")  # PEM-encoded certificate chain
ssl_key_pem  = file("path/to/private-key.pem") # PEM-encoded private key
```

For development and testing only, you can enable self-signed certificate generation:

```hcl
ssl_cname           = "ml-inference.example.com"
should_generate_ca  = true  # Development only - not for production
```

⚠️ **Breaking Change**: The `ssl_leaf_domain_label` variable has been removed. Use the new SSL/TLS variables above for certificate configuration.

## Integration with Other Components

This component depends on and integrates with:

- **000-resource-group**: Resource organization and management
- **010-security-identity**: Key Vault for secure secret storage
- **020-observability**: Application Insights for workspace monitoring
- **030-data**: Storage Account for ML artifacts and datasets
- **050-networking** (Optional): VNet integration for compute clusters
- **060-acr** (Optional): Container Registry for custom ML environments
- **070-kubernetes** (Optional): AKS cluster for ML training and inference workloads

## Variables

### Core Variables

| Variable          | Type     | Default | Description                     |
|-------------------|----------|---------|---------------------------------|
| `resource_prefix` | `string` | -       | Prefix for all resources        |
| `environment`     | `string` | -       | Environment: dev, test, or prod |
| `location`        | `string` | -       | Azure region for deployment     |
| `instance`        | `string` | "001"   | Instance identifier             |

### Dependency Variables

| Variable               | Type     | Description                                       |
|------------------------|----------|---------------------------------------------------|
| `resource_group`       | `object` | Resource group from 000-resource-group            |
| `application_insights` | `object` | Application Insights from 020-observability       |
| `key_vault`            | `object` | Key Vault from 010-security-identity              |
| `storage_account`      | `object` | Storage Account from 030-data                     |
| `acr`                  | `object` | Container Registry from 060-acr (optional)        |
| `subnet_id`            | `string` | Subnet ID from 050-networking (optional)          |
| `kubernetes`           | `object` | Kubernetes cluster from 070-kubernetes (optional) |

### Configuration Variables

| Variable                              | Type     | Default           | Description                                   |
|---------------------------------------|----------|-------------------|-----------------------------------------------|
| `workspace_sku`                       | `string` | "Basic"           | Workspace SKU: Free, Basic, Standard, Premium |
| `should_enable_public_network_access` | `bool`   | `true`            | Enable public network access to workspace     |
| `should_create_compute_cluster`       | `bool`   | `false`           | Create compute cluster for training workloads |
| `compute_cluster_vm_size`             | `string` | "Standard_DS3_v2" | VM size for compute cluster nodes             |
| `compute_cluster_vm_priority`         | `string` | "Dedicated"       | VM priority: Dedicated or LowPriority         |
| `compute_cluster_min_nodes`           | `number` | `0`               | Minimum number of cluster nodes               |
| `compute_cluster_max_nodes`           | `number` | `1`               | Maximum number of cluster nodes               |
| `compute_cluster_idle_duration`       | `string` | "PT15M"           | Idle time before scaling down nodes           |

### AKS Integration Variables

| Variable                                    | Type     | Default        | Description                                         |
|---------------------------------------------|----------|----------------|-----------------------------------------------------|
| `should_integrate_aks_cluster`              | `bool`   | `false`        | Enable AKS cluster integration for ML workloads     |
| `should_enable_azureml_aks_training`        | `bool`   | `true`         | Enable training workloads on AKS cluster            |
| `should_enable_azureml_aks_inference`       | `bool`   | `true`         | Enable inference workloads on AKS cluster           |
| `azureml_inference_router_service_type`     | `string` | "LoadBalancer" | Service type for inference router                   |
| `should_allow_azureml_insecure_connections` | `bool`   | `false`        | Allow HTTP connections (development only)           |
| `aks_cluster_purpose`                       | `string` | "FastProd"     | Cluster purpose: DevTest, DenseProd, FastProd       |
| `ssl_cname`                                 | `string` | `""`           | CNAME used for HTTPS endpoint                       |
| `ssl_cert_pem`                              | `string` | `""`           | PEM-encoded TLS certificate chain (sensitive)       |
| `ssl_key_pem`                               | `string` | `""`           | PEM-encoded private key (sensitive)                 |
| `should_generate_ca`                        | `bool`   | `false`        | Generate self-signed certificate (development only) |

## Outputs

### Workspace Outputs

| Output                   | Description                                   |
|--------------------------|-----------------------------------------------|
| `azureml_workspace`      | Complete workspace object with all properties |
| `workspace_id`           | Immutable workspace resource ID               |
| `workspace_name`         | Workspace name for reference                  |
| `workspace_principal_id` | System-assigned managed identity principal ID |

### Compute Cluster Outputs

| Output                         | Description                                          |
|--------------------------------|------------------------------------------------------|
| `compute_cluster`              | Complete cluster object (when created)               |
| `compute_cluster_id`           | Cluster resource ID (when created)                   |
| `compute_cluster_name`         | Cluster name (when created)                          |
| `compute_cluster_principal_id` | Cluster managed identity principal ID (when created) |

### AKS Integration Outputs

| Output                             | Description                                                   |
|------------------------------------|---------------------------------------------------------------|
| `azureml_extension`                | Azure ML extension resource for AKS integration               |
| `inference_cluster_compute_target` | Inference cluster compute target for AKS-Azure ML integration |

## Deployment Options

### Terraform

Refer to [Terraform Components - Getting Started](../README.md#terraform-components---getting-started) for deployment instructions.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

## Cost Optimization

The component includes several cost optimization features:

- **Free Tier Option**: Workspace can be deployed with Free SKU for development
- **Auto-scaling**: Compute clusters scale to zero when idle
- **Configurable Timeouts**: Short idle duration (15 minutes) minimizes compute costs
- **Optional Resources**: Compute cluster creation is optional for scenarios using external compute

## Security Considerations

- **Managed Identity**: System-assigned identity for secure resource access without credential management
- **Key Vault Integration**: Workspace secrets stored securely in Azure Key Vault
- **Network Isolation**: Optional VNet integration for compute clusters
- **RBAC**: Principle of least privilege access to dependent resources
- **Private Endpoints**: Support for private network access configuration

## External References

### Azure Machine Learning Platform Documentation

- [Azure Machine Learning Overview](https://learn.microsoft.com/azure/machine-learning/overview-what-is-azure-machine-learning) - Complete platform overview and machine learning capabilities
- [Create and Manage Machine Learning Workspaces](https://learn.microsoft.com/azure/machine-learning/how-to-manage-workspace) - Workspace creation, configuration, and management patterns
- [Azure Machine Learning Compute Clusters](https://learn.microsoft.com/azure/machine-learning/how-to-create-attach-compute-cluster) - Compute cluster creation, scaling, and configuration options

### Compute Resources and Performance Optimization

- [Azure VM Sizes](https://learn.microsoft.com/azure/virtual-machines/sizes) - Complete VM size specifications including D-series for general purpose ML workloads
- [Azure Machine Learning Compute Target Options](https://learn.microsoft.com/azure/machine-learning/concept-compute-target) - Comparison of compute options including clusters, instances, and AKS integration
- [Manage and Optimize Compute Costs](https://learn.microsoft.com/azure/machine-learning/how-to-manage-optimize-cost) - Cost optimization strategies, auto-scaling, and low-priority VMs

### Infrastructure Automation and Deployment

- [Terraform Azure Machine Learning Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/machine_learning_workspace) - Azure Machine Learning Terraform resource documentation
- [Azure Resource Manager Templates for ML](https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.machinelearningservices) - Production ML infrastructure templates and configurations

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
