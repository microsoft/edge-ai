# Overview

This folder contains the Terraform configuration to deploy a Arc Connected K3s Kubernetes cluster on a single Azure Virtual Machine with Azure IoT Operations.

The VM can be accessed via SSH using a certificate and has the K3s Kubernetes cluster pre-installed. The cluster is connected to Azure Arc for management and monitoring. The private key will be stored a `.ssh` directory in the root of the project by default.

In addition to the above the config will optionally deploy the following:

- Create a resource group to deploy the VM into if no existing resource group is provided
- Create a Managed Identity leveraged by the VM, with minimum required permissions to connect the cluster to Azure Arc
- Optionally, create or pass in a Service Principal to connect the cluster to Azure Arc
- Optionally, enable the Arc feature `cluster-connect` and assign the current Entra ID user as Kubernetes `cluster-admin` role. This allows for the user to securely, [remote connect](https://learn.microsoft.com/azure/azure-arc/kubernetes/cluster-connect?tabs=azure-cli%2Cagent-version) into the Arc-enabled Kubernetes cluster.
- Install and configure Azure IoT Operations and required dependencies with default settings

Learn more about the default configuration of each module by exploring the [modules](./modules/) directory.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

## Create resources

Login to Azure CLI using the below command:

```bash
# Login to Azure CLI, optionally specify the tenant-id
az login # --tenant <tenant-id>
```

Set up terraform setting and apply it

1. cd into the `terraform` directory

    ```sh
    cd src/010_cluster_install/terraform
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

4. By default, current Azure Entra ID user or principal will be assigned a `cluster-admin` role in the K3S cluster so modules like Azure IoT Operations requiring `kubectl` can run successfully. If you wish to disable this, add the following variable to `terraform.tfvars` file:

    ```hcl
    add_current_entra_user_cluster_admin = false
    ```

5. Initalized and apply terraform

    ```sh
    terraform init
    terraform apply
    ```

6. Navigate to the deployed VM in Azure portal and Enable JIT (Just in time) access for your IP:
    Virtual Machines -> Select the VM -> Connect -> Native SSH -> VM Access -> Requests JIT access

7. The terraform output will contain the SSH command to connect to the VM
    Use the SSH command to connect to the VM or any preferred SSH client.

    ```sh
    ssh -i ../.ssh/id_rsa <vm_user_name>@<vm_dns_or_public_ip>
    ```

## Destroy resources

To destroy the resources created by Terraform, run the following command:

```sh
terraform destroy
```

## Troubleshooting

### Virtual Machine extension

Check the VM extension logs for errors, ensure you SSH into the machine:

```sh
sudo su
cat /var/lib/waagent/Microsoft.Azure.Extensions.CustomScript-2.1.10/status/0.status
```

Check the VM extension `stdout` and `stderr` logs:

```sh
sudo cat /var/lib/waagent/custom-script/download/0/stdout
sudo cat /var/lib/waagent/custom-script/download/0/stderr
```
