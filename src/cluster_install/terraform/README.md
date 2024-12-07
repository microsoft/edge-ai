# Overview

This folder contains the Terraform configuration to deploy a Arc Connected K3s Kubernetes cluster on a single Azure Virtual Machine with Azure IoT Operations.

The VM can be accessed via SSH using a certificate and has the K3s Kubernetes cluster pre-installed. The cluster is connected to Azure Arc for management and monitoring. The private key will be stored a `.ssh` directory in the root of the project by default.

In addition to the above the config will optionally deploy the following:

- Create a resource group to deploy the VM into if no existing resource group is provided
- Create a Service Principal with minimum required permissions to connect the cluster to Azure Arc, if no existing Service Principal is provided
- Enable the Arc feature `cluster-connect` and assign the current Entra ID user as Kubernetes `cluster-admin` role. This allows for the user to securely, [remote connect](https://learn.microsoft.com/azure/azure-arc/kubernetes/cluster-connect?tabs=azure-cli%2Cagent-version) into the Arc-enabled Kubernetes cluster.

Learn more about the default configuration of each module by exploring the [modules](./modules/) directory.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)

### Optionally create a Service Principal manually

If you want to create a Service Principal manually instead of letting Terraform create it, you can use the following command:

```sh
# Create a Service Principal and assign roles to connect the cluster to Azure Arc
resource_group_name=<resource-group-name>
resource_group_id=$(az group show --name $resource_group_name --query id --output tsv)

az ad sp create-for-rbac --name manual-azure-arc  --role "Kubernetes Cluster - Azure Arc Onboarding" --scopes $resource_group_id
```

Then add the Service Principal details to the `terraform.tfvars` file:

```hcl
service_principal_id     = "<service-principal-id>"
service_principal_secret = "<service-principal-secret>"
```

## Create resources

Set up terraform setting and apply it

1. cd into the `terraform` directory

    ```sh
    cd src/cluster_install/terraform
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

4. Optionally, if `environment` is not set to `prod`, and you wish your current Azure Entra ID user to be assigned a `cluster-admin` role in the K3S cluster, add the following variable to `terraform.tfvars` file:

    ```hcl
    add_current_entra_user_cluster_admin = true
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

### Cloud-init

Check the cloud-init logs for errors:

```sh
cat /var/log/cloud-init-output.log
```

Cloud init script can be found at:

```sh
 sudo cat /var/lib/cloud/instance/scripts/runcmd
```
