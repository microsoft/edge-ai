---
title: General User Guide - Getting Started
description: Deploy and use the AI on Edge Flagship Accelerator with step-by-step instructions for both Terraform and Bicep deployments
author: Edge AI Team
ms.date: 2025-12-18
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

- **Azure subscription** with appropriate permissions (see [Required Azure Permissions](#required-azure-permissions) below)
- **Azure resource providers registered** - Run the registration script in [src/azure-resource-providers/][azure-resource-providers] once per subscription

    ```sh
    # Bash
    ./src/azure-resource-providers/register-azure-providers.sh aio-azure-resource-providers.txt
    # Or use PowerShell
    ./src/azure-resource-providers/register-azure-providers.ps1 -filePath aio-azure-resource-providers.txt
    ```

- **GitHub account** with access to this repository
- **Docker Desktop** installed and running (for Dev Container)
- **Visual Studio Code** with the Dev Containers extension

### Required Azure Permissions

Deploying Azure IoT Operations requires permissions to create resources and assign roles. The simplest approach:

| Approach        | Required Role                                         | Scope                          | Best For                              |
|-----------------|-------------------------------------------------------|--------------------------------|---------------------------------------|
| **Recommended** | Owner                                                 | Subscription or Resource Group | Full deployment with role assignments |
| **Alternative** | Contributor + Role Based Access Control Administrator | Subscription or Resource Group | When Owner is unavailable             |

> **Why role assignment permissions?** Blueprints create managed identities and assign them roles (e.g., Key Vault access, Arc cluster permissions). Without role assignment capability, deployments will fail during RBAC configuration.

For complete details on individual permissions, see [Azure IoT Operations Required Permissions][iot-ops-permissions].

> **💡 New to edge AI deployments?** Check out our [Learning Platform](/learning/) for hands-on learning experiences that complement this guide. Start with our [Edge-to-Cloud Systems Track](/learning/training-labs/02-edge-to-cloud-systems/) to build your expertise, learning to use AI and accelerate your solution development.

## Step 1: Set Up Development Environment

### Option A: Using Dev Container (Recommended)

The Dev Container provides a consistent, pre-configured development environment with all necessary tools.

#### Choosing Your Dev Container

This repository provides two Dev Container options in [.devcontainer/](/.devcontainer/):

| Container   | Location                                | Purpose                                         | Recommended For                                           |
|-------------|-----------------------------------------|-------------------------------------------------|-----------------------------------------------------------|
| **Default** | `.devcontainer/devcontainer.json`       | Standard development with all core tools        | General users, infrastructure deployment                  |
| **Beads**   | `.devcontainer/beads/devcontainer.json` | Extended Copilot features with Beads MCP server | Advanced users experimenting with AI-assisted development |

The **default container** is recommended for most users. It includes:

- Azure CLI with pre-installed extensions (`connectedk8s`, `k8s-extension`, `azure-iot-ops`, `amg`, `eventgrid`)
- Terraform with terraform-docs
- kubectl, Helm, K3d, K9s
- Docker (using host daemon)
- Python, Node.js, Go, Rust, .NET

The **beads container** adds experimental Beads MCP server integration and custom Copilot chat modes. Use this only if you're exploring advanced AI-assisted workflows.

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
   - Select the default container

4. **Verify setup**:

   ```bash
   # Check available tools
   terraform version
   az version
   kubectl version --client
   ```

> **🚀 Guided Deployment with GitHub Copilot**: Once you have the Dev Container running, you can use GitHub Copilot Chat to guide you through the entire deployment process.
>
> In Agent mode, enter:
>
> ```text
> /getting-started help me deploy my first blueprint
> ```
>
> This interactive prompt walks you through blueprint selection, variable configuration, and deployment step-by-step. It's the fastest way to get started!

### Option B: Local Development

If you prefer local development, install these tools:

- [Azure CLI][azure-cli] with extensions `connectedk8s`, `k8s-extension`, `azure-iot-ops`, `amg` and `eventgrid`:

   ```bash
   # Install Azure CLI extensions
   az extension add --name connectedk8s
   az extension add --name k8s-extension
   az extension add --name azure-iot-ops
   az extension add --name amg
   az extension add --name eventgrid
   ```

- [Terraform][terraform-install] (version 1.14.x recommended for lazy evaluation support)
- [kubectl][kubectl-install]
- [Docker][docker-install]
- [Python][python-install]

## Step 2: Choose Your Blueprint

Blueprints are pre-configured deployment templates. Here is a quick overview of the common blueprints available:

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

2. **Create your configuration file**:

   Create a `terraform.auto.tfvars` file with the required variables. Most blueprints require only three core variables:

   ```terraform
   # terraform.auto.tfvars - Minimal required configuration
   environment     = "dev"         # dev, test, or prod
   location        = "eastus2"     # Azure region
   resource_prefix = "myprefix"    # 5-8 alphanumeric chars, must be globally unique
   ```

   ```bash
   # Create and edit your configuration file
   code terraform.auto.tfvars
   ```

   > **⚠️ Important**: Review and update these key variables before deployment:
   >
   > - `resource_prefix`: Use a unique prefix (max 8 chars, alphanumeric only) - this affects resource naming globally
   > - `environment`: Set to "dev", "test", or "prod"
   > - `location`: Choose your preferred Azure region (e.g., `eastus2`, `westus3`)

   <!-- -->

   > **💡 Tip**: Terraform automatically picks up `*.auto.tfvars` files without needing the `-var-file` flag, making deployment simpler.

   <!-- -->

   > **📝 Finding required vs optional variables**: Each blueprint's `README.md` documents all available variables:
   >
   > ```bash
   > # View the Inputs section to identify required variables
   > grep -A 100 "## Inputs" README.md | head -50
   > ```
   >
   > Variables marked with `n/a` in the Default column are required; all others are optional with sensible defaults.

   <!-- -->

   > **💡 Advanced**: Generate a complete variable template using `terraform-docs`:
   >
   > ```bash
   > terraform-docs tfvars hcl .
   > ```
   >
   > **Note**: Do not use this output directly as it may override null defaults with empty values that can break deployment. Only add variables to `terraform.auto.tfvars` that you explicitly want to configure.

3. **Set up environment variables and initialize Terraform**:

   ```bash
   # Set required environment variable for Terraform Azure provider by running the script
   source ../../../scripts/az-sub-init.sh

   # Initialize Terraform (pulls down providers and modules)
   terraform init -upgrade
   ```

4. **Plan and apply the deployment**:

   ```bash
   # Preview changes before applying
   terraform plan

   # Review resource change list, then deploy
   terraform apply
   ```

   > **🔍 Pre-Apply Checklist**:
   >
   > - Verify your `terraform.auto.tfvars` has the correct `resource_prefix`, `environment`, and `location`
   > - Ensure you're logged into the correct Azure subscription (`az account show`)
   > - Review the `terraform plan` output to confirm expected resources
   >
   > **Note**: Add `-auto-approve` to the apply command to skip confirmation.

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
param customLocationsOid = '' // Replace with 'CUSTOM_LOCATIONS_OID' retrieved earlier
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

#### VM Extension Script Failures

**Problem**: Azure VM custom script extension fails during cluster deployment

VM extensions run scripts on the VM after provisioning. Common failure causes include:

- Network connectivity issues preventing package downloads
- Script timeouts (default 90 minutes)
- Missing prerequisites on the VM
- Key Vault access issues when using script-from-secrets deployment

**Solution**:

1. **Check extension status**:

   ```bash
   # Get extension provisioning state
   az vm extension list --resource-group $RG_NAME --vm-name $VM_NAME --output table

   # View detailed extension output
   az vm extension show --resource-group $RG_NAME --vm-name $VM_NAME \
     --name linux-cluster-server-setup --query "instanceView.statuses[0].message" -o tsv
   ```

2. **Review logs on the VM**:

   ```bash
   # SSH to VM and check extension logs
   sudo cat /var/log/azure/custom-script/handler.log
   sudo cat /var/lib/waagent/custom-script/download/0/stdout
   sudo cat /var/lib/waagent/custom-script/download/0/stderr
   ```

3. **Handling VM extension failures**:

   VM extension script deployments can fail for various reasons (network issues, timeouts, provider bugs). The most reliable solution is a full redeployment:

   ```bash
   # Destroy all resources
   terraform destroy

   # Redeploy from scratch
   terraform apply
   ```

   This ensures a clean state and avoids issues with partial deployments, state inconsistencies, and script idempotency problems.

4. **Key Vault script deployment issues**:

   When using `should_use_script_from_secrets_for_deploy = true`:

   - Verify the managed identity has `Key Vault Secrets User` role on the Key Vault
   - Check that secrets exist with the expected naming pattern: `{prefix}-{distro}-{node_type}-script`
   - Ensure the VM has network access to the Key Vault endpoint

#### Arc Cluster Connectivity Issues

**Problem**: `az connectedk8s proxy` succeeds but `kubectl` commands fail

The `az connectedk8s proxy` command establishes a connection to the Arc cluster proxy service but does not verify actual cluster connectivity. If the VM hosting the cluster is shutdown or unreachable, the proxy command succeeds but `kubectl` commands fail.

**Diagnostic command**:

```bash
# Check Arc cluster connectivity status
az connectedk8s show -g "$RG_NAME" -n "$ARC_CONNECTED_CLUSTER_NAME" \
  --query "{provisioningState:provisioningState, connectivityStatus:connectivityStatus}" -o yaml
```

**Expected output when cluster is healthy**:

```yaml
connectivityStatus: Connected
provisioningState: Succeeded
```

**Common scenarios and solutions**:

1. **VM shutdown**: If the VM is stopped, `connectivityStatus` shows `Offline` or `Expired`

   **Solution**: Start the VM through Azure Portal or CLI:

   ```bash
   az vm start --resource-group $RG_NAME --name $VM_NAME
   ```

2. **Network connectivity**: VM cannot reach Azure Arc endpoints

   **Solution**:
   - Verify network security groups allow outbound HTTPS traffic to Arc service endpoints
   - Check VM's network configuration and DNS resolution

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
[kubectl-install]: https://kubernetes.io/docs/tasks/tools/install-kubectl/
[docker-install]: https://docs.docker.com/get-docker/
[blueprint-full-single]: /blueprints/full-single-node-cluster/
[blueprint-full-multi]: /blueprints/full-multi-node-cluster/
[blueprint-minimum]: /blueprints/minimum-single-node-cluster/
[blueprint-cloud-only]: /blueprints/only-cloud-single-node-cluster/
[iot-ops-quickstart]: https://learn.microsoft.com/azure/iot-operations/get-started-end-to-end-sample/quickstart-deploy
[iot-ops-docs]: https://learn.microsoft.com/azure/iot-operations/
[iot-ops-permissions]: https://learn.microsoft.com/azure/iot-operations/deploy-iot-ops/overview-deploy#required-permissions
[project-repo]: {{REPO_URL}}
[python-install]: https://www.python.org/downloads/
[azure-resource-providers]: /src/azure-resource-providers/

_AI and automation capabilities described in this scenario should be implemented following responsible AI principles, including fairness, reliability, safety, privacy, inclusiveness, transparency, and accountability. Organizations should ensure appropriate governance, monitoring, and human oversight are in place for all AI-powered solutions._

<!-- markdownlint-disable MD036 -->

_🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers._

<!-- markdownlint-enable MD036 -->
