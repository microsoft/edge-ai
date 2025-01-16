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

    The above will generate the custom trust as self signed certificates, if you wish to configure your own certificates from a PKI infrastructure, you can provide the following configuration:

    ```hcl
    aio_ca = {
        # Root CA certificate in PEM format, used as the trust bundle.
        root_ca_cert_pem  = "<>"
        # CA certificate chain, can be the same as root_ca_cert_pem or a chain with any number of intermediate certificates.
        # Chain direction must be: ca -> intermediate(s) --> root ca
        ca_cert_chain_pem = "<>"
        # Root or intermediate CA private key in PEM format. If using intermediates, must provide the private key of the first cert in the chain.
        ca_key_pem        = "<>"
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
