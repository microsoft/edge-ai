# Blueprints

## Overview

Blueprints are the Infrastructure as Code (IaC) composition mechanism for this repository. They
provide ready-to-deploy end-to-end solutions that showcase how to combine individual components into
complete edge computing solutions. Blueprints can be deployed as-is, extended, modified, or layered
to build complex multi-stage solutions that meet your specific requirements.

## Available Blueprints

| Blueprint                                                               | Description                                                                                  |
|-------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| [Full Single Cluster](./full-single-cluster/README.md)                  | Complete deployment of Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster |
| [Full Multi-node Cluster](./full-single-cluster/README.md)              | Complete deployment of Azure IoT Operations on a multi-node, Arc-enabled Kubernetes cluster  |
| [CNCF Cluster Script Only](./only-output-cncf-cluster-script/README.md) | Generates scripts for cluster creation without deploying resources                           |
| [Azure Fabric Environment](./fabric/terraform/README.md)                | Provisions Azure Fabric environment  *Terraform only currently*                              |
| *More coming soon...*                                                   |                                                                                              |

## Terraform Architecture

Each blueprint in this repository follows a consistent structure:

- **Main Configuration**: Root module that orchestrates component deployment
- **Variables**: Defined in `variables.tf` with descriptions and default values
- **Outputs**: Critical resource information returned after deployment in `outputs.tf`
- **Reusable Modules**: Leverages components from `/src` to ensure consistency and maintainability
- **Local State**: By default, state is stored locally but can be configured for remote backends

## Blueprint Selection Guide

- **Full Single Cluster**: Best for development, testing, and proof-of-concept deployments
- **Full Multi-node Cluster**: Recommended for general purpose lab and production-grade deployments requiring high availability
- **CNCF Cluster Script Only**: Ideal for environments with existing infrastructure or custom deployment processes
- **Azure Fabric Environment**: For users looking to provision Azure Fabric environments with options to deploy Lakehouse, EventStream, and Fabric workspace

## Prerequisites

**IMPORTANT:** We highly suggest using [this project's integrated dev container](./.devcontainer/README.md) to get started quickly with Windows-based systems and also works well with nix-compatible environments.

Refer to the Environment Setup section in the [Root README](../README.md#getting-started-and-prerequisites-setup) for detailed instructions on setting up your environment.

## Detailed Deployment Workflow

### Getting Started with Terraform

#### ⚠️ Terraform Prerequisites Required Before Proceeding

> **You must complete all [prerequisites and environment setup](../README.md#getting-started-and-environment-setup) before running these steps.**
> Ensure your Azure CLI is logged in and your subscription context is set correctly.

1. **IMPORTANT**: Register required Azure resource providers before proceeding. These scripts need to be run once per subscription to ensure all necessary provider services are available:

   **Using Bash:**

   ```sh
   # Navigate to the resource providers directory
   cd ./src/azure-resource-providers

   # Run the registration script
   ./register-all-providers.sh
   ```

   **Using PowerShell:**

   ```powershell
   # Navigate to the resource providers directory
   cd \src\azure-resource-providers

   # Run the registration script (will prompt for confirmation)
   .\Register-AllProviders.ps1
   ```

   This step is critical as Azure IoT Operations and Arc-enabled Kubernetes require several resource providers that might not be registered by default in your subscription.

2. Navigate to your chosen blueprint directory:

   ```sh
   cd ./full-single-node-cluster
   ```

3. Set up required environment variables:

   - **ARM_SUBSCRIPTION_ID** -- The Azure Subscription ID target for this deployment (required to be set for the Terraform tasks below)

   ```sh
   # Dynamically get the Subscription ID or manually get and pass to ARM_SUBSCRIPTION_ID
   current_subscription_id=$(az account show --query id -o tsv)
   export ARM_SUBSCRIPTION_ID="$current_subscription_id"
   ```

4. Create a `terraform.tfvars` file with the following minimum configuration:

   ```hcl
   # Required, environment hosting resource: "dev", "prod", "test", etc...
   environment     = "<environment>"
   # Required, short unique alphanumeric string: "sample123", "plantwa", "uniquestring", etc...
   resource_prefix = "<resource-prefix>"
   # Required, region location: "eastus2", "westus3", etc...
   location        = "<location>"
   # Optional, instance/replica number: "001", "002", etc...
   instance        = "<instance>"
   ```

   > **NOTE**: To have Terraform automatically use your variables, you can name your tfvars file `terraform.auto.tfvars`. Terraform will use variables from any `*.auto.tfvars` files located in the same deployment folder.

5. Initialize and apply Terraform:

   ```sh
   # Pulls down providers and modules, initializes state and backend
   terraform init # Use '-update -reconfigure' if provider or backend updates are required

   # Preview changes before applying
   terraform plan -var-file=terraform.tfvars

   # Review resource change list, then deploy
   terraform apply -var-file=terraform.tfvars # Add '-auto-approve' to skip confirmation
   ```

6. Wait for the deployments to complete with the message:

   ```txt
   Apply complete! Resources: *** added, *** changed, *** destroyed.
   ```

### Getting Started with Bicep

Bicep provides an alternative Infrastructure as Code (IaC) approach that's native to Azure. Follow these steps to deploy blueprints using Bicep:

#### ⚠️ Bicep Prerequisites Required Before Proceeding

> **You must complete all [prerequisites and environment setup](../README.md#getting-started-and-environment-setup) before running these steps.**
> Ensure your Azure CLI is logged in and your subscription context is set correctly.

1. Use the Azure CLI to get the Custom Locations OID:

   ```sh
   # Get the custom locations OID
   az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
   ```

2. **IMPORTANT**: Register required Azure resource providers before proceeding. These scripts need to be run once per subscription to ensure all necessary provider services are available:

   **Using Bash:**

   ```sh
   # Navigate to the resource providers directory
   cd ./src/azure-resource-providers

   # Run the registration script
   ./register-all-providers.sh
   ```

   **Using PowerShell:**

   ```powershell
   # Navigate to the resource providers directory
   cd \src\azure-resource-providers

   # Run the registration script (will prompt for confirmation)
   .\Register-AllProviders.ps1
   ```

   This step is critical as Azure IoT Operations and Arc-enabled Kubernetes require several resource providers that might not be registered by default in your subscription.

3. Navigate to your chosen blueprint directory:

   ```sh
   cd ./full-single-node-cluster
   ```

4. Check that the Bicep CLI is installed or install it:

   ```sh
   # Verify Bicep installation (included in recent Azure CLI versions)
   az bicep version

   # If not installed:
   az bicep install
   ```

5. Create a parameters file for your deployment:

   Create a file named `main.bicepparam` in the root of the blueprint directory (e.g., `full-single-node-cluster`) with your deployment parameters:

   ```bicep
   // Parameters for blueprint deployment
   using './bicep/main.bicep'

   // Required parameters
   param common = {
     resourcePrefix: 'myprefix'     // Replace with a unique prefix
     location: 'eastus2'            // Replace with your Azure region
     environment: 'dev'             // 'dev', 'test', or 'prod'
     instance: '001'
   }

   // This is not optimal, to be replaced by KeyVault usage in future
   @secure()
   param adminPassword = 'YourSecurePassword123!' // Replace with a secure password

   param customLocationsOid = 'YourRetrievedOID' // Replace with the OID retrieved from the previous step
   ```

6. Deploy the Bicep template:

   ```sh
   # Deploy using the Azure CLI at the subscription level
   az deployment sub create --name <uniquename-prefix> --location <location> --parameters ./main.bicepparam
   ```

7. Monitor deployment progress:

   You can check the deployment status in the Azure portal or using the Azure CLI:

   ```sh
   # Get the resource group name (after deployment starts)
   RG_NAME="rg-<resource_prefix>-<environment>-<instance>"

   # List resources in the resource group
   az resource list --resource-group $RG_NAME -o table
   ```

8. Access Deployed Resources:

   After successful deployment:

   ```sh
   # Access the Kubernetes cluster (in one prompt)
   az connectedk8s proxy -n <cluster-name> -g $RG_NAME

   # View AIO resources (in a separate prompt)
   kubectl get pods -n azure-iot-operations

   # Check cluster node status
   kubectl get nodes -o wide
   ```

## Common Terraform Commands

```sh
# Validate Terraform configuration
terraform validate

# Format Terraform files
terraform fmt

# Preview changes before applying
terraform plan -var-file=terraform.tfvars

# Clean up deployed resources
terraform destroy -var-file=terraform.tfvars
```

## State Management

By default, Terraform state is stored locally. For team environments, consider configuring a remote backend:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "terraformstate"
    container_name       = "tfstate"
    key                  = "blueprint.tfstate"
  }
}
```

## Industry Solutions

The blueprints in this repository can be used to implement a variety of industry solutions across different pillars. We are working aggressively towards building blueprints for each of these scenarios as time move on:

| Industry Pillar                                | Scenario                                              | Description                                                                                                                                  |
|------------------------------------------------|-------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|
| **Process & Production Optimization**          | Packaging Line Performance Optimization               | Line & Bottleneck automated control                                                                                                          |
|                                                | End-to-end batch planning and optimization            | Digitally enabled batch release                                                                                                              |
|                                                | Changeover & Cycle Time Optimization                  | Advanced analytics-based cycle time optimization                                                                                             |
|                                                | Autonomous Material Movement                          | Advanced IIoT applied to process optimization                                                                                                |
|                                                | Operational Performance Monitoring                    | Digital tools to enhance a connected workforce                                                                                               |
|                                                | Inventory Optimization                                | Real-time inventory management (internal/ external)                                                                                          |
|                                                | Yield Process Optimization                            | Advanced IIoT applied to process optimization                                                                                                |
| **Intelligent Asset Health**                   | Digital Inspection / Survey                           | Automated inspection enabled by digital thread                                                                                               |
|                                                | Predictive Maintenance                                | AI driven predictive analysis for critical asset lifecycle management                                                                        |
| **Empower Your Workforce**                     | Intelligent Assistant (CoPilot/Companion)             | Smart workforce planning and optimization                                                                                                    |
|                                                | Integrated Maintenance/Work Orders                    | Resource efficiency with operations AI enabled data analytics                                                                                |
|                                                | Immersive Remote Operations                           | Smart workforce upskilling tool                                                                                                              |
|                                                | Enhanced Personal Safety                              | Virtual Muster. Robot-aided process operations support                                                                                       |
|                                                | Virtual Training                                      | Immersive Training                                                                                                                           |
| **Smart Quality Management**                   | Quality Process Optimization & Automation             | IoT-enabled manufacturing quality management                                                                                                 |
|                                                | Automated Quality Diagnostics & Simulation            | Quality diagnostic system empowered by AI search engine e.g. line performance monitoring                                                     |
| **Frictionless Material Handling & Logistics** | End-to-end Material Handling                          | Analytics for dynamic warehouse resource planning and scheduling                                                                             |
|                                                | Logistics Optimization & Automation                   | Logistics Control Tower                                                                                                                      |
|                                                | Autonomous Cell                                       | Fully automated process for discreet manufacturing                                                                                           |
|                                                | Semi-Autonomous Cell                                  | Human robotics orchestration                                                                                                                 |
| **Consumer in the IMV**                        | Connected Consumer Experience                         | Generative AI Customer Agent. Augmented remote assistance                                                                                    |
|                                                | Connected Consumer Insights                           | Digital twin of customer system                                                                                                              |
| **Virtual Design, Build & Operate Lifecycle**  | Automated Product Design                              | Digital twins and process modelling and simulation enabling shorter qualification trials in R&D                                              |
|                                                | Facility Design & Simulation                          | Operation research model-based factory capacity optimization                                                                                 |
|                                                | Product Innovation                                    | Ecosystem digital twin for co-development. Data unification for federation                                                                   |
|                                                | Product Lifecycle Simulation                          | Intelligent Personalization. Simulated product lifecycle performance                                                                         |
|                                                | Automated Formula Management                          | Product Formula Simulation. Model based Design                                                                                               |
| **Cognitive Supply Ecosystem**                 | Ecosystem Orchestration                               | Agile logistics bidding through analytics-enabled capacity and price prediction                                                              |
|                                                | Ecosystem Decision Support                            | A closed-loop analytic model connects portfolio, scenario, value, and situational analysis to drive supply chain innovation powered by AR/VR |
| **Sustainability for the IMV**                 | Energy optimization for fixed facility/process assets | IIoT and advanced analytics based energy consumption optimization across ecosystem                                                           |
|                                                | Compressed Air Optimization                           | Compressed air optimization using predictive analytics                                                                                       |
|                                                | Waste Circular Economy                                | Advanced IIoT applied to process optimization                                                                                                |
|                                                | Water Usage Optimization                              | Advanced analytics enabled clean water reduction and contaminated water cleaning optimization                                                |

## Getting Started with Your Industry Solution

1. Identify the industry scenario from the table above that best matches your requirements
2. Select the appropriate blueprint based on your infrastructure needs (single node or multi-node)
3. Follow the deployment instructions in this document
4. After deployment, customize the solution with additional components specific to your industry scenario

For more information about implementing specific industry solutions, please contact the solution team.
