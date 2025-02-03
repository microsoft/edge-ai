# VM Host

Component for onboarding a new Azure VM for the purposes of installing and testing out
an edge deployment.

This includes the following:

- Azure VNet
- Azure VM

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

4. Initalized and apply terraform

    ```sh
    terraform init
    terraform apply
    ```

5. Navigate to the deployed VM in Azure portal and Enable JIT (Just in time) access for your IP:
    Virtual Machines -> Select the VM -> Connect -> Native SSH -> VM Access -> Requests JIT access

6. The terraform output will contain the SSH command to connect to the VM
    Use the SSH command to connect to the VM or any preferred SSH client.

    ```sh
    ssh -i ../.ssh/id_rsa <vm_user_name>@<vm_dns_or_public_ip>
    ```

## Destroy resources

To destroy the resources created by Terraform, run the following command:

```sh
terraform destroy
```
