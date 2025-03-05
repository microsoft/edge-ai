# Blueprints

## Overview

Blueprints are the Infrastructure as Code (IaC) composition mechanism for this repository. They provide ready-to-deploy end-to-end solutions that showcase how to combine individual components into complete edge computing solutions. Blueprints can be deployed as-is, extended, modified, or layered to build complex multi-stage solutions that meet your specific requirements.

## Available Blueprints

| Blueprint                                                                | Description                                                                                  |
|--------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| [Full Single Cluster](./terraform/full-single-cluster/)                  | Complete deployment of Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster |
| [CNCF Cluster Script Only](./terraform/only-output-cncf-cluster-script/) | Generates scripts for cluster creation without deploying resources                           |
| *More coming soon...*                                                    |                                                                                              |

## Prerequisites

**IMPORTANT:** We highly suggest using [this project's integrated dev container](./.devcontainer/README.md) to get started quickly with Windows-based systems and also works well with nix-compatible environments.

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- An Azure subscription
- [Visual Studio Code](https://code.visualstudio.com/)
- [Terraform](https://developer.hashicorp.com/terraform/install)
- A Linux-based development environment or a [Windows system with WSL](https://code.visualstudio.com/docs/remote/wsl)

1. Login to Azure CLI using the below command:

    ```sh
    # Login to Azure CLI, optionally specify the tenant-id
    az login # --tenant <tenant-id>
    ```

2. Navigate to your chosen blueprint directory:

   ```sh
   cd ./terraform/full-single-cluster
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

   # Review resource change list, then deploy
   terraform apply -var-file=terraform.tfvars # Add '-auto-approve' to skip confirmation
   ```

6. Wait for the deployments to complete with the message:

   ```txt
   Apply complete! Resources: *** added, *** changed, *** destroyed.
   ```
