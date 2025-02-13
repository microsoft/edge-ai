# Blueprints

__Blueprints__ are the IaC composition mechanism for this repository. They
provide a way to bring complete end-to-end solutions to life easily, and
can be extended, modified, or layered to build up and deploy complex multi-stage
solutions.

## Available Blueprints

- [Full Single Cluster install](./terraform/full-single-cluster/)
- more coming soon ...

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- An Azure subscription
- [Visual Studio Code](https://code.visualstudio.com/)
- A Linux-based development environment or a [Windows system with WSL](https://code.visualstudio.com/docs/remote/wsl)

> NOTE: We highly suggest using [this project's integrated dev container](./.devcontainer/README.md) to get started quickly particularly with Windows-bases systems.

Login to Azure CLI using the below command:

```sh
# Login to Azure CLI, optionally specify the tenant-id
az login # --tenant <tenant-id>
```

### Terraform - Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)

## Terraform - Getting Started

1. Login to Azure CLI using the below command:

    ```sh
    # Optionally, specify the tenant-id or tenant login
    az login # --tenant <tenant>.onmicrosoft.com
    ```

2. cd into the `blueprints/terraform/<deployment>` directory

   ```sh
   cd ./terraform/ful-single-cluster
   ```

3. Set up required env vars:

   ```sh
   # Dynamically get the Subscription ID or manually get and pass to ARM_SUBSCRIPTION_ID
   current_subscription_id=$(az account show --query id -o tsv)
   export ARM_SUBSCRIPTION_ID="$current_subscription_id"
   ```

4. Create a `terraform.tfvars` file with at least the following minimum configuration settings:

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

   For additional variables to configure, refer to the `variables.tf` or any of the `variables.*.tf` files located
   in the `terraform` directory for the component.

   > [!NOTE]: To have Terraform automatically use your variables you can name your tfvars file `terraform.auto.tfvars`.
   > Terraform will use variables from any `*.auto.tfvars` files located in the same deployment folder.

5. Initialize and apply terraform

   ```sh
   # Pulls down providers and modules, initializes state and backend
   # Use '-update -reconfigure' if provider or backend updates are required
   terraform init # -update -reconfigure

   # Review resource change list, then type 'y' enter to deploy, or, deploy with '-auto-approve'
   terraform apply -var-file=terraform.tfvars # -auto-approve
   ```

6. Wait patiently while your end-to-end solution deploys.
