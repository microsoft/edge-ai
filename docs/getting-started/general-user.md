---
title: General User Guide - Getting Started
description: Deploy and use the AI on Edge Flagship Accelerator with step-by-step instructions for both Terraform and Bicep deployments
author: Edge AI Team
ms.date: 2025-06-15
ms.topic: how-to
estimated_reading_time: 5
keywords:
  - general user
  - deployment
  - blueprint
  - terraform
  - bicep
  - Azure IoT Operations
---

## General User Guide - Getting Started

This guide is designed for users who want to deploy and use the AI on Edge Flagship Accelerator. Follow these steps to get up and running quickly with pre-built blueprints.

## Prerequisites

Before you begin, ensure you have:

- **Azure subscription** with appropriate permissions
- **GitHub account** with access to this repository
- **Docker Desktop** installed and running (for Dev Container)
- **Visual Studio Code** with the Dev Containers extension

> **💡 New to edge AI deployments?** Check out our [PraxisWorx Training Platform](/praxisworx/) for hands-on learning experiences that complement this guide. Start with our [Edge-to-Cloud Systems Track](/praxisworx/training-labs/02-edge-to-cloud-systems/) to build your expertise, learning to use AI and accelerate your solution development.

## Step 1: Set Up Development Environment

### Option A: Using Dev Container (Recommended)

The Dev Container provides a consistent, pre-configured development environment with all necessary tools.

1. **Clone the repository**:

   ```bash
   git clone {{CLONE_URL}}
   cd edge-ai
   ```

2. **Open in VS Code**:

   ```bash
   code .
   ```

3. **Reopen in Dev Container**:
   - When prompted, click "Reopen in Container"
   - Or use Command Palette: `Remote-Containers: Reopen in Container`

4. **Verify setup**:

   ```bash
   # Check available tools
   terraform version
   az version
   kubectl version --client
   ```

### Option B: Local Development

If you prefer local development, install these tools:

- [Azure CLI][azure-cli]
- [Terraform][terraform-install] (>= 1.0)
- [kubectl][kubectl-install]
- [Docker][docker-install]
- [Python][python-install]

## Step 2: Choose Your Blueprint

Blueprints are pre-configured deployment templates. Select one based on your scenario:

| Blueprint                                              | Description                     | Use Case                          |
|--------------------------------------------------------|---------------------------------|-----------------------------------|
| [full-single-node-cluster][blueprint-full-single]      | Complete single-node deployment | Testing, small deployments        |
| [full-multi-node-cluster][blueprint-full-multi]        | Production multi-node cluster   | Production environments           |
| [minimum-single-node-cluster][blueprint-minimum]       | Minimal single-node setup       | Resource-constrained environments |
| [only-cloud-single-node-cluster][blueprint-cloud-only] | Cloud components only           | Cloud-first deployments           |

### Blueprint Directory Structure

blueprints/
├── full-single-node-cluster/
│   ├── terraform/
│   └── bicep/
├── full-multi-node-cluster/
│   ├── terraform/
│   └── bicep/
└── minimum-single-node-cluster/
    ├── terraform/
    └── bicep/

## Step 3: Deploy Your Blueprint

### Using Terraform

#### Interactive Deployment

1. **Navigate to your chosen blueprint**:

   ```bash
   cd blueprints/full-single-node-cluster/terraform
   ```

2. **Initialize Terraform**:

   ```bash
   terraform init
   ```

3. **Create configuration file**:

   ```bash
   # Copy example configuration
   cp terraform.tfvars.example terraform.tfvars

   # Edit with your values
   code terraform.tfvars
   ```

4. **Plan the deployment**:

   ```bash
   terraform plan
   ```

5. **Apply the configuration**:

   ```bash
   terraform apply
   ```

#### Automated Deployment

Use our deployment script for simplified deployment:

```bash
# Set environment variables
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"

# Run deployment script
./scripts/deploy-blueprint.sh full-single-node-cluster terraform
```

### Using Bicep

#### Interactive Bicep Deployment

1. **Navigate to your chosen blueprint**:

   ```bash
   cd blueprints/full-single-node-cluster/bicep
   ```

2. **Login to Azure**:

   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

3. **Create resource group**:

   ```bash
   az group create --name "rg-edge-ai" --location "East US"
   ```

4. **Deploy the blueprint**:

   ```bash
   az deployment group create \
     --resource-group "rg-edge-ai" \
     --template-file main.bicep \
     --parameters @parameters.json
   ```

#### Automated Bicep Deployment

Use our deployment script for simplified deployment:

```bash
# Set environment variables
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
export AZURE_RESOURCE_GROUP="rg-edge-ai"

# Run deployment script
./scripts/deploy-blueprint.sh full-single-node-cluster bicep
```

## Step 4: Verify Deployment

After deployment completes, verify your resources:

### Check Azure Resources

```bash
# List deployed resources
az resource list --resource-group "rg-edge-ai" --output table

# Check specific services
az aks list --resource-group "rg-edge-ai" --output table
az iot hub list --resource-group "rg-edge-ai" --output table
```

### Connect to Kubernetes Cluster

```bash
# Get cluster credentials
az aks get-credentials --resource-group "rg-edge-ai" --name "your-cluster-name"

# Verify connection
kubectl get nodes
kubectl get pods --all-namespaces
```

## Step 5: Access Your Application

The specific access methods depend on your chosen blueprint:

### Web Interface Access

```bash
# Get external IP addresses
kubectl get services --all-namespaces

# Access applications (example URLs)
# Grafana: http://<grafana-external-ip>:3000
# Azure IoT Operations: http://<iot-ops-external-ip>:8080
```

### Command Line Access

```bash
# Port forward for local access
kubectl port-forward service/grafana 3000:3000 -n monitoring
kubectl port-forward service/iot-operations 8080:8080 -n azure-iot-operations
```

## GitHub Copilot Assistance

Use GitHub Copilot throughout your deployment for interactive help:

### Quick Copilot Commands

- **"@workspace How do I troubleshoot deployment errors?"**
- **"Explain the blueprint structure in /blueprints/full-single-node-cluster"**
- **"Help me configure terraform.tfvars for my environment"**
- **"What Azure resources will be created by this blueprint?"**

### Using Copilot Prompts

1. **Getting Started Prompt**: Use `/getting-started` in Copilot chat for guided setup
2. **Deployment Assistance**: Ask specific questions about your chosen infrastructure tool
3. **Troubleshooting**: Get help with error messages and configuration issues

## Troubleshooting

### Common Issues

#### Authentication Errors

**Problem**: Azure authentication failures

**Solution**:

```bash
# Re-authenticate with Azure
az login --tenant "your-tenant-id"
az account set --subscription "your-subscription-id"

# For service principal authentication
az login --service-principal -u "app-id" -p "password" --tenant "tenant-id"
```

#### Terraform State Issues

**Problem**: Terraform state conflicts

**Solution**:

```bash
# Refresh state
terraform refresh

# Import existing resources (if needed)
terraform import azurerm_resource_group.main /subscriptions/{subscription-id}/resourceGroups/{rg-name}
```

#### Resource Quota Errors

**Problem**: Azure resource quota exceeded

**Solution**:

1. Check current quotas:

   ```bash
   az vm list-usage --location "East US" --output table
   ```

2. Request quota increase through Azure portal
3. Choose a different region with available capacity

#### Dev Container Issues

**Problem**: Dev Container fails to build

**Solution**:

1. **Restart Docker Desktop**
2. **Clear Docker cache**:

   ```bash
   docker system prune -a
   ```

3. **Rebuild container**:
   - Command Palette: `Remote-Containers: Rebuild Container`

### Getting Help

1. **Check logs**:

   ```bash
   # Terraform logs
   TF_LOG=DEBUG terraform apply

   # Azure CLI logs
   az group create --name test --location eastus --debug
   ```

2. **Use GitHub Copilot**: Ask specific questions about errors you encounter

3. **Review documentation**: Check [Azure IoT Operations documentation][iot-ops-docs] for platform-specific issues

4. **Community support**: Create an issue in the repository with:
   - Error messages
   - Steps to reproduce
   - Environment details (OS, tool versions)

## Next Steps

After successful deployment:

1. **Explore the solution**: Familiarize yourself with deployed components
2. **Configure monitoring**: Set up alerts and dashboards in Grafana
3. **Customize settings**: Modify configuration for your specific needs
4. **Learn more**: Review [Azure IoT Operations documentation][iot-ops-docs] for advanced features

## Additional Resources

- **[Blueprint Developer Guide](blueprint-developer.md)** - Create custom blueprints
- **[Feature Developer Guide](feature-developer.md)** - Contribute to the platform
- **[Azure IoT Operations Getting Started][iot-ops-quickstart]** - Official Microsoft guide
- **[Troubleshooting Documentation](../observability/)** - Detailed troubleshooting guides

---

*This guide is part of the AI on Edge Flagship Accelerator project. For the latest updates and comprehensive resources, visit our [project repository][project-repo].*

[azure-cli]: https://docs.microsoft.com/cli/azure/install-azure-cli
[terraform-install]: https://learn.hashicorp.com/tutorials/terraform/install-cli
[kubectl-install]: https://kubernetes.io/docs/tasks/tools/install-kubectl/
[docker-install]: https://docs.docker.com/get-docker/
[blueprint-full-single]: blueprints/full-single-node-cluster/
[blueprint-full-multi]: blueprints/full-multi-node-cluster/
[blueprint-minimum]: blueprints/minimum-single-node-cluster/
[blueprint-cloud-only]: blueprints/only-cloud-single-node-cluster/
[iot-ops-quickstart]: https://learn.microsoft.com/azure/iot-operations/get-started-end-to-end-sample/quickstart-deploy
[iot-ops-docs]: https://learn.microsoft.com/azure/iot-operations/
[project-repo]: {{REPO_URL}}
[python-install]: https://www.python.org/downloads/

*AI and automation capabilities described in this scenario should be implemented following responsible AI principles, including fairness, reliability, safety, privacy, inclusiveness, transparency, and accountability. Organizations should ensure appropriate governance, monitoring, and human oversight are in place for all AI-powered solutions.*

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
