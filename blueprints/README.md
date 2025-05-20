# Blueprints

## Overview

Blueprints are the Infrastructure as Code (IaC) composition mechanism for this repository. They
provide ready-to-deploy end-to-end solutions that showcase how to combine individual components into
complete edge computing solutions. Blueprints can be deployed as-is, extended, modified, or layered
to build complex multi-stage solutions that meet your specific requirements.

## Available Blueprints

| Blueprint                                                               | Description                                                                                                                                        |
|-------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| [Minimum Single Cluster](./minimum-single-node-cluster/README.md)       | Minimum deployment of Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster, omitting observability, messaging, and ACR components |
| [Full Single Cluster](./full-single-node-cluster/README.md)             | Complete deployment of Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster                                                       |
| [Full Multi-node Cluster](./full-multi-node-cluster/README.md)          | Complete deployment of Azure IoT Operations on a multi-node, Arc-enabled Kubernetes cluster                                                        |
| [CNCF Cluster Script Only](./only-output-cncf-cluster-script/README.md) | Generates scripts for cluster creation without deploying resources                                                                                 |
| [Azure Fabric Environment](./fabric/terraform/README.md)                | Provisions Azure Fabric environment  *Terraform only currently*                                                                                    |
| *More coming soon...*                                                   |                                                                                                                                                    |

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

## Using Existing Resource Groups

All blueprints support deploying to existing resource groups rather than creating new ones.

### Terraform Implementation

To use an existing resource group with Terraform:

```sh
terraform apply -var="use_existing_resource_group=true" -var="resource_group_name=your-existing-rg"
```

### Bicep Implementation

To use an existing resource group with Bicep:

```sh
az deployment sub create --name deploy1 --location eastus \
  --template-file ./main.bicep \
  --parameters useExistingResourceGroup=true resourceGroupName=your-existing-rg
```

### Important Considerations

When using an existing resource group:

- Ensure it's in the same region specified in your deployment parameters
- Verify you have appropriate permissions to deploy resources within it
- Be aware that name conflicts may occur with existing resources
- The existing resource group's location will be used for resources that are location-sensitive

## Detailed Deployment Workflow

### Prerequisites

**IMPORTANT:** We highly suggest using [this project's integrated dev container](./.devcontainer/README.md) to get started quickly with Windows-based systems and also works well with nix-compatible environments.

Refer to the Environment Setup section in the [Root README](../README.md#getting-started-and-prerequisites-setup) for detailed instructions on setting up your environment.

Ensure your Azure CLI is logged in and your subscription context is set correctly.

### Getting Started and Deploying with Terraform

1. Navigate to your chosen blueprint directory, as an example:

   ```sh
   # Navigate to the terraform directory
   cd ./full-single-node-cluster/terraform
   ```

2. Set up required environment variables:

   - **ARM_SUBSCRIPTION_ID** -- The Azure Subscription ID target for this deployment (required to be set for the Terraform tasks below)

   ```sh
   # Dynamically get the Subscription ID or manually get and pass to ARM_SUBSCRIPTION_ID
   current_subscription_id=$(az account show --query id -o tsv)
   export ARM_SUBSCRIPTION_ID="$current_subscription_id"
   ```

3. Generate a `terraform.tfvars` file using terraform-docs:

   ```sh
   # Generate the tfvars file
   terraform-docs tfvars hcl .
   ```

   If terraform-docs is not installed, you'll need to install it:

   ```sh
   # Install terraform-docs - macOS
   brew install terraform-docs

   # Install terraform-docs - Linux
   ./scripts/install-terraform-docs.sh
   ```

   Or visit the [terraform-docs installation page](https://terraform-docs.io/user-guide/installation/) for more options.

   The generated output will look similar to the following:

   ```terraform
   # Required variables
   environment     = "dev"                 # Environment type (dev, test, prod)
   resource_prefix = "myprefix"            # Short unique prefix for resource naming
   location        = "eastus2"             # Azure region location
   # Optional (recommended) variables
   instance        = "001"                 # Deployment instance number
   ```

   Copy this output to a file named `terraform.tfvars` and fill in any required values.
   Update any optional values that you want to change as well.

   > **NOTE**: To have Terraform automatically use your variables, you can name your tfvars file `terraform.auto.tfvars`. Terraform will use variables from any `*.auto.tfvars` files located in the same deployment folder.

4. Initialize and apply Terraform:

   ```sh
   # Pulls down providers and modules, initializes state and backend
   terraform init -upgrade # Use '-reconfigure' if backend for tfstate needs to be reconfigured

   # Preview changes before applying
   terraform plan -var-file=terraform.tfvars  # Use -var-file if not using *.auto.tfvars file

   # Review resource change list, then deploy
   terraform apply -var-file=terraform.tfvars # Add '-auto-approve' to skip confirmation
   ```

   > **Note**: To deploy to an existing resource group instead of creating a new one, add `-var="use_existing_resource_group=true" -var="resource_group_name=your-existing-rg"` to your apply command.

5. Wait for the deployments to complete, an example successful deployment message looks like the following:

   ```txt
   Apply complete! Resources: *** added, *** changed, *** destroyed.
   ```

### Getting Started and Deploying with Bicep

Bicep provides an alternative Infrastructure as Code (IaC) approach that's native to Azure. Follow these steps to deploy blueprints using Bicep:

1. Navigate to your chosen blueprint directory, as an example:

   ```sh
   # Navigate to the bicep directory
   cd ./full-single-node-cluster/bicep
   ```

2. Use the Azure CLI to get the Custom Locations OID:

   ```sh
   # Get the custom locations OID and export it as an environment variable
   export CUSTOM_LOCATIONS_OID=$(az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv)

   # Verify the environment variable is set correctly
   echo $CUSTOM_LOCATIONS_OID
   ```

3. Check that the Bicep CLI is installed or install it:

   ```sh
   # Verify Bicep installation (included in recent Azure CLI versions)
   az bicep version

   # If not installed:
   az bicep install
   ```

4. Create a parameters file for your deployment:

   Generate a parameters file using the Azure CLI's Bicep parameter generation feature:

   ```sh
   # Generate the parameters file template
   az bicep generate-params --file main.bicep --output-format bicepparam --include-params all > main.bicepparam
   ```

   Edit the generated `main.bicepparam` file to customize your deployment parameters:

   ```bicep
   // Parameters for full-single-node-cluster blueprint
   using './main.bicep'

   // Required parameters for the common object
   param common = {
     resourcePrefix: 'prf01a2'     // Keep short (max 8 chars) to avoid resource naming issues
     location: 'eastus2'            // Replace with your Azure region
     environment: 'dev'             // 'dev', 'test', or 'prod'
     instance: '001'                // For multiple deployments
   }

   // This is not optimal, to be replaced by KeyVault usage in future
   @secure()
   param adminPassword = 'YourSecurePassword123!' // Replace with a secure password

   // When customeLocationsOid is required:
   param customLocationsOid = readEnvironmentVariable('CUSTOM_LOCATIONS_OID') // Read from environment variable

   // Any additional parameters with defaults, example:
   param resourceGroupName = 'rg-${common.resourcePrefix}-${common.environment}-${common.instance}'
   param shouldCreateAnonymousBrokerListener = false // Set to true only for dev/test environments
   param shouldInitAio = true // Deploy the Azure IoT Operations initial connected cluster resources
   param shouldDeployAio = true // Deploy an Azure IoT Operations Instance
   param useExistingResourceGroup = false // Set to true to use an existing resource group instead of creating a new one
   ```

   > **Note**: When setting `useExistingResourceGroup` to `true`, ensure the resource group already exists or your deployment will fail.

5. (Optional) Determine available Azure locations:

   Navigate to the `scripts` directory:

   ```sh
   cd ../../../scripts
   ```

   Run the `location-check.sh` script:

   ```sh
   ./location-check.sh --blueprint {blueprint_name} --method bicep
   ```

6. Deploy Resources with Bicep:

   ```sh
   # Deploy using the Azure CLI at the subscription level, keep deployment_name less than 8 characters:
   az deployment sub create --name {deployment_name} --location {location} --parameters ./main.bicepparam

   # Deploy using the Azure CLI at the resource group level, keep deployment_name less than 8 characters:
   RG_NAME="rg-{resource_prefix}-{environment}-{instance}"
   az deployment group create -g $RG_NAME --name {deployment_name} --parameters ./main.bicepparam
   ```

   > **Note**: When deploying with a `customLocationsOid`, ensure the CUSTOM_LOCATIONS_OID environment variable is set in your current shell session before running the deployment command.

7. Monitor deployment progress:

   You can check the deployment status in the Azure portal or using the Azure CLI:

   ```sh
   # Get the resource group name (after deployment starts)
   RG_NAME="rg-{resource_prefix}-{environment}-{instance}"

   # List resources in the resource group
   az resource list --resource-group $RG_NAME -o table
   ```

### Accessing Deployed Resources

After a successful deployment, you will want to verify your resources have been deployed correctly.
You can do this by listing all resources in the resource group to check that they've been deployed successfully:

```sh
# Get the resource group name (after deployment starts)
RG_NAME="rg-{resource_prefix}-{environment}-{instance}"

# List resources in the resource group
az resource list --resource-group $RG_NAME -o table
```

#### Any Arc Connected Cluster Deployment

After a successful deployment, verify you can connect to the cluster and that there are pods:

```sh
# Get the arc connected cluster name after deployment, default looks like the following:
ARC_CONNECTED_CLUSTER_NAME="arck-{resource_prefix}-{environment}-{instance}"

# Access the Kubernetes cluster (in one prompt)
az connectedk8s proxy -n $ARC_CONNECTED_CLUSTER_NAME -g $RG_NAME

# View AIO resources (in a separate prompt)
kubectl get pods -n azure-iot-operations

# Check cluster node status
kubectl get nodes -o wide
```

#### Any Key Vault Stored Resources (Such as Scripts)

After a successful deployment, for any resources stored in Key Vault that you may want to retrieve locally for
verification or as a result of a blueprint. Check the output from the deployment framework for specifics on what
to download.

Here is also how you will typically follow this process, using cluster setup scripts as an example:

```bash
# Get the Key Vault name after deployment, default looks like the following:
KV_NAME="kv-{resource_prefix}-{environment}-{instance}"

# Retrieve scripts from Key Vault and save to local files
az keyvault secret show --name cluster-server-ubuntu-k3s --vault-name $KV_NAME --query value -o tsv > cluster-server-ubuntu-k3s.sh
az keyvault secret show --name cluster-node-ubuntu-k3s --vault-name $KV_NAME --query value -o tsv > cluster-node-ubuntu-k3s.sh

# Make scripts executable
chmod +x cluster-server-ubuntu-k3s.sh cluster-node-ubuntu-k3s.sh
```

### Deployment Cleanup

It is recommend that you either use the Azure Portal or AZ CLI commands for deleting deployed resources. If you've deploy a Resource Group with resources in it, then the quickest way to clean up resources is to delete the resource group.

The following is an example using AZ CLI:

```bash
# Delete the resource group and all its resources
az group delete --name "$RG_NAME"
```

### Deployment Troubleshooting

Deployment duration for multi-node clusters will be longer than single-node deployments. Be patient during the provisioning process.

#### Terraform Troubleshooting

Terraform can fail if resources already exist that are not properly in its state, use the following to correct terraform state:

```sh
# List resources in the current state file
terraform state list

# Show details of a specific resource in state, example:
terraform state show 'module.edge_iot_ops.azurerm_arc_kubernetes_cluster_extension.iot_operations'

# Remove a resource from state (doesn't delete the actual resource), example:
terraform state rm 'module.edge_iot_ops.azurerm_arc_kubernetes_cluster_extension.iot_operations'

# Import an existing Azure resource into your Terraform state
# For Arc-enabled K8s cluster, example:
terraform import 'module.edge_cncf_cluster.azurerm_kubernetes_cluster.arc_cluster' \
  /subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Kubernetes/connectedClusters/{cluster_name}

# Update state to match the real infrastructure without making changes
terraform refresh

# Remove all resources from state (useful when you want to start fresh without destroying resources)
terraform state rm $(terraform state list)

# Move a resource within your state (useful for refactoring), example:
terraform state mv 'module.old_name.azurerm_resource.example' 'module.new_name.azurerm_resource.example'
```

#### Bicep Troubleshooting

Bicep uses the actual deployed resources in Azure, any correction needed to deployed resources must be done directly with bicep or AZ CLI commands:

```sh
# Get deployment status and errors
az deployment sub show --name {deployment_name} --query "properties.error" -o json

# List all deployments at subscription level
az deployment sub list --query "[].{Name:name, State:properties.provisioningState}" -o table

# Get detailed information about a specific resource
az resource show --resource-group $RG_NAME --name {resource_name} --resource-type {resource_type}

# Delete a specific resource without deleting the whole resource group
az resource delete --resource-group $RG_NAME --name {resource_name} --resource-type {resource_type}

# View deployment operations for troubleshooting
az deployment sub operation list --name {deployment_name}

# Export a deployed resource group as a template for comparison or backup
az group export --name $RG_NAME > exported-resources.json

# Export all child resources of a specific parent resource (useful for nested resources)
az resource list --parent "subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/{provider}/{resource-type}/{parent-resource}" -o json > child-resources.json
```

#### Common Issues

- **Node joining failures**: Multi-node deployments with worker nodes that fail to join the cluster, verify networking connectivity between VMs
- **Terraform timeouts**: Multi-node deployments may require increased timeouts for resource creation, increase timeout and retry the deployment.
- **Arc-enabled Kubernetes issues**: Arc connection issues may occur during first deployment, attempt retrying the deployment.
- **Custom Locations OID**: Verify correct OID for your tenant. This can vary between Azure AD instances and permissions.
- **VM size availability**: Ensure the chosen VM size is available in your selected region
- **Bicep deployment name too long**: Ensure that the original deployment name is roughly 5-8 characters long, this name is used for additional deployments throughout the process.
- **Resource name issues**: Ensure the provided resource prefix does not include anything other than alphanumeric characters. Also ensure your resource prefix is at most 8 characters long. Additional, pick a resource prefix that is likely to be unique, add 4 unique characters to the end of your resource prefix if needed.
- **Existing resource group issues**: When using the existing resource group feature, make sure the resource group exists before deployment.

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
