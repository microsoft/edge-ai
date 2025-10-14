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
- [terraform-docs][terraform-docs-install] (for generating variable templates)
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

> **📋 More Blueprints Available**: Additional blueprints are available including `fabric`, `fabric-rti`, `dual-peered-single-node-cluster`, `only-edge-iot-ops`, `azureml`, and more. Check the [`/blueprints`](/blueprints/) directory for the complete list and detailed descriptions.

### Blueprint Directory Structure

```text
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
```

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

3. **Generate and create configuration file**:

   ```bash
   # Generate terraform.tfvars template using terraform-docs
   terraform-docs tfvars hcl .
   ```

   The generated output will look similar to the following:

   ```terraform
   # Required variables
   environment     = "dev"                 # Environment type (dev, test, prod)
   resource_prefix = "myprefix"            # Short unique prefix for resource naming
   location        = "eastus2"             # Azure region location
   # Optional (recommended) variables
   instance        = "001"                 # Deployment instance number
   ```

   Copy this output to a file named `terraform.tfvars` and fill in your specific values:

   ```bash
   # Create and edit your configuration file
   code terraform.tfvars
   ```

   > **⚠️ Important**: Review and update these key variables before deployment:
   >
   > - `resource_prefix`: Use a unique prefix (max 8 chars, alphanumeric only)
   > - `environment`: Set to "dev", "test", or "prod"
   > - `location`: Choose your preferred Azure region
   > - Update any optional values that you want to change as well
   >
   > **💡 Tip**: To have Terraform automatically use your variables, you can name your tfvars file `terraform.auto.tfvars`. Terraform will use variables from any `*.auto.tfvars` files located in the same deployment folder.

4. **Set up environment variables and initialize Terraform**:

   ```bash
   # Set required environment variable for Terraform Azure provider
   export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

   # Initialize Terraform (pulls down providers and modules)
   terraform init -upgrade
   ```

5. **Plan and apply the deployment**:

   ```bash
   # Preview changes before applying
   terraform plan -var-file=terraform.tfvars

   # Review resource change list, then deploy
   terraform apply -var-file=terraform.tfvars
   ```

   > **🔍 Pre-Apply Checklist**:
   >
   > - Verify your `terraform.tfvars` has the correct `resource_prefix`, `environment`, and `location`
   > - Ensure you're logged into the correct Azure subscription (`az account show`)
   > - Review the `terraform plan` output to confirm expected resources
   >
   > **Note**: Add `-auto-approve` to the apply command to skip confirmation, or use `-var-file` if not using `*.auto.tfvars` file

### Using Bicep

#### Interactive Bicep Deployment

**Navigate to your chosen blueprint**:

   ```bash
   cd blueprints/full-single-node-cluster/bicep
   ```

**Login to Azure and set up environment**:

   ```bash
   az login
   az account set --subscription "your-subscription-id"

   # Get the custom locations OID and export it as an environment variable
   export CUSTOM_LOCATIONS_OID=$(az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv)

   # Verify the environment variable is set correctly
   echo $CUSTOM_LOCATIONS_OID
   ```

**Create the parameters file**:

```bash
# Create main.bicepparam with the required parameters
cat <<'EOF' > main.bicepparam
using './main.bicep'

// Required parameters for the common object
param common = {
    resourcePrefix: 'prf01a2'     // Keep short (max 8 chars) to avoid resource naming issues
    location: 'eastus2'           // Replace with your Azure region
    environment: 'dev'            // 'dev', 'test', or 'prod'
    instance: '001'               // For multiple deployments
}

param resourceGroupName = 'rg-${common.resourcePrefix}-${common.environment}-${common.instance}'
param useExistingResourceGroup = false
param telemetry_opt_out = false
param adminPassword = '' // Supply a secure password
param shouldCreateAcrPrivateEndpoint = false
param shouldCreateAks = false
param customLocationsOid = '' // Replace with 'CUSTOM_LOCATIONS_OID' retrieved earlier
param shouldCreateAnonymousBrokerListener = false
EOF
```

   After creating the file, open it in your editor (`code main.bicepparam`) and replace the sample values with the settings for your deployment. Replace `customLocationsOid` with the correct value from the environment variable `CUSTOM_LOCATIONS_OID`.

> **⚠️ Important**: Confirm the `common` object matches your environment, choose the correct region, and review each optional parameter flag before continuing.

**Deploy the blueprint**:

   > **🔍 Pre-Deploy Checklist**:
   >
   > - Verify your `main.bicepparam` has the correct `resourcePrefix`, `environment`, and `location`
   > - Ensure `customLocationsOid` is set correctly
   > - Confirm you're logged into the correct Azure subscription (`az account show`)

   ```bash
   # Deploy using Azure CLI at subscription level (keep the `--name` value under 8 characters and unique)
   az deployment sub create --name deploy01 --location eastus2 --parameters ./main.bicepparam
   ```

## Step 4: Verify Deployment

After deployment completes, verify your resources:

### Check Azure Resources

```bash
# Get the resource group name (using your resource prefix, environment, and instance)
RG_NAME="rg-<prefix>-<environment>-<instance>"

# List deployed resources
az resource list --resource-group $RG_NAME --output table
```

### Connect to Kubernetes Cluster

```bash
# Get the arc connected cluster name after deployment
ARC_CONNECTED_CLUSTER_NAME="arck-{resource_prefix}-{environment}-{instance}"

# Access the Kubernetes cluster (in one terminal)
az connectedk8s proxy -n $ARC_CONNECTED_CLUSTER_NAME -g $RG_NAME

# Verify connection (in a separate terminal)
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

_This guide is part of the AI on Edge Flagship Accelerator project. For the latest updates and comprehensive resources, visit our [project repository][project-repo]._

[azure-cli]: https://docs.microsoft.com/cli/azure/install-azure-cli
[terraform-install]: https://learn.hashicorp.com/tutorials/terraform/install-cli
[terraform-docs-install]: https://terraform-docs.io/user-guide/installation/
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

_AI and automation capabilities described in this scenario should be implemented following responsible AI principles, including fairness, reliability, safety, privacy, inclusiveness, transparency, and accountability. Organizations should ensure appropriate governance, monitoring, and human oversight are in place for all AI-powered solutions._

<!-- markdownlint-disable MD036 -->

_🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers._

<!-- markdownlint-enable MD036 -->
