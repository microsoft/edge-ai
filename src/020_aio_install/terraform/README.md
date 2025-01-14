# Overview

This folder contains the Terraform configuration to deploy a Azure IoT Operations to an Arc Connected K3s Kubernetes cluster and required dependencies.

Learn more about the default configuration of each module by exploring the [modules](./modules/) directory.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- K3s cluster connected to Azure Arc, can be done by following the [cluster_install/README.md](../../010_cluster_install/terraform/README.md)

## Create resources

Set up terraform setting and apply it

1. cd into the `terraform` directory

    ```sh
    cd src/020_aio_install/terraform
    ```

2. Set up env vars

    ```sh
    export ARM_SUBSCRIPTION_ID=<subscription-id>
    ```

3. Create a `terraform.tfvars` file with the at least the following minumum configuration:

    ```hcl
    resource_prefix = "<resource-prefix>"
    location        = "<location>"
    ```

4. Optionally, if `connectedk8s proxy` is enabled on the cluster for the user deploying terraform and if you wish to deploy custom trust with TLS certificate in Key Vault and associated secrets for the broker, add the following to the `terraform.tfvars` file:

    ```hcl
    trust_config = {
        source = "CustomerManaged"
    }
    ```

5. Initalized and apply terraform

    ```sh
    terraform init
    terraform apply
    ```

6. Connect to the cluster as you normally would

## Destroy resources

To destroy the resources created by Terraform, run the following command:

```sh
terraform destroy
```
