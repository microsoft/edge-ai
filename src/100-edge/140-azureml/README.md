---
title: Azure Machine Learning Arc Extension Component
description: Azure Machine Learning extension for Arc-enabled Kubernetes clusters with TLS configuration for secure inference endpoints
author: Edge AI Team
ms.date: 09/15/2025
ms.topic: reference
keywords:
  - azure machine learning
  - arc extension
  - kubernetes
  - edge ai
  - terraform
  - tls
estimated_reading_time: 3
---

## Azure Machine Learning Arc Extension Component

This component installs the Azure Machine Learning extension on Arc-enabled Kubernetes clusters, enabling distributed ML training and model inference capabilities at the edge with secure TLS endpoint configuration.

## Purpose and Role

The Azure Machine Learning Arc Extension component enables:

- **Edge ML Workloads**: Run ML training and inference workloads on Arc-enabled Kubernetes clusters
- **Distributed Training**: Scale ML training across multiple edge nodes
- **Secure Inference**: Deploy ML models with TLS-secured inference endpoints
- **Cloud Integration**: Connect edge ML workloads to Azure Machine Learning workspace
- **Certificate Management**: Provide TLS certificates for secure communication

## Component Resources

This component creates the following Azure resources:

### Core Infrastructure

- **Azure Arc Kubernetes Cluster Extension**: Azure ML extension deployment on Arc-enabled cluster
- **TLS Certificate Generation** (Optional): Self-signed certificates for development environments

### Integration Dependencies

This component integrates with:

- **Arc-enabled Kubernetes Cluster**: Target cluster from 100-cncf-cluster component
- **Azure Machine Learning Workspace**: Cloud ML workspace for model management

## Configuration Options

### Extension Configuration

- **Optional Deployment**: Extension deployment can be disabled for cluster-only scenarios
- **Training Enablement**: Configure whether to enable ML training workloads
- **Inference Enablement**: Configure whether to enable ML inference workloads
- **High Availability**: Configure inference router for high availability

### TLS Configuration

- **Certificate Modes**: Use provided certificates or generate self-signed for development
- **CNAME Configuration**: Specify custom domain name for inference endpoints
- **Security Options**: Configure secure vs insecure connections

## Deployment Scenarios

### Development with Self-Signed Certificates

```hcl
ssl_cname           = "ml-inference.local"
should_generate_ca  = true  # Development only
```

### Production with Custom Certificates

```hcl
ssl_cname    = "ml-inference.yourdomain.com"
ssl_cert_pem = file("path/to/certificate.pem")
ssl_key_pem  = file("path/to/private-key.pem")
```

### Training-Only Deployment

```hcl
should_enable_training   = true
should_enable_inference  = false
```

## Integration with Other Components

This component depends on:

- **100-cncf-cluster**: Arc-enabled Kubernetes cluster for extension deployment

This component integrates with:

- **000-cloud/080-azureml**: Azure Machine Learning workspace for cloud integration

## Variables

### Core Variables

| Variable          | Type     | Default | Description                     |
|-------------------|----------|---------|---------------------------------|
| `resource_prefix` | `string` | -       | Prefix for all resources        |
| `environment`     | `string` | -       | Environment: dev, test, or prod |
| `instance`        | `string` | "001"   | Instance identifier             |

### Dependency Variables

| Variable            | Type     | Description                             |
|---------------------|----------|-----------------------------------------|
| `connected_cluster` | `object` | Connected cluster from 100-cncf-cluster |

### Configuration Variables

| Variable                            | Type     | Default        | Description                               |
|-------------------------------------|----------|----------------|-------------------------------------------|
| `should_deploy_extension`           | `bool`   | `true`         | Deploy Azure ML extension on cluster      |
| `should_enable_training`            | `bool`   | `true`         | Enable training workloads                 |
| `should_enable_inference`           | `bool`   | `true`         | Enable inference workloads                |
| `should_enable_inference_router_ha` | `bool`   | `true`         | Enable inference router high availability |
| `inference_router_service_type`     | `string` | "LoadBalancer" | Service type for inference router         |
| `should_allow_insecure_connections` | `bool`   | `false`        | Allow HTTP connections (development only) |

### SSL/TLS Variables

| Variable             | Type     | Default | Description                                         |
|----------------------|----------|---------|-----------------------------------------------------|
| `ssl_cname`          | `string` | `""`    | CNAME used for HTTPS endpoint                       |
| `ssl_cert_pem`       | `string` | `""`    | PEM-encoded TLS certificate chain (sensitive)       |
| `ssl_key_pem`        | `string` | `""`    | PEM-encoded private key (sensitive)                 |
| `should_generate_ca` | `bool`   | `false` | Generate self-signed certificate (development only) |

## Outputs

| Output              | Description                                 |
|---------------------|---------------------------------------------|
| `azureml_extension` | Complete Azure ML extension resource object |
| `extension_name`    | Name of the deployed extension              |
| `extension_status`  | Deployment status of the extension          |

## Deployment Options

### Terraform

Refer to [Terraform Components - Getting Started](../README.md#terraform-components---getting-started) for deployment instructions.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

## Security Considerations

- **TLS Configuration**: Always use proper TLS certificates in production environments
- **Development Certificates**: Self-signed certificates should only be used for development/testing
- **Arc Security**: Leverages Arc-enabled cluster security model and managed identity
- **Secure Communication**: All ML workload communication secured via TLS when properly configured

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
