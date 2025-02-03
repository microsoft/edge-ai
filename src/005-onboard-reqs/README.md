# New Environment Onboard Requirements

Component for onboarding a new environment and includes IaC for creating resources that are needed for an
edge deployment.

This includes the following:

- Azure Resource Group
- User Assigned Managed Identity for a VM Host
- Service Principal for automated cluster setup and Azure Arc connection

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

## Create resources

Login to Azure CLI using the below command:

```sh
# Login to Azure CLI, optionally specify the tenant-id
az login # --tenant <tenant-id>
```

Set up terraform setting and apply it

1. cd into the `terraform` directory

    ```sh
    cd ./terraform
    ```

2. Set up env vars

    ```sh
    export ARM_SUBSCRIPTION_ID=<subscription-id>
    ```

3. Create a `terraform.tfvars` file with the at least the following minumum configuration:

    ```hcl
    environment     = "<environment>"
    resource_prefix = "<resource-prefix>"
    location        = "<location>"
    ```

4. Initialize and apply terraform

    ```sh
    terraform init
    terraform apply
    ```

## Destroy resources

To destroy the resources created by Terraform, run the following command:

```sh
terraform destroy
```
