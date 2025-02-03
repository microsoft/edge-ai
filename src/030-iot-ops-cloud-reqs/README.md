# Azure IoT Operations Cloud Requirements

Component for Azure Resources required by Azure IoT Operations.

This includes the following:

- Azure Device Registry Schema Registry
- Storage Account (for the ADR Schema Registry)
- Azure Key Vault (for Secret Sync Extension)
- Roles and Permissions for these resources

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
